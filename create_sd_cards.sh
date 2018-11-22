#!/bin/bash

#Tell the 
read -p $'\e[33m WARNING: \e[0m No input sanitation is applied, please be careful with your input parameters. Press Enter to continue or STRG+C/D to cancel:[ENTER]'
#check paramters for emptyness
if [ -z "$1" ];
then
	echo -e "\e[31m ERROR:\e[0m No first parameter defined, please define something like 2 or 3 for the raspberry pi version you want to prepare u-boot for.";
	exit 1;
fi
if [ -z "$2" ];
then
	echo -e "\e[31m ERROR:\e[0m No second parameter defined, please define something like /dev/sdb1.";
	exit 1;
fi
if [ -z "$3" ];
then
	echo -e "\e[33m WARN:\e[0m No third parameter defined, please define something like /tmp/sdcardmount.\n \e[31m Using standard value /tmp/sdcard! \e[0m";
fi
if [ -z "$4" ];
then
	echo -e "\e[33m WARN:\e[0m No fourth parameter defined, standard parameter will be used for MAC address.\n \e[32m Using standard value 02:03:02:00:00:XX! \e[0m";
fi
if [ -z "$5" ];
then
	echo -e "\e[33m WARN:\e[0m No fifth parameter defined,\n \e[32m initializing MAC addresses with 1! \e[0m";
fi


#installing necessary dependencies
echo -e "\e[33m Installing dependencies... \e[0m"
sudo apt update && sudo apt install make gcc bison flex xz-utils -yy


DIRECTORY="./u-boot"
if [ ! -d "$DIRECTORY" ]; then
#Cloning u-boot from repository
echo -e "\e[33m Cloning GIT-Repository... \e[0m"
git clone git://git.denx.de/u-boot.git
#Switching into u-boot directory
cd u-boot

## OPTIONAL:
#show possible rpi configs
#ls configs | grep rpi

#get the latest version from https://releases.linaro.org/components/toolchain/binaries/
echo -e "\e[35m... Please ensure you are using the latest linaro toolchain for CROSS_COMPILE ...\e[0m"
wget https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-eabi/gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi.tar.xz
tar xf gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi.tar.xz
else
 echo -e "\e[31mDirectory exists, please delete first, if you have problems with u-boot or linaro toolchain...\e[0m \n Continuing to compile!";
 cd u-boot
 echo -e "Switched into u-boot directory"
fi

git checkout v2018.11

#checks if value for raspberry pi version is 2 or 3 and builds, quits otherwise
if [ "$1" == '3' ]
then
	#Raspberry Pi 3 config
	CROSS_COMPILE=`pwd`/gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi/bin/arm-eabi- make O=build_rpi3 rpi_3_defconfig
	CROSS_COMPILE=`pwd`/gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi/bin/arm-eabi- make O=build_rpi3 -j
	CROSS_COMPILE=`pwd`/gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi/bin/arm-eabi- make O=build_rpi3 env
elif [ "$1" == '2' ]
then
	#Raspberry Pi 2 config
	CROSS_COMPILE=`pwd`/gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi/bin/arm-eabi- make O=build_rpi2 rpi_2_defconfig
	CROSS_COMPILE=`pwd`/gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi/bin/arm-eabi- make O=build_rpi2 -j
	CROSS_COMPILE=`pwd`/gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi/bin/arm-eabi- make O=build_rpi2 env
else
	echo -e "Please specify either 2 or 3 as first parameter to build for raspberry pi 2 or 3"
	exit 1;
fi


#Creating mount folder
if [ -z "$3" ];
then
	echo -e "No third parameter defined, please define something like /tmp/sdcard as mounting point if you wish. \n Continuing with /tmp/sdcard as mounting point";
	mountpoint=/tmp/sdcard
else
	mountpoint=$3
fi
mkdir -p $mountpoint

#Check if mac address was set, otherwise take the default one
if [ -z "$4"];
then
	mac="02:03:02:00:00:";
else
	mac=$4;
fi

#Check if start parameter is set, otherwise set it do default 1
if [ -z "$5"];
then
	startvariable=1;
else
	startvariable=$5;
fi

#Check if end parameter is set, otherwise set it do default 20
if [ -z "$6"];
then
	endvariable=20;
else
	endvariable=$6;
fi
cd ..
#start loop that prepares the sd cards, as for a new sd card at the end of each cycle
for i in $(seq $startvariable $endvariable);
do
	# create hex from dec
	i=$(printf "%02X\n" $i)

	# adapt mac address
	sed -i "s/^ethaddr=.*/ethaddr=$mac$i/"  uboot.env.txt

	# create uboot.env
	./u-boot/build_rpi2/tools/mkenvimage -s 16384 -o uboot.env uboot.env.txt

	# format sd card
	sudo umount $2
	echo -en "o\nn\np\n\n\n\nt\nb\nw\nq\n" | sudo fdisk $2
	sudo mkfs.fat -n GENODE_RPI2 $2

	# mount sd card and copy files
	sudo mount $2 $mountpoint
	sudo cp ./u-boot/build_rpi$1/u-boot.bin $mountpoint
	sudo cp uboot.env $mountpoint
	sudo cp files$1/* $mountpoint

	# umount and sync
	sudo umount $mountpoint
	sync

	read -p "Switch SD card and press enter to continue"
done

