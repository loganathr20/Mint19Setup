#!/bin/bash
# Linux System Health Report (Complete Version with Sidebar Fix)
# Usage: sudo bash /usr/local/bin/linux_hardware_report.sh

EMAIL="loganathr20@gmail.com"
SUBJECT="Linux System Health Report - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')"
TMPHTML=$(mktemp /tmp/sys_health_XXXX.html)
trap 'rm -f "$TMPHTML"' EXIT

SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

safe_html() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# --------------------------
# System Info
# --------------------------
HOSTNAME=$(hostname)
KERNEL_VER=$(uname -r)
LSCPU_MODEL=$(lscpu | awk -F: '/Model name/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')
CPU_CORES=$(lscpu | awk -F: '/^CPU\(s\)/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')
RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
NOW=$(date '+%Y-%m-%d %H:%M:%S %z')

BIOS_VENDOR=$($SUDO dmidecode -s bios-vendor 2>/dev/null || echo "")
BIOS_VERSION=$($SUDO dmidecode -s bios-version 2>/dev/null || echo "")
BIOS_DATE=$($SUDO dmidecode -s bios-release-date 2>/dev/null || echo "")
BIOS_VENDOR=${BIOS_VENDOR:-"Unknown Vendor"}
BIOS_VERSION=${BIOS_VERSION:-"Unknown Version"}
BIOS_DATE=${BIOS_DATE:-"Unknown Date"}
BOOT_MODE="Legacy"
[[ -d /sys/firmware/efi ]] && BOOT_MODE="UEFI"

LOAD1=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{gsub(/^[ \t]+/,"",$1); print $1}')
LOAD1=${LOAD1:-0}
MEM_USED_PERC=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
SWAP_USED_PERC=$(free | awk '/Swap:/ {if ($2==0) print 0; else printf "%.0f", $3/$2*100}')
ROOT_USE_PERC=$(df --output=pcent / | tail -1 | tr -dc '0-9')

SMART_OVERALL="OK"
if command -v smartctl &>/dev/null; then
  for d in /dev/sd[a-z] /dev/nvme*n*; do
    [[ -b "$d" ]] || continue
    out=$($SUDO smartctl -H "$d" 2>&1)
    if echo "$out" | grep -iq 'fail'; then SMART_OVERALL="FAILED"; break; fi
  done
fi

TEMP_MAX=0
if command -v sensors &>/dev/null; then
  for t in $(sensors | sed -n 's/.*\([0-9]\{1,3\}\)\.\?[0-9]*°C.*/\1/p'); do
    [[ -z "$t" ]] && continue
    (( t > TEMP_MAX )) && TEMP_MAX=$t
  done
fi

FAILED_SERVICES=$(systemctl --failed --no-legend | grep -c .)
CRIT_LOGS=$(journalctl -p 3 -n 100 --no-pager | grep -c .)

# --------------------------
# Scoring functions
# --------------------------
score_cpu() { awk -v ld="$LOAD1" -v cores="$CPU_CORES" 'BEGIN{r=(cores>0?ld/cores:ld); s=(r<=0.7?100:r<=1?80:r<=1.5?60:r<=2?40:20); print s}'; }
score_mem() { awk -v m="$MEM_USED_PERC" 'BEGIN{ s=100-m; if(s<0)s=0; print s}'; }
score_swap() { awk -v s="$SWAP_USED_PERC" 'BEGIN{ if(s==0) print 100; else {v=100-(s*2); if(v<0)v=0; print v} }'; }
score_disk() { awk -v d="$ROOT_USE_PERC" 'BEGIN{s=100-d;if(s<0)s=0;print s}'; }
score_smart() { [[ "$SMART_OVERALL" == "FAILED" ]] && echo 0 || echo 100; }
score_temp() { awk -v t="$TEMP_MAX" 'BEGIN{if(t==0){print 100;exit} if(t<60)print 100; else if(t<70)print 80; else if(t<80)print 60; else if(t<90)print 30; else print 10}'; }
score_failed_services() { awk -v f="$FAILED_SERVICES" 'BEGIN{v=100-(f*10); if(v<0)v=0; print v}'; }
score_logs() { awk -v l="$CRIT_LOGS" 'BEGIN{v=100-(l*5); if(v<0)v=0; print v}'; }

