#!/bin/bash

echo "===================================="
echo "     scrcpy Wireless Launcher"
echo "===================================="
echo ""
read -p "Enter device IP:PORT (example 192.168.1.13:39077): " DEVICEIP

echo "Disconnecting old ADB sessions..."
adb disconnect

echo "Connecting to $DEVICEIP ..."
adb connect "$DEVICEIP"

sleep 1

echo "Launching scrcpy..."
scrcpy -s "$DEVICEIP" --max-fps=60 --bit-rate=8M

