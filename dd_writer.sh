#!/bin/bash

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] This script must be run as root. Exiting."
    exit 1
fi

echo -e "\n.:/// DD WRITER ///:.\n"

echo "[+] Enter the full path to the ISO or IMG file:"
read -r FILE_PATH

if [ ! -f "$FILE_PATH" ]; then
    echo "[!] The file does not exist. Exiting."
    exit 1
fi

# Find physical volumes in volume group(s) to omit from output
VG_DRIVES=$(pvs --noheadings -o pv_name | awk '{print $1}' | sed 's#/dev/##')

# List block devices
echo "[+] Available drives (excluding system, DVD, LVM, and loop devices):"
lsblk -dno NAME,SIZE,MODEL | grep -vE "loop|sr0" | awk '{print $1}' | while read -r LINE; do
    if ! echo "$VG_DRIVES" | grep -q "$LINE"; then
        lsblk -dno NAME,SIZE,MODEL | grep "^$LINE"
    fi
done

echo "[+] Enter the device name to write to (e.g., sdb, sdc):"
read -r DEVICE_NAME

# Validate device name
if [[ "$DEVICE_NAME" =~ ^(sda|loop|sr0)$ ]] || echo "$VG_DRIVES" | grep -q "/dev/$DEVICE_NAME"; then
    echo "[!] Invalid device selection. Exiting."
    exit 1
fi

echo "[+] Enter block size (e.g., 1M, 4M, etc.), or press Enter to use default 4M:"
read -r BLOCK_SIZE
BLOCK_SIZE=${BLOCK_SIZE:-4M}  # Default 4M

echo "/dev/$DEVICE_NAME selected. The next step will delete all data on $DEVICE_NAME."
echo "[+] Type 'yes' to confirm:"
read -r CONFIRMATION

if [ "$CONFIRMATION" != "yes" ]; then
    echo "[!] Exiting."
    exit 1
fi

# Write to device using dd
echo "[+] Writing to /dev/$DEVICE_NAME with block size $BLOCK_SIZE..."
dd if="$FILE_PATH" of="/dev/$DEVICE_NAME" bs="$BLOCK_SIZE" status=progress oflag=sync

echo "[+] Write operation completed successfully!"
