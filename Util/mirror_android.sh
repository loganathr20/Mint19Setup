#!/bin/bash

##########################################################
#  ANDROID MIRRORING SCRIPT (LINUX MINT)
#  Supports USB + Wi-Fi Auto Switching
#  scrcpy 3.3.3 compatible
##########################################################

# --- SETTINGS ------------------------------------------

# Set this to "yes" to enable wireless mode
WIRELESS_MODE="yes"

# Default Wi-Fi port for adb
ADB_PORT=5555

# --------------------------------------------------------

echo "===== Android Screen Mirroring (Linux Mint) ====="

echo "🔧 Killing any existing ADB server..."
adb kill-server >/dev/null 2>&1

echo "🔄 Restarting ADB server..."
adb start-server >/dev/null 2>&1

# Check scrcpy installed
if ! command -v scrcpy &> /dev/null; then
    echo "❌ scrcpy is not installed. Install: sudo apt install scrcpy"
    exit 1
fi

# Detect USB device
USB_DEVICE=$(adb devices | grep -w "device" | grep -v "emulator" | awk '{print $1}')

# =======================================================
# WIRELESS MIRRORING SECTION
# =======================================================
if [ "$WIRELESS_MODE" = "yes" ]; then
    echo "📡 Wireless mode enabled. Trying Wi-Fi connection..."

    # If USB is connected, use it to configure wireless ADB
    if [ -n "$USB_DEVICE" ]; then
        echo "🔌 USB device detected: $USB_DEVICE"
        echo "📡 Preparing device for wireless ADB..."

        # Get phone's IP
        PHONE_IP=$(adb -s "$USB_DEVICE" shell ip route | awk '{print $9}')
        
        if [ -z "$PHONE_IP" ]; then
            echo "❌ Cannot retrieve device IP. Check Wi-Fi connection."
            exit 1
        fi

        echo "📶 Device IP: $PHONE_IP"

        echo "📡 Switching ADB to TCP/IP mode..."
        adb -s "$USB_DEVICE" tcpip $ADB_PORT >/dev/null

        echo "🔗 Connecting over Wi-Fi..."
        adb connect "$PHONE_IP:$ADB_PORT"

        # Detect wireless connection
        WIFI_DEVICE=$(adb devices | grep "$PHONE_IP" | grep "device" | awk '{print $1}')

        if [ -n "$WIFI_DEVICE" ]; then
            echo "✅ Wireless connection established: $WIFI_DEVICE"
            echo "🚀 Launching scrcpy wirelessly..."

            scrcpy \
                --max-size=1080 \
                --video-bit-rate=8M \
                --audio-bit-rate=128K \
                --stay-awake \
                --turn-screen-off \
                --window-title="Android Mirror (Wi-Fi) - $WIFI_DEVICE"
            
            exit 0
        else
            echo "❌ Wireless connection failed. Falling back to USB..."
        fi
    else
        echo "⚠ No USB device detected to configure wireless. Trying direct Wi-Fi..."
    fi
fi

# =======================================================
# USB MIRRORING SECTION (fallback or wireless disabled)
# =======================================================

echo "🔌 Trying USB mode..."

USB_DEVICE=$(adb devices | grep -w "device" | grep -v "emulator" | awk '{print $1}')

if [ -z "$USB_DEVICE" ]; then
    echo "❌ No Android device detected via USB or Wi-Fi."
    exit 1
fi

echo "📱 USB device detected: $USB_DEVICE"
echo "🚀 Launching scrcpy via USB..."

scrcpy \
    --max-size=1080 \
    --video-bit-rate=8M \
    --audio-bit-rate=128K \
    --stay-awake \
    --turn-screen-off \
    --window-title="Android Mirror (USB) - $USB_DEVICE"

exit 0



