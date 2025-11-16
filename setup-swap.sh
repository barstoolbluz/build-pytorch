#!/bin/bash
# Setup swap space to prevent OOM kernel freezes
# Run with: sudo bash setup-swap.sh

set -e

SWAP_SIZE=64G
SWAP_FILE=/swapfile

echo "Creating ${SWAP_SIZE} swap file at ${SWAP_FILE}..."

# Create swap file
dd if=/dev/zero of=${SWAP_FILE} bs=1G count=64 status=progress

# Set proper permissions
chmod 600 ${SWAP_FILE}

# Make it a swap file
mkswap ${SWAP_FILE}

# Enable it
swapon ${SWAP_FILE}

# Make it permanent
if ! grep -q "${SWAP_FILE}" /etc/fstab; then
    echo "${SWAP_FILE} none swap sw 0 0" >> /etc/fstab
    echo "Added to /etc/fstab for persistence"
fi

echo "Swap setup complete!"
free -h
