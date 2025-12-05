#!/bin/bash
# Linux System Health Report (Blue Professional, final)
# - Fixed SMART parsing (no awk regexp errors)
# - Systemd timers displayed raw (preformatted text, readable)
# - Top processes moved under timers
# - BIOS included in System Summary (Unknown Vendor fallback)
# - Overall weighted health score (Option A)
# Usage: sudo bash /usr/local/bin/linux_hardware_report.sh

EMAIL="loganathr20@gmail.com"
SUBJECT="Linux System Health Report - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')"
TMPHTML=$(mktemp /tmp/sys_health_XXXX.html)
TMPTXT=$(mktemp /tmp/sys_health_XXXX.txt)

trap 'rm -f "$TMPHTML" "$TMPTXT"' EXIT

# Use sudo where necessary if not root
SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

# HTML escape helper
safe_html() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# color helper for SMART status display
color_status_html() {
  local s="$1"
  if echo "$s" | grep -iq 'pass\|ok'; then
    printf '<b style="color:#1b8f1b;">PASS</b>'
  elif echo "$s" | grep -iq 'fail'; then
    printf '<b style="color:#c23b22;">FAILED</b>'
  else
    printf '<b style="color:#f0ad4e;">%s</b>' "$(safe_html "$s")"
  fi
}

# Pre-capture common outputs
PS_OUTPUT=$(ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu,-%mem 2>/dev/null || true)
LSCPU_MODEL=$(lscpu 2>/dev/null | awk -F: '/Model name/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' || echo "Unknown CPU")
CPU_CORES=$(lscpu 2>/dev/null | awk -F: '/^CPU\(s\)/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' || echo "1")
KERNEL_VER=$(uname -r 2>/dev/null || echo "N/A")
RAM_TOTAL=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo "N/A")
HOSTNAME=$(hostname)
NOW=$(date '+%Y-%m-%d %H:%M:%S %z')

# --- BIOS extraction with fallbacks ---
BIOS_VENDOR=$($SUDO dmidecode -s bios-vendor 2>/dev/null || echo "")
BIOS_VERSION=$($SUDO dmidecode -s bios-version 2>/dev/null || echo "")
BIOS_DATE=$($SUDO dmidecode -s bios-release-date 2>/dev/null || echo "")

if [[ -z "$BIOS_VENDOR" || -z "$BIOS_VERSION" || -z "$BIOS_DATE" ]]; then
  if command -v dmidecode &>/dev/null; then
    BIOS_RAW=$($SUDO dmidecode -t bios 2>/dev/null || true)
    BIOS_VENDOR="${BIOS_VENDOR:-$(printf "%s" "$BIOS_RAW" | awk -F: '/Vendor:/ {gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')}"
    BIOS_VERSION="${BIOS_VERSION:-$(printf "%s" "$BIOS_RAW" | awk -F: '/Version:/ {gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')}"
    BIOS_DATE="${BIOS_DATE:-$(printf "%s" "$BIOS_RAW" | awk -F: '/Release Date:/ {gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')}"
  fi
fi

# sanitize placeholder vendor
if [[ -z "$BIOS_VENDOR" || "$BIOS_VENDOR" =~ (To\ Be\ Filled\ By\ O\.E\.M\.|OEM|Default\ String) ]]; then
  BIOS_VENDOR="Unknown Vendor"
fi
BIOS_VERSION=${BIOS_VERSION:-"Unknown Version"}
BIOS_DATE=${BIOS_DATE:-"Unknown Date"}

# Boot mode detection
if [[ -d /sys/firmware/efi ]]; then BOOT_MODE="UEFI"; else BOOT_MODE="Legacy"; fi

# --- Metrics for scoring (Option A) ---
LOAD1=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{gsub(/^[ \t]+/,"",$1); print $1}' 2>/dev/null)
LOAD1=${LOAD1:-0}
MEM_USED_PERC=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
MEM_USED_PERC=${MEM_USED_PERC:-0}
SWAP_USED_PERC=$(free | awk '/Swap:/ {if ($2==0) print 0; else printf "%.0f", $3/$2*100}')
SWAP_USED_PERC=${SWAP_USED_PERC:-0}
ROOT_USE_PERC=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9')
ROOT_USE_PERC=${ROOT_USE_PERC:-0}

