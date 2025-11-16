#!/bin/bash

echo "===================================="
echo "  scrcpy Wireless (USB → WiFi) Tool"
echo "===================================="

echo "Checking for USB-connected Android device..."
USB_DEVICE=$(adb devices | grep -w "device" | awk 'NR==1{print $1}')

if [ -z "$USB_DEVICE" ]; then
    echo "❌ No USB device found."
    echo "Make sure:"
    echo "  • USB debugging is ON"
    echo "  • USB cable is connected"
    echo "  • You accepted 'Allow USB debugging' on phone"
    exit 1
fi

echo "✔ USB device found: $USB_DEVICE"

echo "Switching to TCP/IP mode on port 5555..."
adb tcpip 5555

sleep 1

# Get the phone's WiFi IP from `ip route` (Linux Mint compatible)
PHONE_IP=$(ip route | grep -oP 'src \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)

echo ""
echo "Detected phone IP address: $PHONE_IP"
if [ -z "$PHONE_IP" ]; then
    echo "❌ Could not detect phone IP. Enter manually."
    read -p "Enter your phone WiFi IP: " PHONE_IP
fi

TARGET="$PHONE_IP:5555"

echo ""
echo "Connecting wirelessly to: $TARGET"
adb connect "$TARGET"

sleep 1

echo ""
echo "Launching scrcpy wirelessly..."
scrcpy -s "$TARGET" --video-bit-rate=8M --max-fps=60



