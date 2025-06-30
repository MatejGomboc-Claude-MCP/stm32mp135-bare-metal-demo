# Flash script for Windows PowerShell
# Requires Administrator privileges

$ErrorActionPreference = "Stop"

Write-Host "STM32MP135 SD Card Flasher" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""

# Check if binary exists
if (-not (Test-Path "build\stm32mp135-bare-metal.stm32")) {
    Write-Host "Error: Binary not found. Please build the project first." -ForegroundColor Red
    exit 1
}

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click on VSCode and select 'Run as Administrator', then try again." -ForegroundColor Yellow
    exit 1
}

# List available disks
Write-Host "Available disks:"
Get-Disk | Where-Object {$_.BusType -eq "USB" -or $_.BusType -eq "SD"} | Format-Table Number, FriendlyName, Size, PartitionStyle

Write-Host ""
Write-Host "WARNING: Selecting the wrong disk will destroy your data!" -ForegroundColor Yellow
$diskNumber = Read-Host "Please enter the disk number for your SD card"

# Validate disk
try {
    $disk = Get-Disk -Number $diskNumber
    if ($disk.Size -gt 64GB) {
        Write-Host "Warning: Selected disk is larger than 64GB. Are you sure this is an SD card?" -ForegroundColor Yellow
        $confirm = Read-Host "Type 'yes' to continue"
        if ($confirm -ne "yes") {
            Write-Host "Aborted."
            exit 0
        }
    }
} catch {
    Write-Host "Error: Invalid disk number" -ForegroundColor Red
    exit 1
}

# Confirm with user
Write-Host ""
Write-Host "You are about to write to: Disk $diskNumber - $($disk.FriendlyName)"
Write-Host "Size: $([math]::Round($disk.Size / 1GB, 2)) GB"
$confirm = Read-Host "Are you ABSOLUTELY SURE? Type 'yes' to continue"

if ($confirm -ne "yes") {
    Write-Host "Aborted."
    exit 0
}

# Flash the image
Write-Host ""
Write-Host "Flashing image..." -ForegroundColor Green

try {
    # Open disk for raw write
    $diskPath = "\\.\PhysicalDrive$diskNumber"
    $fileStream = [System.IO.File]::OpenRead("build\stm32mp135-bare-metal.stm32")
    $diskStream = [System.IO.File]::OpenWrite($diskPath)
    
    # Seek to sector 34 (offset 0x4400)
    $diskStream.Seek(34 * 512, [System.IO.SeekOrigin]::Begin) | Out-Null
    
    # Copy data
    $buffer = New-Object byte[] 4096
    $totalBytes = 0
    while (($bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $diskStream.Write($buffer, 0, $bytesRead)
        $totalBytes += $bytesRead
        Write-Progress -Activity "Flashing" -Status "$totalBytes bytes written" -PercentComplete (($totalBytes / $fileStream.Length) * 100)
    }
    
    $fileStream.Close()
    $diskStream.Close()
    
    Write-Host "`nSuccess! Image flashed to SD card." -ForegroundColor Green
    Write-Host "You can now insert the SD card into your STM32MP135 board."
    
} catch {
    Write-Host "Error: Failed to flash image" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