# SMART overall (safe check)
SMART_OVERALL="OK"
if command -v smartctl &>/dev/null; then
  for d in /dev/sd[a-z] /dev/nvme*n*; do
    [[ -b "$d" ]] || continue
    out=$($SUDO smartctl -H "$d" 2>&1)
    if echo "$out" | grep -iq 'failed'; then
      SMART_OVERALL="FAILED"
      break
    fi
  done
fi

# Temperatures (max)
TEMP_MAX=0
if command -v sensors &>/dev/null; then
  tmpvals=$(sensors 2>/dev/null | sed -n 's/.*\([0-9]\{1,3\}\)\.\?[0-9]*°C.*/\1/p')
  for t in $tmpvals; do [[ -z "$t" ]] && continue; (( t > TEMP_MAX )) && TEMP_MAX=$t; done
fi

FAILED_SERVICES=$(systemctl --failed --no-legend 2>/dev/null | grep -c .)
FAILED_SERVICES=${FAILED_SERVICES:-0}
CRIT_LOGS=$(journalctl -p 3 -n 100 --no-pager 2>/dev/null | grep -c .)
CRIT_LOGS=${CRIT_LOGS:-0}

# --- Component scoring functions ---
score_cpu() {
  awk -v ld="$LOAD1" -v cores="${CPU_CORES:-1}" 'BEGIN{
    ratio = (cores>0) ? (ld/cores) : ld;
    if (ratio <= 0.7) { print 100; exit }
    else if (ratio <= 1.0) { print 80; exit }
    else if (ratio <= 1.5) { print 60; exit }
    else if (ratio <= 2.0) { print 40; exit }
    else { print 20; exit }
  }'
}
score_mem() { awk -v m="$MEM_USED_PERC" 'BEGIN{ s = 100 - m; if (s<0) s=0; print int(s) }'; }
score_swap() { awk -v s="$SWAP_USED_PERC" 'BEGIN{ if (s==0) print 100; else { val = 100 - (s*2); if (val<0) val=0; print int(val) } }'; }
score_disk() { awk -v d="$ROOT_USE_PERC" 'BEGIN{ s = 100 - d; if (s<0) s=0; print int(s) }'; }
score_smart() { [[ "$SMART_OVERALL" == "FAILED" ]] && echo 0 || echo 100; }
score_temp() { awk -v t="$TEMP_MAX" 'BEGIN{ if (t==0) { print 100; exit } if (t < 60) print 100; else if (t < 70) print 80; else if (t < 80) print 60; else if (t < 90) print 30; else print 10; }'; }
score_failed_services() { awk -v f="$FAILED_SERVICES" 'BEGIN{ val = 100 - (f * 10); if (val<0) val=0; print int(val) }'; }
score_logs() { awk -v l="$CRIT_LOGS" 'BEGIN{ val=100 - (l * 5); if (val<0) val=0; print int(val) }'; }

CPU_SCORE=$(score_cpu)
MEM_SCORE=$(score_mem)
SWAP_SCORE=$(score_swap)
DISK_SCORE=$(score_disk)
SMART_SCORE=$(score_smart)
TEMP_SCORE=$(score_temp)
FAILED_SVC_SCORE=$(score_failed_services)
LOG_SCORE=$(score_logs)

# weights
W_CPU=20; W_MEM=20; W_DISK=15; W_SWAP=5; W_SMART=15; W_TEMP=10; W_FAILSVC=10; W_LOGS=5

HEALTH_SCORE=$(awk -v c="$CPU_SCORE" -v wc="$W_CPU" \
                     -v m="$MEM_SCORE" -v wm="$W_MEM" \
                     -v d="$DISK_SCORE" -v wd="$W_DISK" \
                     -v s="$SWAP_SCORE" -v ws="$W_SWAP" \
                     -v sm="$SMART_SCORE" -v wsm="$W_SMART" \
                     -v t="$TEMP_SCORE" -v wt="$W_TEMP" \
                     -v fs="$FAILED_SVC_SCORE" -v wfs="$W_FAILSVC" \
                     -v lg="$LOG_SCORE" -v wlg="$W_LOGS" \
                     'BEGIN{
                         total = c*wc + m*wm + d*wd + s*ws + sm*wsm + t*wt + fs*wfs + lg*wlg;
                         score = total / 100.0;
                         if (score<0) score=0;
                         if (score>100) score=100;
                         printf("%.0f", score);
                     }')

if (( HEALTH_SCORE < 20 )); then HEALTH_LABEL="poor"
elif (( HEALTH_SCORE < 40 )); then HEALTH_LABEL="very poor"
elif (( HEALTH_SCORE < 60 )); then HEALTH_LABEL="good"
elif (( HEALTH_SCORE < 80 )); then HEALTH_LABEL="very good"
else HEALTH_LABEL="excellent"
fi

