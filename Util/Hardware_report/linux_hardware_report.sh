#!/bin/bash
# Linux Hardware & Performance Report with HTML-styled email (no attachment)
# Usage: sudo bash /usr/local/bin/linux_hardware_report.sh

EMAIL="loganathr20@gmail.com"
SUBJECT="Linux Hardware & Performance Report - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')"
TMPHTML=$(mktemp /tmp/hw_report_XXXX.html)

# Function to color status
color_status() {
    case "$1" in
        OK|PASSED|Healthy|on)
            echo "<span style='color:green;font-weight:bold;'>$1</span>"
            ;;
        Warning|Degraded|Caution)
            echo "<span style='color:orange;font-weight:bold;'>$1</span>"
            ;;
        *)
            echo "<span style='color:red;font-weight:bold;'>$1</span>"
            ;;
    esac
}

# Start HTML
echo "<html><body style='font-family: Arial, sans-serif;'>" > "$TMPHTML"
echo "<h2 style='background-color:#cce5ff;padding:10px;'>Linux Hardware & Performance Report</h2>" >> "$TMPHTML"
echo "<p><b>Host:</b> $(hostname) &nbsp;&nbsp; <b>Date:</b> $(date '+%Y-%m-%d %H:%M:%S %z')</p>" >> "$TMPHTML"

# --- SYSTEM SUMMARY ---
BIOS_VER=$(sudo dmidecode -s bios-version 2>/dev/null || echo "N/A")
BIOS_DATE=$(sudo dmidecode -s bios-release-date 2>/dev/null || echo "N/A")
KERNEL_VER=$(uname -r)
CPU_MODEL=$(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')
CPU_CORES=$(lscpu | grep '^CPU(s):' | awk '{print $2}')
RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')

echo "<h3 style='background-color:#e6f7ff;padding:5px;'>System Summary</h3>" >> "$TMPHTML"
echo "<table border='1' cellspacing='0' cellpadding='5' style='border-collapse:collapse;width:70%;'>" >> "$TMPHTML"
echo "<tr style='background-color:#d9edf7;'><th>Component</th><th>Value</th></tr>" >> "$TMPHTML"
echo "<tr><td>Kernel</td><td>$KERNEL_VER</td></tr>" >> "$TMPHTML"
echo "<tr style='background-color:#f2f2f2;'><td>CPU</td><td>$CPU_MODEL · $CPU_CORES cores</td></tr>" >> "$TMPHTML"
echo "<tr><td>Total RAM</td><td>$RAM_TOTAL</td></tr>" >> "$TMPHTML"
echo "<tr style='background-color:#f2f2f2;'><td>BIOS Version</td><td>$BIOS_VER</td></tr>" >> "$TMPHTML"
echo "<tr><td>BIOS Date</td><td>$BIOS_DATE</td></tr>" >> "$TMPHTML"
echo "</table><br>" >> "$TMPHTML"

# --- CPU & LOAD ---
LOAD_AVG=$(uptime | awk -F 'load average:' '{print $2}' | sed 's/^[ \t]*//')
UPTIME_STR=$(uptime -p)

echo "<h3 style='background-color:#e6ffe6;padding:5px;'>CPU & Load</h3>" >> "$TMPHTML"
echo "<table border='1' cellspacing='0' cellpadding='5' style='border-collapse:collapse;width:50%;'>" >> "$TMPHTML"
echo "<tr style='background-color:#dff0d8;'><th>Metric</th><th>Value</th></tr>" >> "$TMPHTML"
echo "<tr><td>Load (1/5/15)</td><td style='background-color:#fcf8e3;font-weight:bold;'>$LOAD_AVG</td></tr>" >> "$TMPHTML"
echo "<tr style='background-color:#f9f9f9;'><td>Uptime</td><td>$UPTIME_STR</td></tr>" >> "$TMPHTML"
echo "</table><br>" >> "$TMPHTML"

# --- MEMORY USAGE ---
echo "<h3 style='background-color:#fff0e6;padding:5px;'>Memory Usage</h3>" >> "$TMPHTML"
echo "<table border='1' cellspacing='0' cellpadding='5' style='border-collapse:collapse;width:50%;'>" >> "$TMPHTML"
echo "<tr style='background-color:#d9edf7;'><th>Total</th><th>Used</th><th>Free</th><th>Usage%</th></tr>" >> "$TMPHTML"
read total used free <<< $(free -h | awk '/Mem:/ {print $2,$3,$4}')
usage_percent=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
echo "<tr style='background-color:#f2f2f2;'><td>$total</td><td>$used</td><td>$free</td><td>$usage_percent%</td></tr>" >> "$TMPHTML"
echo "</table><br>" >> "$TMPHTML"

# --- TOP PROCESSES ---
echo "<h3 style='background-color:#fff0e6;padding:5px;'>Top CPU-consuming processes (top 10)</h3>" >> "$TMPHTML"
echo "<table border='1' cellspacing='0' cellpadding='5' style='border-collapse:collapse;width:100%;'>" >> "$TMPHTML"
echo "<tr style='background-color:#d9edf7;'><th>PID</th><th>User</th><th>Command</th><th>%CPU</th><th>%MEM</th></tr>" >> "$TMPHTML"
ps -eo pid,user,cmd,%cpu,%mem --sort=-%cpu | head -n 11 | tail -n 10 | while read pid user cmd cpu mem; do
    echo "<tr style='background-color:#f9f9f9;'><td>$pid</td><td>$user</td><td>$cmd</td><td>$cpu</td><td>$mem</td></tr>" >> "$TMPHTML"
done
echo "</table><br>" >> "$TMPHTML"

# (Rest of sections remain the same...)

# End HTML
echo "</body></html>" >> "$TMPHTML"

# Send Email via msmtp (HTML only)
{
echo "Subject: $SUBJECT"
echo "MIME-Version: 1.0"
echo "Content-Type: text/html; charset=UTF-8"
echo
cat "$TMPHTML"
} | msmtp -a default "$EMAIL"

# Cleanup
rm -f "$TMPHTML"


