# uboot-deploy
Deploying script to deploy u-boot on raspberry pi 2 and 3 for the data generation clusters


This is a helper to fast flash a lot of SD Cards which help to boot up raspberry pis 2 and 3.
The helper will install u-boot and all necessary components on the sd card and increase the MAC addresses
of every u-boot image deployed.

Please have a look at the script before running it. Device path and raspberry pi version are mandatory.
Others can be left blank. Initial values are shown below.

							Raspberry Pi Version		Device		Mountpoint		MAC				Start	End
Usage: ./create_sd_card.sh 	2							/dev/sdb1	/tmp/sdcard 	00:03:02:00:00: 	1		20
