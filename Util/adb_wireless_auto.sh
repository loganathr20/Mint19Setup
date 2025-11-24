#!/bin/bash

##########################################################
# Wireless-only ADB Connect Script
# Connects to 192.168.1.13:<port> over Wi-Fi
# Linux Mint / Ubuntu / Debian
# Assumes wireless debugging is already enabled and paired
##########################################################

# Ask user for the ADB wireless port
read -p "Enter ADB wireless connect port (e.g., 5555): " CONNECT_PORT

CONNECT_IP="192.168.1.13:$CONNECT_PORT"

echo "===== Wireless ADB Connect Script ====="

# Kill and restart adb
echo "🔧 Killing existing adb server..."
adb kill-server >/dev/null 2>&1

echo "🔄 Restarting adb server..."
adb start-server >/dev/null 2>&1

# Attempt to connect wirelessly
echo "🔗 Connecting to $CONNECT_IP ..."
adb connect "$CONNECT_IP"

if [ $? -ne 0 ]; then
    echo "❌ Connection failed! Make sure wireless debugging is enabled and phone is on same Wi-Fi."
    exit 1
fi

echo "✅ Successfully connected to $CONNECT_IP"

# Show current connected devices
echo "📱 Current connected devices:"
adb devices -l

scrcpy

exit 0



