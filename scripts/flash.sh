#!/bin/bash
# Flash script for Linux and macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "STM32MP135 SD Card Flasher"
echo "========================="
echo ""

# Check if binary exists
if [ ! -f "build/stm32mp135-bare-metal.stm32" ]; then
    echo -e "${RED}Error: Binary not found. Please build the project first.${NC}"
    exit 1
fi

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
else
    echo -e "${RED}Error: Unsupported OS${NC}"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# List available disks
echo "Available disks:"
if [ "$OS" == "Linux" ]; then
    lsblk -d -o NAME,SIZE,MODEL | grep -E '^sd|^mmcblk'
elif [ "$OS" == "macOS" ]; then
    diskutil list | grep -E '^/dev/disk[0-9]+ '
fi

echo ""
echo -e "${YELLOW}WARNING: Selecting the wrong disk will destroy your data!${NC}"
echo "Please enter the device path for your SD card:"

if [ "$OS" == "Linux" ]; then
    echo "Example: /dev/sdb or /dev/mmcblk0"
elif [ "$OS" == "macOS" ]; then
    echo "Example: /dev/disk2"
fi

read -p "Device path: " DEVICE

# Validate device exists
if [ ! -e "$DEVICE" ]; then
    echo -e "${RED}Error: Device $DEVICE not found${NC}"
    exit 1
fi

# Confirm with user
echo ""
echo "You are about to write to: $DEVICE"
read -p "Are you ABSOLUTELY SURE? Type 'yes' to continue: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Flash the image
echo ""
echo "Flashing image..."

if [ "$OS" == "Linux" ]; then
    sudo dd if=build/stm32mp135-bare-metal.stm32 of="$DEVICE" bs=512 seek=34 conv=fsync status=progress
elif [ "$OS" == "macOS" ]; then
    # On macOS, we need to unmount first
    diskutil unmountDisk "$DEVICE"
    sudo dd if=build/stm32mp135-bare-metal.stm32 of="$DEVICE" bs=512 seek=34
fi

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}Success! Image flashed to SD card.${NC}"
    echo "You can now insert the SD card into your STM32MP135 board."
else
    echo -e "\n${RED}Error: Failed to flash image${NC}"
    exit 1
fi