case "$HEALTH_LABEL" in
  "poor") HEALTH_COLOR="#c23b22" ;;
  "very poor") HEALTH_COLOR="#ff6f61" ;;
  "good") HEALTH_COLOR="#f0ad4e" ;;
  "very good") HEALTH_COLOR="#5cb85c" ;;
  "excellent") HEALTH_COLOR="#2a9d8f" ;;
  *) HEALTH_COLOR="#999999" ;;
esac

# --- Start HTML (Blue Professional) ---
cat > "$TMPHTML" <<HTML
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Linux System Health Report - ${HOSTNAME}</title>
<style>
  body { font-family: "Segoe UI", Roboto, Arial, sans-serif; background:#f5f7fa; color:#222; margin:20px; }
  .header { background: linear-gradient(90deg,#e6f7ff,#f0f9ff); padding:18px; border-radius:10px; box-shadow:0 2px 6px rgba(0,0,0,0.05); }
  .title { font-size:20px; font-weight:700; margin:0; color:#0b5f86; }
  .subtitle { margin:4px 0 0 0; color:#555; font-size:13px; }
  .container { display:grid; grid-template-columns: 1fr 360px; gap:16px; margin-top:16px; }
  .panel { background:#fff; border-radius:8px; padding:14px; box-shadow:0 1px 4px rgba(14,20,24,0.06); }
  .summary { border-left:6px solid ${HEALTH_COLOR}; }
  .summary h3 { margin:0 0 8px 0; }
  table { width:100%; border-collapse:collapse; font-size:13px; }
  th, td { padding:8px 10px; border-bottom:1px solid #f0f2f5; text-align:left; vertical-align:top; }
  th { background:#f7fbff; font-weight:600; color:#0b5f86; }
  .metric { font-weight:700; color:#333; }
  .small { font-size:12px; color:#666; }
  .pre { background:#fbfbfd; padding:8px; border-radius:6px; overflow:auto; font-family:monospace; font-size:12px; white-space:pre-wrap; }
  .health-badge { display:inline-block; padding:6px 10px; border-radius:20px; color:#fff; font-weight:700; }
  .graph { margin-top:8px; }
  .scroll-x { overflow-x:auto; }
</style>
</head>
<body>
  <div class="header">
    <p class="title">Linux System Health Report</p>
    <p class="subtitle"><strong>Host:</strong> ${HOSTNAME} &nbsp;&nbsp; <strong>Date:</strong> ${NOW}</p>
  </div>

  <div class="container">
    <div>
      <div class="panel summary">
        <h3>System Summary</h3>
        <p class="small">Overview & overall health</p>
        <table>
          <tr><th style="width:40%;">Item</th><th>Value</th></tr>
          <tr><td class="metric">Hostname</td><td>$(safe_html "$HOSTNAME")</td></tr>
          <tr><td class="metric">Kernel</td><td>$(safe_html "$KERNEL_VER")</td></tr>
          <tr><td class="metric">CPU</td><td>$(safe_html "$LSCPU_MODEL") · ${CPU_CORES:-1} cores</td></tr>
          <tr><td class="metric">Total RAM</td><td>$(safe_html "$RAM_TOTAL")</td></tr>
          <tr><td class="metric">BIOS Vendor</td><td>$(safe_html "$BIOS_VENDOR")</td></tr>
          <tr><td class="metric">BIOS Version</td><td>$(safe_html "$BIOS_VERSION")</td></tr>
          <tr><td class="metric">BIOS Date</td><td>$(safe_html "$BIOS_DATE")</td></tr>
          <tr><td class="metric">Boot Mode</td><td>$(safe_html "$BOOT_MODE")</td></tr>
          <tr><td class="metric">Overall Health</td><td><span class="health-badge" style="background:${HEALTH_COLOR}; text-transform:uppercase;">${HEALTH_LABEL} (${HEALTH_SCORE}%)</span></td></tr>
        </table>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>CPU & Load</h3>
        <table>
          <tr><th>Metric</th><th>Value</th></tr>
          <tr><td>Load (1 min)</td><td>$(printf '%.2f' "$LOAD1")</td></tr>
          <tr><td>Uptime</td><td>$(uptime -p 2>/dev/null || echo "N/A")</td></tr>
          <tr><td>CPU component score</td><td>${CPU_SCORE}%</td></tr>
        </table>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>Memory & Swap</h3>
        <table>
          <tr><th>Metric</th><th>Value</th></tr>
          <tr><td>Memory Used</td><td>${MEM_USED_PERC}%</td></tr>
          <tr><td>Swap Used</td><td>${SWAP_USED_PERC}%</td></tr>
          <tr><td>Memory score</td><td>${MEM_SCORE}%</td></tr>
          <tr><td>Swap score</td><td>${SWAP_SCORE}%</td></tr>
        </table>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>Disk</h3>
        <table>
          <tr><th>Filesystem</th><th>Type</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mount</th></tr>
HTML

# Append disk rows
df -hT | tail -n +2 | while read -r FS TYPE SZ USED AVAIL USEP MOUNT; do
  printf '<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n' \
    "$(safe_html "$FS")" "$(safe_html "$TYPE")" "$(safe_html "$SZ")" "$(safe_html "$USED")" "$(safe_html "$AVAIL")" "$(safe_html "$USEP")" "$(safe_html "$MOUNT")" >> "$TMPHTML"
done

cat >> "$TMPHTML" <<HTML
        </table>
        <p class="small">Root usage: ${ROOT_USE_PERC}% — disk score: ${DISK_SCORE}%</p>
      </div>

      <!-- SMART Disk Health (5-column table, safe parsing) -->
      <div class="panel" style="margin-top:12px;">
        <h3>SMART Disk Health</h3>
        <div class="scroll-x">
          <table>
            <tr><th>Device</th><th>Status</th><th>Temperature (°C)</th><th>Reallocated_Sector_Ct</th><th>Power_On_Hours</th></tr>
HTML

# SMART rows (safe parser)
if command -v smartctl &>/dev/null; then
  for d in /dev/sd[a-z] /dev/nvme*n*; do
    [[ -b "$d" ]] || continue
    SMART_OUT=$($SUDO smartctl -A -H "$d" 2>/dev/null || true)

    # Overall health: try common phrases safely with grep
    HEALTH_RAW=$(printf "%s\n" "$SMART_OUT" | grep -iE 'SMART overall-health|SMART overall health|overall-health|result' -m1 || true)
    # try fallback: look for 'PASSED' or 'FAILED'
    if printf "%s\n" "$HEALTH_RAW" | grep -iq 'PASSED\|OK'; then
      HEALTH="PASSED"
    elif printf "%s\n" "$HEALTH_RAW" | grep -iq 'FAILED\|FAIL'; then
      HEALTH="FAILED"
    else
      # last resort: search for PASSED/FAILED anywhere
      if printf "%s\n" "$SMART_OUT" | grep -iq 'PASSED\|OK'; then HEALTH="PASSED"
      elif printf "%s\n" "$SMART_OUT" | grep -iq 'FAILED\|FAIL'; then HEALTH="FAILED"
      else HEALTH="UNKNOWN"
      fi
    fi

    # Temperature: search for first numeric before "°C"
    TEMP=$(printf "%s\n" "$SMART_OUT" | sed -n 's/.*\([0-9]\{1,3\}\)\.\?[0-9]*°C.*/\1/p' | head -n1)
    TEMP=${TEMP:-"-"}

    # Reallocated sectors: search attribute lines
    REALL=$(printf "%s\n" "$SMART_OUT" | awk '/Reallocated_Sector_Ct|Reallocated_Sector_Count|Reallocated_Sectors/ { for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+$/) { print $i; break } }' | head -n1)
    REALL=${REALL:-"-"}

    # Power on hours
    POH=$(printf "%s\n" "$SMART_OUT" | awk '/Power_On_Hours|Power on hours/ { for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+$/) { print $i; break } }' | head -n1)
    POH=${POH:-"-"}

    # Format status cell with color
    STATUS_CELL=$(color_status_html "$HEALTH")

    printf '<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n' \
      "$(safe_html "$d")" "$STATUS_CELL" "$(safe_html "$TEMP")" "$(safe_html "$REALL")" "$(safe_html "$POH")" >> "$TMPHTML"
  done
else
  echo '<tr><td colspan="5" class="small">smartctl not installed; install smartmontools for SMART details.</td></tr>' >> "$TMPHTML"
fi

cat >> "$TMPHTML" <<HTML
          </table>
        </div>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>Temperatures</h3>
        <table>
          <tr><th>Sensor</th><th>Value</th></tr>
HTML

# Temperatures table
if command -v sensors &>/dev/null; then
  sensors | while read -r LINE; do
    if [[ "$LINE" == *:* ]]; then
      NAME=$(echo "$LINE" | cut -d: -f1)
      VAL=$(echo "$LINE" | cut -d: -f2-)
      printf '<tr><td>%s</td><td>%s</td></tr>\n' "$(safe_html "$NAME")" "$(safe_html "$VAL")" >> "$TMPHTML"
    fi
  done
else
  echo '<tr><td colspan="2" class="small">lm-sensors not installed.</td></tr>' >> "$TMPHTML"
fi

cat >> "$TMPHTML" <<HTML
        </table>
        <p class="small">Max detected temp: ${TEMP_MAX}°C — temp score: ${TEMP_SCORE}%</p>
      </div>

      <!-- Systemd timers: RAW output in <pre> blocks for readability (no table formatting) -->
      <div class="panel" style="margin-top:12px;">
        <h3>Systemd Timers — Important (filtered)</h3>
        <div class="pre">$(safe_html "$(systemctl list-timers --all 2>/dev/null | grep -E 'cinnamon|timeshift|linux_hardware_report.timer' || echo 'No important timers found.')")</div>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>Systemd Timers — All (raw)</h3>
        <div class="pre">$(safe_html "$(systemctl list-timers --all 2>/dev/null || echo 'systemctl not available')")</div>
      </div>

      <!-- Top processes (after timers) shown as pre blocks -->
      <div class="panel" style="margin-top:12px;">
        <h3>Top CPU-consuming processes (top 10)</h3>
        <div class="pre">$(safe_html "$(echo "$PS_OUTPUT" | head -n 10)")</div>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>Top processes by CPU+Memory</h3>
        <div class="pre">$(safe_html "$(ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu,-%mem | head -n 10)")</div>
      </div>

    </div>

    <!-- Right column (quick metrics and smaller panels) -->
    <div>
      <div class="panel">
        <h3>Quick Metrics</h3>
        <table>
          <tr><th>Metric</th><th>Value</th></tr>
          <tr><td>CPU score</td><td>${CPU_SCORE}%</td></tr>
          <tr><td>Memory score</td><td>${MEM_SCORE}%</td></tr>
          <tr><td>Disk score</td><td>${DISK_SCORE}%</td></tr>
          <tr><td>Swap score</td><td>${SWAP_SCORE}%</td></tr>
          <tr><td>SMART score</td><td>${SMART_SCORE}%</td></tr>
          <tr><td>Temp score</td><td>${TEMP_SCORE}%</td></tr>
          <tr><td>Failed svc score</td><td>${FAILED_SVC_SCORE}%</td></tr>
          <tr><td>Log score</td><td>${LOG_SCORE}%</td></tr>
        </table>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>Network Interfaces & IPs</h3>
        <div class="pre">$(safe_html "$(ip -brief addr show 2>/dev/null || echo 'ip not available')")</div>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>Recent Critical Logs (last 20)</h3>
        <div class="pre">$(safe_html "$(journalctl -p 3 -n 20 --no-pager 2>/dev/null || echo 'journalctl not available')")</div>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>Failed Services</h3>
        <div class="pre">$(safe_html "$(systemctl --failed 2>/dev/null || echo 'systemctl not available')")</div>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>Available Package Updates (apt)</h3>
        <div class="pre">$(safe_html "$(apt list --upgradable 2>/dev/null | sed '1d' || echo 'apt not available or no upgrades')")</div>
      </div>

      <div class="panel" style="margin-top:12px;">
        <h3>PCI & USB Devices</h3>
        <div class="pre">$(safe_html "$(lspci -vvnn 2>/dev/null || echo 'lspci not available')")</div>
        <div class="pre" style="margin-top:6px;">$(safe_html "$(lsusb 2>/dev/null || echo 'lsusb not available')")</div>
      </div>

    </div>
  </div>
</body>
</html>
HTML

# Save raw HTML copy
cp "$TMPHTML" "$TMPTXT"

# Send email via msmtp (HTML only). Suppress msmtp stderr to avoid logfile permission warnings.
# Permanent fix: edit /etc/msmtprc or ~/.msmtprc and remove/comment "logfile /var/log/msmtp.log"
{
  echo "Subject: $SUBJECT"
  echo "MIME-Version: 1.0"
  echo "Content-Type: text/html; charset=UTF-8"
  echo
  cat "$TMPHTML"
} | msmtp -a default "$EMAIL" 2>/dev/null

exit 0


