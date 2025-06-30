#!/usr/bin/env python3
"""
Cross-platform STM32MP1 SD card flasher
Works on Windows, Linux, and macOS
"""

import sys
import os
import platform
import subprocess
import struct
import argparse
from pathlib import Path

def get_removable_drives():
    """Get list of removable drives based on OS"""
    system = platform.system()
    drives = []
    
    if system == "Windows":
        import win32api
        import win32file
        
        drive_bits = win32api.GetLogicalDrives()
        for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            mask = 1 << (ord(letter) - ord('A'))
            if drive_bits & mask:
                drive = f"{letter}:\\"
                drive_type = win32file.GetDriveType(drive)
                if drive_type == win32file.DRIVE_REMOVABLE:
                    try:
                        size = win32api.GetDiskFreeSpaceEx(drive)[1]
                        drives.append((drive, size))
                    except:
                        pass
                        
    elif system == "Linux":
        # Look for removable block devices
        for device in Path("/sys/block").iterdir():
            removable_path = device / "removable"
            if removable_path.exists():
                with open(removable_path) as f:
                    if f.read().strip() == "1":
                        dev_path = f"/dev/{device.name}"
                        size_path = device / "size"
                        if size_path.exists():
                            with open(size_path) as f:
                                size = int(f.read().strip()) * 512
                                drives.append((dev_path, size))
                                
    elif system == "Darwin":  # macOS
        result = subprocess.run(["diskutil", "list", "-plist"], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            import plistlib
            plist = plistlib.loads(result.stdout.encode())
            for disk in plist.get("AllDisksAndPartitions", []):
                if disk.get("Internal", True) == False:
                    dev_path = f"/dev/{disk['DeviceIdentifier']}"
                    size = disk.get("Size", 0)
                    drives.append((dev_path, size))
                    
    return drives

def verify_stm32_header(data):
    """Verify the STM32 header in the binary"""
    if len(data) < 256:
        return False
    
    magic, entry_point, reserved, image_size = struct.unpack("<IIII", data[:16])
    
    if magic != 0x00000001:
        print(f"Warning: Invalid magic number: 0x{magic:08x}")
        return False
        
    print(f"STM32 Header found:")
    print(f"  Magic: 0x{magic:08x}")
    print(f"  Entry: 0x{entry_point:08x}")
    print(f"  Size:  {image_size} bytes")
    
    return True

def flash_image(image_path, device_path, offset=0x4400):
    """Flash the image to the SD card"""
    system = platform.system()
    
    # Read the image
    with open(image_path, "rb") as f:
        data = f.read()
        
    # Verify header
    if not verify_stm32_header(data):
        response = input("\nInvalid STM32 header. Continue anyway? (y/N): ")
        if response.lower() != 'y':
            return False
            
    print(f"\nFlashing {len(data)} bytes to {device_path} at offset 0x{offset:x}...")
    
    try:
        # Use dd on Unix-like systems
        if system in ["Linux", "Darwin"]:
            cmd = [
                "sudo", "dd", 
                f"if={image_path}", 
                f"of={device_path}", 
                "bs=512", 
                f"seek={offset // 512}",
                "conv=fsync"
            ]
            if system == "Linux":
                cmd.append("status=progress")
                
            # Unmount on macOS first
            if system == "Darwin":
                subprocess.run(["diskutil", "unmountDisk", device_path])
                
            result = subprocess.run(cmd)
            return result.returncode == 0
            
        # Direct write on Windows
        elif system == "Windows":
            with open(device_path, "r+b") as f:
                f.seek(offset)
                f.write(data)
                f.flush()
            return True
            
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Flash STM32MP1 image to SD card")
    parser.add_argument("image", help="Path to .stm32 image file")
    parser.add_argument("-d", "--device", help="Device path (auto-detect if not specified)")
    parser.add_argument("-o", "--offset", type=lambda x: int(x, 0), 
                       default=0x4400, help="Offset in bytes (default: 0x4400)")
    
    args = parser.parse_args()
    
    # Check if image exists
    if not os.path.exists(args.image):
        print(f"Error: Image file '{args.image}' not found")
        sys.exit(1)
        
    print("STM32MP135 SD Card Flasher")
    print("==========================\n")
    
    # Get device if not specified
    if not args.device:
        drives = get_removable_drives()
        
        if not drives:
            print("No removable drives found.")
            print("Please specify device manually with -d option.")
            sys.exit(1)
            
        print("Available removable drives:")
        for i, (path, size) in enumerate(drives):
            size_gb = size / (1024**3)
            print(f"  {i+1}. {path} ({size_gb:.1f} GB)")
            
        print("\nWARNING: Selecting the wrong drive will destroy your data!")
        
        try:
            choice = int(input("Select drive number (0 to cancel): "))
            if choice == 0:
                print("Cancelled.")
                sys.exit(0)
            if choice < 1 or choice > len(drives):
                raise ValueError()
                
            device_path = drives[choice-1][0]
            
        except (ValueError, KeyboardInterrupt):
            print("\nInvalid selection or cancelled.")
            sys.exit(1)
    else:
        device_path = args.device
        
    # Confirm
    print(f"\nAbout to flash to: {device_path}")
    print(f"Image: {args.image}")
    print(f"Offset: 0x{args.offset:x}")
    
    response = input("\nAre you ABSOLUTELY SURE? Type 'yes' to continue: ")
    if response != "yes":
        print("Cancelled.")
        sys.exit(0)
        
    # Flash the image
    if flash_image(args.image, device_path, args.offset):
        print("\nSuccess! Image flashed to SD card.")
        print("You can now insert the SD card into your STM32MP135 board.")
    else:
        print("\nError: Failed to flash image.")
        sys.exit(1)

if __name__ == "__main__":
    main()
