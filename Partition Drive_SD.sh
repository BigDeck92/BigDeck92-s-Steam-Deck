#!/bin/bash

# Variables
DEVICE="/dev/mmcblk0"
WIN_PART_SIZE="53.9G"  # Adjust size as needed
WIN_PART_LABEL="Windows"
SHARED_PART_LABEL="Shared"

# Check if the device exists
if [ ! -b "$DEVICE" ]; then
  echo "Device $DEVICE not found. Please check the device name."
  exit 1
fi

# Unmount the device if mounted
if mount | grep ${DEVICE}p1 > /dev/null; then
  sudo umount ${DEVICE}p1 || { echo "Failed to unmount ${DEVICE}p1"; exit 1; }
fi

if mount | grep ${DEVICE}p2 > /dev/null; then
  sudo umount ${DEVICE}p2 || { echo "Failed to unmount ${DEVICE}p2"; exit 1; }
fi

# Kill processes using the device
sudo fuser -k ${DEVICE}p1 2>/dev/null
sudo fuser -k ${DEVICE}p2 2>/dev/null

# Create partitions
sudo parted ${DEVICE} --script mklabel gpt || { echo "Failed to create GPT label"; exit 1; }
sudo parted ${DEVICE} --script mkpart primary ntfs 1MiB ${WIN_PART_SIZE} || { echo "Failed to create Windows partition"; exit 1; }
sudo parted ${DEVICE} --script mkpart primary ${WIN_PART_SIZE} 100% || { echo "Failed to create Shared partition"; exit 1; }

# Format partitions
sudo mkfs.ntfs -f -L ${WIN_PART_LABEL} ${DEVICE}p1 || { echo "Failed to format Windows partition"; exit 1; }
sudo mkfs.exfat -n ${SHARED_PART_LABEL} ${DEVICE}p2 || { echo "Failed to format Shared partition"; exit 1; }

# Display the partition table
sudo parted ${DEVICE} --script print || { echo "Failed to display partition table"; exit 1; }

echo "Partitioning complete. ${WIN_PART_LABEL} partition is NTFS and ${SHARED_PART_LABEL} partition is exFAT."
