
#!/bin/bash

DEFAULT_IP="192.168.1.13"
DEFAULT_PORT="42465"
CONNECT_IP="$DEFAULT_IP:$DEFAULT_PORT"

echo "===== ADB Wireless Connect & scrcpy ====="

# Kill and restart adb
echo "🔧 Killing existing adb server..."
adb kill-server >/dev/null 2>&1
echo "🔄 Restarting adb server..."
adb start-server >/dev/null 2>&1

# Function to attempt connection
connect_device() {
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

# First attempt with default IP:PORT
if ! connect_device "$CONNECT_IP"; then
    # Ask user for a new port if first attempt fails
    read -p "Enter ADB port to connect (example 5555): " USER_PORT
    CONNECT_IP="$DEFAULT_IP:$USER_PORT"

    if ! connect_device "$CONNECT_IP"; then
        echo "❌ Connection failed again! Make sure phone is on same Wi-Fi and wireless debugging is enabled."
        exit 1
    fi
fi

# Show current connected devices
echo "📱 Current connected devices:"
adb devices -l

# Launch scrcpy
if command -v scrcpy >/dev/null 2>&1; then
    echo "📺 Launching scrcpy..."
    scrcpy --video-bit-rate=8M --max-size=1080
else
    echo "⚠ scrcpy is not installed. Install it with: sudo apt install scrcpy"
fi

exit 0



