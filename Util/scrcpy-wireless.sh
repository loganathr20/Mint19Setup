#!/bin/bash

echo "==============================="
echo "     SCRCPY WIRELESS (TCP)"
echo "==============================="
echo

# Step 0 - Wake up device
echo "🔋 Waking up device..."
adb shell input keyevent 224 2>/dev/null  # Wake screen
sleep 1
adb shell input keyevent 82 2>/dev/null   # Unlock menu/home button
sleep 1
echo "✔ Device wake attempted."
echo

# Step 1 - Check for USB device
echo "🔍 Checking for USB device..."
USB_DEVICE=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')

if [ -z "$USB_DEVICE" ]; then
    echo "❌ No USB device detected."
    echo "Connect your phone via USB with USB debugging enabled."
    exit 1
fi

echo "✔ USB device detected: $USB_DEVICE"
echo

# Step 2 - Enable TCP mode on port 5555
echo "🔄 Enabling ADB TCP mode on port 5555..."
adb tcpip 5555
echo

# Step 3 - Ask for phone IP with default
read -p "📡 Enter phone IP address (default 192.168.1.13): " PHONE_IP
PHONE_IP=${PHONE_IP:-192.168.1.13}
echo "Using phone IP: $PHONE_IP"
echo

# Step 4 - Connect via TCP
echo "🔗 Trying to connect to $PHONE_IP:5555 ..."
adb connect "$PHONE_IP:5555"

if [ $? -ne 0 ]; then
    echo
    echo "❌ Connection failed on port 5555."
    read -p "Enter correct port (from Wireless Debugging): " PORT
    echo
    echo "🔗 Trying to connect to $PHONE_IP:$PORT ..."
    adb connect "$PHONE_IP:$PORT"

    if [ $? -ne 0 ]; then
        echo "❌ Failed to connect. Check IP/port and try again."
        exit 1
    fi
fi

echo
echo "✅ Connected successfully!"
echo

# Step 5 - Launch scrcpy
echo "🚀 Launching scrcpy..."
scrcpy
echo

