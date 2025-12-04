#!/bin/bash
# Ultimate Linux System Health Report
# Full HTML report via email
# Usage: sudo bash /usr/local/bin/linux_system_health_report.sh

EMAIL="loganathr20@gmail.com"
SUBJECT="Ultimate Linux System Health Report - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')"
TMPHTML=$(mktemp /tmp/sys_health_XXXX.html)
TMPTXT=$(mktemp /tmp/sys_health_XXXX.txt)

trap 'rm -f "$TMPHTML" "$TMPTXT"' EXIT

# Check if sudo is needed
SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

# HTML escape
safe_html() { echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# Color status
color_status() {
    case "$1" in
        OK|PASSED|Healthy|on)
            echo "<span style='color:green;font-weight:bold;'>$1</span>";;
        Warning|Degraded|Caution)
            echo "<span style='color:orange;font-weight:bold;'>$1</span>";;
        *)
            echo "<span style='color:red;font-weight:bold;'>$1</span>";;
    esac
}

# Capture ps once
PS_OUTPUT=$(ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu,-%mem)

# Start HTML
cat <<EOF > "$TMPHTML"
<html>
<head>
<style>
body { font-family: Arial, sans-serif; line-height:1.4; }
h2,h3 { padding:10px; }
table { border-collapse: collapse; width: 100%; margin-bottom:15px; }
th, td { border:1px solid #ccc; padding:5px; text-align:left; }
th { background-color:#d9edf7; }
tr:nth-child(even) { background-color:#f9f9f9; }
</style>
</head>
<body>
<h2 style="background-color:#cce5ff;">Ultimate Linux System Health Report</h2>
<p><b>Host:</b> $(hostname) &nbsp;&nbsp; <b>Date:</b> $(date '+%Y-%m-%d %H:%M:%S %z')</p>
EOF

# SYSTEM SUMMARY
BIOS_VER=$($SUDO dmidecode -s bios-version 2>/dev/null || echo "N/A")
BIOS_DATE=$($SUDO dmidecode -s bios-release-date 2>/dev/null || echo "N/A")
BIOS_VENDOR=$($SUDO dmidecode -s bios-vendor 2>/dev/null || echo "N/A")
KERNEL_VER=$(uname -r)
CPU_MODEL=$(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')
CPU_CORES=$(lscpu | grep '^CPU(s):' | awk '{print $2}')
RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')

cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#e6f7ff;'>System Summary</h3>
<table>
<tr><th>Component</th><th>Value</th></tr>
<tr><td>Kernel</td><td>$KERNEL_VER</td></tr>
<tr><td>CPU</td><td>$CPU_MODEL · $CPU_CORES cores</td></tr>
<tr><td>Total RAM</td><td>$RAM_TOTAL</td></tr>
</table>
EOF

# MEMORY USAGE
read total used free <<< $(free -h | awk '/Mem:/ {print $2,$3,$4}')
usage_percent=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#fff0e6;'>Memory Usage</h3>
<table>
<tr><th>Total</th><th>Used</th><th>Free</th><th>Usage%</th></tr>
<tr><td>$total</td><td>$used</td><td>$free</td><td>$usage_percent%</td></tr>
</table>
EOF

# BIOS INFORMATION
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#e6ffe6;'>BIOS Information</h3>
<table>
<tr><th>Vendor</th><th>Version</th><th>Date</th></tr>
<tr><td>$BIOS_VENDOR</td><td>$BIOS_VER</td><td>$BIOS_DATE</td></tr>
</table>
EOF

# CPU & LOAD
LOAD_AVG=$(uptime | awk -F 'load average:' '{print $2}' | sed 's/^[ \t]*//')
UPTIME_STR=$(uptime -p)
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#e6ffe6;'>CPU & Load</h3>
<table>
<tr><th>Metric</th><th>Value</th></tr>
<tr><td>Load (1/5/15)</td><td style='background-color:#fcf8e3;font-weight:bold;'>$LOAD_AVG</td></tr>
<tr><td>Uptime</td><td>$UPTIME_STR</td></tr>
</table>
EOF

# TOP PROCESSES
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#fff0e6;'>Top CPU-consuming processes (top 10)</h3>
<pre>$(safe_html "$(echo "$PS_OUTPUT" | head -n 10)")</pre>

<h3 style='background-color:#e6f7ff;'>Top processes by CPU+Memory</h3>
<pre>$(safe_html "$(echo "$PS_OUTPUT" | head -n 10)")</pre>
EOF

# DISK USAGE
row_color="#f9f9f9"
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#f2f2f2;'>Disk Usage</h3>
<table>
<tr><th>Filesystem</th><th>Type</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mounted on</th></tr>
EOF
df -hT | tail -n +2 | while read fs type size used avail usep mount; do
    echo "<tr style='background-color:$row_color;'><td>$fs</td><td>$type</td><td>$size</td><td>$used</td><td>$avail</td><td>$usep</td><td>$mount</td></tr>" >> "$TMPHTML"
    [[ $row_color == "#f9f9f9" ]] && row_color="#ffffff" || row_color="#f9f9f9"
done
echo "</table>" >> "$TMPHTML"

# SWAP
read sw_total sw_used sw_free <<< $(free -h | awk '/Swap:/ {print $2,$3,$4}')
swap_percent=$(free | awk '/Swap:/ {printf "%.0f", $3/$2*100}')
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#fff0e6;'>Swap Usage</h3>
<table>
<tr><th>Total</th><th>Used</th><th>Free</th><th>Usage%</th></tr>
<tr><td>$sw_total</td><td>$sw_used</td><td>$sw_free</td><td>$swap_percent%</td></tr>
</table>
EOF

# SMART DISK HEALTH
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#e6ffe6;'>SMART Disk Health</h3>
<table>
<tr><th>Device</th><th>Status</th><th>Key Attributes</th></tr>
EOF
shopt -s nullglob
if command -v smartctl &>/dev/null; then
    for dev in /dev/sd[a-z] /dev/nvme*n*; do
        [[ -b "$dev" ]] || continue
        STATUS=$($SUDO smartctl -H "$dev" 2>&1 | awk '/PASSED|Unknown|FAILED/ {print $0}')
        ATTRS=$($SUDO smartctl -A "$dev" 2>/dev/null | grep -E 'Reallocated_Sector_Ct|Power_On_Hours|Temperature|Current_Pending_Sector|Offline_Uncorrectable' | tr '\n' '; ')
        echo "<tr><td>$dev</td><td>$(color_status "$STATUS")</td><td>$ATTRS</td></tr>" >> "$TMPHTML"
    done
fi
shopt -u nullglob
echo "</table>" >> "$TMPHTML"

# TEMPERATURES
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#fff0e6;'>Temperatures</h3>
<table>
<tr><th>Sensor</th><th>Value</th></tr>
EOF
if command -v sensors &>/dev/null; then
    row_color="#f9f9f9"
    sensors | while read line; do
        [[ $line == *:* ]] || continue
        name=$(echo "$line" | cut -d: -f1)
        value=$(echo "$line" | cut -d: -f2-)
        echo "<tr style='background-color:$row_color;'><td>$name</td><td>$value</td></tr>" >> "$TMPHTML"
        [[ $row_color == "#f9f9f9" ]] && row_color="#ffffff" || row_color="#f9f9f9"
    done
else
    echo "<tr><td colspan='2'>sensors not installed.</td></tr>" >> "$TMPHTML"
fi
echo "</table>" >> "$TMPHTML"

# NETWORK INTERFACES
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#e6f7ff;'>Network Interfaces & IPs</h3>
<pre>$(safe_html "$(ip -brief addr show)")</pre>
EOF

# LOGS (last 20 critical entries)
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#f2f2f2;'>Recent Critical Logs (last 20)</h3>
<pre>$(safe_html "$(journalctl -p 3 -n 20 --no-pager)")</pre>
EOF

# FAILED SERVICES
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#e6ffe6;'>Failed Services</h3>
<pre>$(safe_html "$(systemctl --failed)")</pre>
EOF

# PACKAGE UPDATES
if command -v apt &>/dev/null; then
    UPDATES=$(apt list --upgradable 2>/dev/null | tail -n +2)
    cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#fff0e6;'>Available Package Updates</h3>
<pre>$(safe_html "$UPDATES")</pre>
EOF
fi

# PCI & USB DEVICES
cat <<EOF >> "$TMPHTML"
<h3 style='background-color:#e6f7ff;'>PCI & USB Devices</h3>
<pre>$(safe_html "$(lspci -vvnn; lsusb)")</pre>
EOF

# End HTML
echo "</body></html>" >> "$TMPHTML"

# Save raw log
cat "$TMPHTML" > "$TMPTXT"

# Send email via msmtp
{
echo "Subject: $SUBJECT"
echo "MIME-Version: 1.0"
echo "Content-Type: text/html; charset=UTF-8"
echo
cat "$TMPHTML"
} | msmtp -a default "$EMAIL"


