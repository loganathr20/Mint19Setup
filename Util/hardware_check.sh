#!/bin/bash
# Linux Hardware Health Report with Email
# Requires: lshw, smartctl, sensors, mailx or sendmail
# Usage: sudo bash linux_hardware_report.sh

# ---------- CONFIGURATION ----------
EMAIL="your.email@example.com"
SUBJECT="Linux Hardware Health Report - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')"
TMPFILE=$(mktemp /tmp/hw_report_XXXX.html)
# -----------------------------------

# Start HTML
echo "<html><body style='font-family: Arial, sans-serif;'>" > "$TMPFILE"
echo "<h2>Linux Hardware Health Report - $(hostname)</h2>" >> "$TMPFILE"

# SYSTEM INFO
echo "<h3>System Info</h3><pre>" >> "$TMPFILE"
echo "Hostname: $(hostname)" >> "$TMPFILE"
echo "Kernel: $(uname -r)" >> "$TMPFILE"
echo "CPU: $(lscpu | grep 'Model name' | sed 's/Model name: //' )" >> "$TMPFILE"
echo "Total RAM: $(free -h | awk '/Mem:/ {print $2}')" >> "$TMPFILE"
echo "BIOS Version: $(sudo dmidecode -s bios-version)" >> "$TMPFILE"
echo "BIOS Release Date: $(sudo dmidecode -s bios-release-date)" >> "$TMPFILE"
echo "</pre>" >> "$TMPFILE"

# CPU INFO
echo "<h3>CPU Info</h3><pre>" >> "$TMPFILE"
lscpu >> "$TMPFILE"
echo "</pre>" >> "$TMPFILE"

# MEMORY INFO
echo "<h3>Memory Info</h3><pre>" >> "$TMPFILE"
free -h >> "$TMPFILE"
sudo dmidecode -t memory | grep -E 'Size|Speed|Locator|Type' >> "$TMPFILE"
echo "</pre>" >> "$TMPFILE"

# DISK HEALTH
echo "<h3>Disk Health (SMART)</h3><pre>" >> "$TMPFILE"
if command -v smartctl &>/dev/null; then
    for disk in $(lsblk -d -o NAME,TYPE | awk '$2=="disk"{print $1}'); do
        echo "Disk: /dev/$disk" >> "$TMPFILE"
        sudo smartctl -H /dev/$disk >> "$TMPFILE"
        sudo smartctl -A /dev/$disk | grep -E 'Reallocated_Sector_Ct|Wear_Leveling|Power_On_Hours|Temperature' >> "$TMPFILE"
        echo "" >> "$TMPFILE"
    done
else
    echo "smartctl not found, install smartmontools" >> "$TMPFILE"
fi
echo "</pre>" >> "$TMPFILE"

# PHYSICAL DISK INFO
echo "<h3>Physical Disk Info</h3><pre>" >> "$TMPFILE"
lsblk -o NAME,FSTYPE,SIZE,TYPE,MOUNTPOINT >> "$TMPFILE"
echo "</pre>" >> "$TMPFILE"

# TEMPERATURES
echo "<h3>Temperatures</h3><pre>" >> "$TMPFILE"
if command -v sensors &>/dev/null; then
    sensors >> "$TMPFILE"
else
    echo "sensors not found, install lm-sensors and run 'sensors-detect'" >> "$TMPFILE"
fi
echo "</pre>" >> "$TMPFILE"

# PCI DEVICES
echo "<h3>PCI Devices</h3><pre>" >> "$TMPFILE"
lspci >> "$TMPFILE"
echo "</pre>" >> "$TMPFILE"

# USB DEVICES
echo "<h3>USB Devices</h3><pre>" >> "$TMPFILE"
lsusb >> "$TMPFILE"
echo "</pre>" >> "$TMPFILE"

# BATTERY STATUS (if laptop)
echo "<h3>Battery Status (if applicable)</h3><pre>" >> "$TMPFILE"
if [ -d /sys/class/power_supply/ ]; then
    for bat in /sys/class/power_supply/BAT*; do
        [ -e "$bat" ] || continue
        echo "$bat:" >> "$TMPFILE"
        cat "$bat/status" >> "$TMPFILE"
        cat "$bat/capacity" >> "$TMPFILE"
    done
fi
echo "</pre>" >> "$TMPFILE"

# SYSTEM LOG WARNINGS
echo "<h3>System Log Warnings</h3><pre>" >> "$TMPFILE"
journalctl -p 3 -xb | tail -n 20 >> "$TMPFILE"
echo "</pre>" >> "$TMPFILE"

# End HTML
echo "</body></html>" >> "$TMPFILE"

# Send Email
if command -v mailx &>/dev/null; then
    mailx -a "Content-Type: text/html" -s "$SUBJECT" "$EMAIL" < "$TMPFILE"
elif command -v sendmail &>/dev/null; then
    {
        echo "Subject: $SUBJECT"
        echo "MIME-Version: 1.0"
        echo "Content-Type: text/html"
        cat "$TMPFILE"
    } | sendmail "$EMAIL"
else
    echo "No mail command found. Install mailx or sendmail."
fi

# Cleanup
rm "$TMPFILE"