CPU_SCORE=$(score_cpu)
MEM_SCORE=$(score_mem)
SWAP_SCORE=$(score_swap)
DISK_SCORE=$(score_disk)
SMART_SCORE=$(score_smart)
TEMP_SCORE=$(score_temp)
FAILED_SVC_SCORE=$(score_failed_services)
LOG_SCORE=$(score_logs)

W_CPU=20; W_MEM=20; W_DISK=15; W_SWAP=5; W_SMART=15; W_TEMP=10; W_FAILSVC=10; W_LOGS=5
HEALTH_SCORE=$(awk -v c="$CPU_SCORE" -v wc="$W_CPU" -v m="$MEM_SCORE" -v wm="$W_MEM" -v d="$DISK_SCORE" -v wd="$W_DISK" -v s="$SWAP_SCORE" -v ws="$W_SWAP" -v sm="$SMART_SCORE" -v wsm="$W_SMART" -v t="$TEMP_SCORE" -v wt="$W_TEMP" -v fs="$FAILED_SVC_SCORE" -v wfs="$W_FAILSVC" -v lg="$LOG_SCORE" -v wlg="$W_LOGS" 'BEGIN{total=c*wc+m*wm+d*wd+s*ws+sm*wsm+t*wt+fs*wfs+lg*wlg;score=total/100;if(score<0)score=0;if(score>100)score=100;printf("%.0f",score)}')

if ((HEALTH_SCORE<20)); then HEALTH_LABEL="poor"; HEALTH_COLOR="#c23b22"
elif ((HEALTH_SCORE<40)); then HEALTH_LABEL="very poor"; HEALTH_COLOR="#ff6f61"
elif ((HEALTH_SCORE<60)); then HEALTH_LABEL="good"; HEALTH_COLOR="#f0ad4e"
elif ((HEALTH_SCORE<80)); then HEALTH_LABEL="very good"; HEALTH_COLOR="#5cb85c"
else HEALTH_LABEL="excellent"; HEALTH_COLOR="#2a9d8f"; fi

# --------------------------
# Application Health Check
# --------------------------
find_unit() { for u in "$@"; do systemctl list-units --all --type=service --full --no-legend | awk '{print $1}' | grep -xq "$u" && { printf '%s' "$u"; return 0; }; done; return 1; }
check_service() { local u="$1"; local s="STOPPED"; local t="-"; [[ -n "$u" ]] && systemctl is-active --quiet "$u" && s="RUNNING"; t=$(systemctl show -p ActiveEnterTimestamp --value "$u" 2>/dev/null||echo "-"); printf '%s\t%s' "$s" "$t"; }
JENKINS_UNIT=$(find_unit jenkins jenkins.service)
TOMCAT_UNIT=$(find_unit tomcat tomcat.service tomcat9 tomcat10 catalina)
JIRA_UNIT=$(find_unit jiraserver jira atlassian-jira)
read -r JENKINS_STATUS JENKINS_SINCE <<< "$(check_service "$JENKINS_UNIT" | awk -F'\t' '{print $1,$2}')"
read -r TOMCAT_STATUS TOMCAT_SINCE <<< "$(check_service "$TOMCAT_UNIT" | awk -F'\t' '{print $1,$2}')"
read -r JIRA_STATUS JIRA_SINCE <<< "$(check_service "$JIRA_UNIT" | awk -F'\t' '{print $1,$2}')"

status_badge() {
    local status="$1"
    if [[ "$status" == "RUNNING" ]]; then
        echo '<span style="color:#fff; background:#5cb85c; padding:3px 8px; border-radius:12px; font-weight:700;">RUNNING</span>'
    else
        echo '<span style="color:#fff; background:#c23b22; padding:3px 8px; border-radius:12px; font-weight:700;">STOPPED</span>'
    fi
}

