#!/bin/bash
# Setup swap partition on unpartitioned space
# Run with: sudo bash setup-swap-partition.sh

set -e

echo "=== Checking available unpartitioned space ==="
echo ""
echo "Disk /dev/sda:"
parted /dev/sda unit GB print free 2>/dev/null || true
echo ""
echo "Disk /dev/nvme0n1:"
parted /dev/nvme0n1 unit GB print free 2>/dev/null || true
echo ""

read -p "Which disk has the 100GB free space? (sda or nvme0n1): " DISK
DEVICE="/dev/${DISK}"

echo ""
echo "=== Analyzing ${DEVICE} ==="
parted ${DEVICE} unit GB print free

echo ""
read -p "Enter the START position of the free space (e.g., 384GB): " START_POS
read -p "Enter the END position for swap (e.g., 448GB for 64GB swap): " END_POS

echo ""
echo "=== Creating swap partition on ${DEVICE} ==="
echo "Start: ${START_POS}"
echo "End:   ${END_POS}"
echo "This will create a swap partition in the FREE SPACE only"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Show current partition table
echo ""
echo "Current partitions:"
parted ${DEVICE} print
echo ""

# Create the swap partition in the free space
echo "Creating swap partition..."
parted ${DEVICE} mkpart primary linux-swap ${START_POS} ${END_POS}

# Reload partition table
partprobe ${DEVICE}
sleep 2

# Get the new partition number (it should be the last one)
PART_NUM=$(parted ${DEVICE} print | grep "^ " | tail -1 | awk '{print $1}')

# Determine the partition device name
if [[ ${DEVICE} == *"nvme"* ]] || [[ ${DEVICE} == *"mmcblk"* ]]; then
    SWAP_PARTITION="${DEVICE}p${PART_NUM}"
else
    SWAP_PARTITION="${DEVICE}${PART_NUM}"
fi

echo "New swap partition: ${SWAP_PARTITION}"

# Verify it exists
if [ ! -b "${SWAP_PARTITION}" ]; then
    echo "ERROR: Partition ${SWAP_PARTITION} was not created!"
    exit 1
fi

# Format as swap
echo "Formatting ${SWAP_PARTITION} as swap..."
mkswap ${SWAP_PARTITION}

# Get UUID
SWAP_UUID=$(blkid ${SWAP_PARTITION} | grep -oP 'UUID="\K[^"]+')
echo "Swap UUID: ${SWAP_UUID}"

# Enable swap
echo "Enabling swap..."
swapon ${SWAP_PARTITION}

# Add to /etc/fstab for persistence
echo ""
echo "Add this line to /etc/fstab to make it permanent:"
echo "UUID=${SWAP_UUID} none swap sw 0 0"
echo ""

read -p "Add to /etc/fstab now? (yes/no): " ADD_FSTAB
if [ "$ADD_FSTAB" == "yes" ]; then
    if ! grep -q "${SWAP_UUID}" /etc/fstab; then
        echo "UUID=${SWAP_UUID} none swap sw 0 0" >> /etc/fstab
        echo "Added to /etc/fstab"
    else
        echo "Already in /etc/fstab"
    fi
fi

echo ""
echo "=== Swap setup complete! ==="
echo ""
free -h
echo ""
swapon --show
