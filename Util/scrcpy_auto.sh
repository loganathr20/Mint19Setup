#!/bin/bash

adb shell input keyevent KEYCODE_WAKEUP
adb shell input keyevent KEYCODE_MENU
adb shell input keyevent 82
adb shell input keyevent 224

DEFAULT_IP="192.168.1.13"
DEFAULT_PORT="5555"
CONNECT_IP="$DEFAULT_IP:$DEFAULT_PORT"

echo "===== One-Click ADB Wireless/USB scrcpy ====="

# Kill and restart adb
echo "🔧 Killing existing adb server..."
adb kill-server >/dev/null 2>&1
echo "🔄 Restarting adb server..."
adb start-server >/dev/null 2>&1

# Function to attempt wireless connection
connect_wireless() {
    local ip_port="$1"
    echo "🔗 Trying to connect to $ip_port ..."
    adb connect "$ip_port" >/dev/null 2>&1

    # Verify connection
    if adb devices | grep -w "$ip_port" | grep -q "device"; then
        echo "✅ Successfully connected to $ip_port"
        return 0
    else
        echo "❌ Connection failed for $ip_port"
        return 1
    fi
}

# Try default wireless port
if ! connect_wireless "$CONNECT_IP"; then
    # Ask user for a port
    read -p "Enter ADB port to connect (example 5555): " USER_PORT
    CONNECT_IP="$DEFAULT_IP:$USER_PORT"

    if ! connect_wireless "$CONNECT_IP"; then
        echo "⚠ Wireless connection failed. Trying USB..."
        USB_DEVICE=$(adb devices | grep -w "device" | grep -v "emulator" | grep -v "_adb-tls-" | awk '{print $1}')

        if [ -z "$USB_DEVICE" ]; then
            echo "❌ No USB device detected. Cannot continue."
            exit 1
        fi

        echo "🔌 USB device detected: $USB_DEVICE"
        echo "✅ Using USB connection"
        CONNECT_IP="$USB_DEVICE"
    fi
fi

# Show connected devices
echo "📱 Current connected devices:"
adb devices -l

# Launch scrcpy
if command -v scrcpy >/dev/null 2>&1; then
    echo "📺 Launching scrcpy..."
    scrcpy  --video-bit-rate=8M --max-size=1080 -s "$CONNECT_IP"
else
    echo "⚠ scrcpy is not installed. Install it with: sudo apt install scrcpy"
fi

exit 0