JENKINS_HTML=$(status_badge "$JENKINS_STATUS")
TOMCAT_HTML=$(status_badge "$TOMCAT_STATUS")
JIRA_HTML=$(status_badge "$JIRA_STATUS")

# --------------------------
# Start HTML
# --------------------------
cat > "$TMPHTML" <<HTML
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Linux System Health Report - $HOSTNAME</title>
<style>
body { font-family: "Segoe UI", Roboto, Arial, sans-serif; background:#f5f7fa; color:#222; margin:20px; }
.header { background: linear-gradient(90deg,#e6f7ff,#f0f9ff); padding:18px; border-radius:10px; box-shadow:0 2px 6px rgba(0,0,0,0.05); }
.title { font-size:20px; font-weight:700; margin:0; color:#0b5f86; }
.subtitle { margin:4px 0 0 0; color:#555; font-size:13px; }
.container { display:grid; grid-template-columns: 1fr 360px; gap:16px; margin-top:16px; }
.panel { background:#fff; border-radius:8px; padding:14px; box-shadow:0 1px 4px rgba(14,20,24,0.06); margin-top:12px; }
.summary { border-left:6px solid $HEALTH_COLOR; }
.summary h3 { margin:0 0 8px 0; }
table { width:100%; border-collapse:collapse; font-size:13px; }
th, td { padding:8px 10px; border-bottom:1px solid #f0f2f5; text-align:left; vertical-align:top; }
th { background:#f7fbff; font-weight:600; color:#0b5f86; }
.metric { font-weight:700; color:#333; }
.small { font-size:12px; color:#666; }
.pre { background:#fbfbfd; padding:8px; border-radius:6px; overflow:auto; font-family:monospace; font-size:12px; white-space:pre-wrap; }
.health-badge { display:inline-block; padding:6px 10px; border-radius:20px; color:#fff; font-weight:700; }
.scroll-x { overflow-x:auto; }
.red { color:#fff; background:#c23b22; padding:2px 6px; border-radius:4px; font-weight:700;}
.orange { color:#fff; background:#ff6f00; padding:2px 6px; border-radius:4px; font-weight:700;}
.separator { border-top:2px solid #0b5f86; margin:10px 0;}
</style>
</head>
<body>
<div class="header">
<p class="title">Linux System Health Report</p>
<p class="subtitle"><strong>Host:</strong> $HOSTNAME &nbsp;&nbsp; <strong>Date:</strong> $NOW</p>
</div>
<div class="container">
<div> <!-- LEFT COLUMN -->

<!-- System Summary -->
<div class="panel summary">
<h3>System Summary</h3>
<table>
<tr><th>Item</th><th>Value</th></tr>
<tr><td class="metric">Hostname</td><td>$(safe_html "$HOSTNAME")</td></tr>
<tr><td class="metric">Kernel</td><td>$(safe_html "$KERNEL_VER")</td></tr>
<tr><td class="metric">CPU</td><td>$(safe_html "$LSCPU_MODEL") · $CPU_CORES cores</td></tr>
<tr><td class="metric">Total RAM</td><td>$(safe_html "$RAM_TOTAL")</td></tr>
<tr><td class="metric">BIOS Vendor</td><td>$(safe_html "$BIOS_VENDOR")</td></tr>
<tr><td class="metric">BIOS Version</td><td>$(safe_html "$BIOS_VERSION")</td></tr>
<tr><td class="metric">BIOS Date</td><td>$(safe_html "$BIOS_DATE")</td></tr>
<tr><td class="metric">Boot Mode</td><td>$(safe_html "$BOOT_MODE")</td></tr>
<tr><td class="metric">Overall Health</td><td><span class="health-badge" style="background:$HEALTH_COLOR;">$HEALTH_LABEL ($HEALTH_SCORE%)</span></td></tr>
</table>
</div>

<!-- CPU & Load -->
<div class="panel">
<h3>CPU & Load</h3>
<table>
<tr><th>Metric</th><th>Value</th></tr>
<tr><td>Load (1 min)</td><td>$(printf '%.2f' "$LOAD1")</td></tr>
<tr><td>CPU Score</td><td>${CPU_SCORE}%</td></tr>
</table>
</div>

<!-- Memory & Swap -->
<div class="panel">
<h3>Memory & Swap</h3>
<table>
<tr><th>Metric</th><th>Value</th></tr>
<tr><td>Memory Used</td><td>${MEM_USED_PERC}%</td></tr>
<tr><td>Swap Used</td><td>${SWAP_USED_PERC}%</td></tr>
<tr><td>Memory Score</td><td>${MEM_SCORE}%</td></tr>
<tr><td>Swap Score</td><td>${SWAP_SCORE}%</td></tr>
</table>
</div>

<!-- Disk Usage -->
<div class="panel">
<h3>Disk Usage</h3>
<table>
<tr><th>Filesystem</th><th>Type</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mount</th></tr>
HTML

# Disk usage rows
df -hT | tail -n +2 | while read -r FS TYPE SZ USED AVAIL USEP MOUNT; do
  printf '<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n' \
  "$(safe_html "$FS")" "$(safe_html "$TYPE")" "$(safe_html "$SZ")" "$(safe_html "$USED")" "$(safe_html "$AVAIL")" "$(safe_html "$USEP")" "$(safe_html "$MOUNT")" >> "$TMPHTML"
done

cat >> "$TMPHTML" <<HTML
</table>
<p class="small">Root usage: ${ROOT_USE_PERC}% — Disk Score: ${DISK_SCORE}%</p>
</div>

<!-- Application Health Check -->
<div class="panel">
<h3>Application Health Check</h3>
<table>
<tr><th>Application</th><th>Status</th><th>Since</th></tr>
<tr><td>Jenkins</td><td>$JENKINS_HTML</td><td>$JENKINS_SINCE</td></tr>
<tr><td>Tomcat</td><td>$TOMCAT_HTML</td><td>$TOMCAT_SINCE</td></tr>
<tr><td>Jira</td><td>$JIRA_HTML</td><td>$JIRA_SINCE</td></tr>
</table>
</div>

<!-- Timeshift Snapshots -->
<div class="panel">
<h3>Timeshift Snapshots</h3>
<div class="pre">$(timeshift --list 2>/dev/null || echo "Timeshift not installed")</div>
</div>

<!-- Filesystem Inode Usage -->
<div class="panel">
<h3>Filesystem Inode Usage</h3>
<table>
<tr><th>Filesystem</th><th>Inodes Used</th><th>Inodes Free</th><th>Use%</th><th>Mounted on</th></tr>
$(df -i | tail -n +2 | awk '{print "<tr><td>" $1 "</td><td>" $3 "</td><td>" $4 "</td><td>" $5 "</td><td>" $6 "</td></tr>"}')
</table>
</div>

<!-- Last 5 Reboots -->
<div class="panel">
<h3>Last 5 Reboots</h3>
<div class="pre">$(last -n 5 -x | head -n 5)</div>
</div>

<!-- Cron Jobs -->
<div class="panel">
<h3>Cron Jobs (all users)</h3>
<div class="pre">
==== /etc/crontab ====
$(safe_html "$(cat /etc/crontab 2>/dev/null)")

<div class="separator"></div>

==== User Cron Jobs ====
$(for u in $(cut -f1 -d: /etc/passwd); do crontab -l -u "$u" 2>/dev/null; done)
</div>
</div>

<!-- Disk I/O Statistics -->
<div class="panel">
<h3>Disk I/O Statistics</h3>
<div class="pre">$(command -v iostat >/dev/null 2>&1 && iostat -xz 1 1 2>/dev/null || echo "iostat not available. Install sysstat package.")</div>
</div>

<!-- Active Network Connections -->
<div class="panel">
<h3>Active Network Connections</h3>
<div class="pre">$(ss -tunap 2>/dev/null | head -n 30)</div>
</div>

<!-- Open Ports & Listening Services -->
<div class="panel">
<h3>Open Ports & Listening Services</h3>
<div class="pre">$(ss -tulnp 2>/dev/null | head -n 30)</div>
</div>

<!-- NEW SECTIONS START HERE -->

<!-- Top Memory-consuming Processes (top 10) -->
<div class="panel">
<h3>Top Memory-consuming Processes (top 10)</h3>
<div class="pre">$(ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 11)</div>
</div>

<!-- Top CPU-consuming Processes (top 10) -->
<div class="panel">
<h3>Top CPU-consuming Processes (top 10)</h3>
<div class="pre">$(ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -n 11)</div>
</div>

<!-- Detailed Failed Services -->
<div class="panel">
<h3>Detailed Failed Services</h3>
<div class="pre">$(systemctl --failed --no-pager || echo "No failed services")</div>
</div>

<!-- Uptime & Last Boot -->
<div class="panel">
<h3>Uptime & Last Boot</h3>
<div class="pre">Uptime: $(uptime -p)
Last boot: $(who -b)</div>
</div>

<!-- Last 20 sudo commands -->
<div class="panel">
<h3>Last 20 sudo commands</h3>
<div class="pre">$(journalctl _COMM=sudo --no-pager | grep COMMAND | tail -n 20 || echo "No sudo commands found")</div>
</div>

<!-- Package Manager Health -->
<div class="panel">
<h3>Package Manager Health</h3>
<div class="pre">
$(if command -v apt &>/dev/null; then apt update -qq >/dev/null 2>&1 && apt list --upgradable 2>/dev/null || echo "APT package manager not healthy"; elif command -v yum &>/dev/null; then yum check-update >/dev/null 2>&1 && echo "YUM package manager OK" || echo "YUM check failed"; else echo "No supported package manager detected"; fi)
</div>
</div>

<!-- DNS Resolution Test -->
<div class="panel">
<h3>DNS Resolution Test</h3>
<div class="pre">
$(dig +short google.com || nslookup google.com || echo "DNS test failed")
</div>
</div>

<!-- Disk I/O / Latency Snapshot -->
<div class="panel">
<h3>Disk I/O / Latency Snapshot</h3>
<div class="pre">$(ioping -c 5 / 2>/dev/null || echo "ioping not available")</div>
</div>

<!-- Kernel dmesg Errors / Warnings (last 200 lines) -->
<div class="panel">
<h3>Kernel dmesg Errors / Warnings (last 200 lines)</h3>
<div class="pre">$(dmesg | tail -n 200 | grep -i -E "error|warn" || echo "No errors/warnings in last 200 lines")</div>
</div>

<!-- Disclaimer -->
<div class="panel">
<h3>Disclaimer</h3>
<p class="small">Contact: Author: Loganatha Raja &nbsp;&nbsp; Email: loganathr@gmail.com</p>
<p class="small">This report is for informational purposes only.</p>
</div>

</div> <!-- END LEFT COLUMN -->

<!-- RIGHT COLUMN / SIDEBAR -->
<div> 
<div class="panel">
<h3>Hardware Health Summary</h3>
<table>
<tr><th>Metric</th><th>Score</th></tr>
<tr><td>CPU</td><td>${CPU_SCORE}%</td></tr>
<tr><td>Memory</td><td>${MEM_SCORE}%</td></tr>
<tr><td>Swap</td><td>${SWAP_SCORE}%</td></tr>
<tr><td>Disk</td><td>${DISK_SCORE}%</td></tr>
<tr><td>SMART</td><td>${SMART_SCORE}%</td></tr>
<tr><td>Temperature</td><td>${TEMP_SCORE}%</td></tr>
<tr><td>Failed Services</td><td>${FAILED_SVC_SCORE}%</td></tr>
<tr><td>Critical Logs</td><td>${LOG_SCORE}%</td></tr>
<tr><td><b>Overall Health</b></td><td><span class="health-badge" style="background:$HEALTH_COLOR;">$HEALTH_SCORE%</span></td></tr>
</table>
</div>
</div> <!-- END RIGHT COLUMN -->

</div> <!-- END CONTAINER -->
</body>
</html>
HTML

# Send Email
if command -v mailx &>/dev/null; then
  cat "$TMPHTML" | mailx -a "Content-Type: text/html" -s "$SUBJECT" "$EMAIL"
fi

echo "Report generated and emailed to $EMAIL"


