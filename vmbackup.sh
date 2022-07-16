#!/bin/bash
# Script that will check for backup to be mounted 
# then it will run a backup on all existing VM on server.
# Adrin Story
# 09/16/2017
# updated to handle spares files and only give transfer stats
# 03/31/2018
# Updated because for some reason grep ^file doesn't work anymore. 
# 07/15/2022
# Need to add checks to make sure variables are not null

date
BACKUPDEST=/backup


	if [ ! -f $BACKUPDEST/donotdelete.txt ];
	then 
		echo "File not found!"
		echo "Backup directory not mounted"
		exit 1
	fi

	if (( "$EUID" != 0 ));
	then 
		echo "Please run as root"
		exit 1
	fi

	for VMDOMAIN in $(virsh list --name); do
		echo "Backing up "$VMDOMAIN
	#
        # Get the list of targets (disks) and the image paths.
	#
	TARGETS=`virsh domblklist "$VMDOMAIN" --details | grep -i file |grep -v cdrom | grep -v floppy | awk '{print $3}'`
	IMAGES=`virsh domblklist "$VMDOMAIN" --details | grep -i file |grep -v cdrom | grep -v floppy | awk '{print $4}'`
	IMAGESPATH=`dirname $IMAGES`
	IMAGEFILENAME=`basename $IMAGES`
	#
	# Create the snapshot.
	#
	virsh snapshot-create-as --domain "$VMDOMAIN" --name "$VMDOMAIN"Snapshot --no-metadata --atomic --disk-only --diskspec "$TARGETS",snapshot=external,file="$IMAGESPATH"/Snapshot"$IMAGEFILENAME"
        if [ $? -ne 0 ]; then
		echo "Failed to create snapshot for $VMDOMAIN"
		exit 1
	fi
	#
	# Create backup of Virtual Machine
	#
	rsync -aSP --stats "$IMAGES" "$BACKUPDEST"/"$IMAGEFILENAME"
	if [ $? -ne 0 ]; then
		echo "Failed to copy $IMAGES for $VDOMAIN"
		exit 1
	fi
		
	#
	# Merge snapshot back
	#
	virsh blockcommit "$VMDOMAIN" "$TARGETS" --active --pivot
	if [ $? -ne 0 ]; then
		echo "Failed to merge snapshot for $VDOMAIN"
		exit 1
	fi
		
	#
	# Cleanup left over backup images.
	#
	rm "$IMAGESPATH"/Snapshot"$IMAGEFILENAME"
		if [ $? -ne 0 ]; then
			echo "Failed to remove snapshot for $VDOMAIN"
			exit 1
		fi
		
	#
	# Dump the configuration information.
	#
	virsh dumpxml "$VMDOMAIN" >"$BACKUPDEST/$VMDOMAIN.xml"

	done
date
