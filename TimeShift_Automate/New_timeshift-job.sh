#!/usr/bin/env bash
# New_timeshift-job.sh 
# Robust Timeshift snapshot script with retries, inline email report, and concurrency check.
# HTML email report, with Timeshift snapshot list in plain text

set -euo pipefail

LOG_EMAIL="loganathr20@gmail.com"
MODE="${1:-Other}"   # Default to Other if not specified
TIMESHIFT_BIN="/usr/bin/timeshift"
TMPDIR=$(mktemp -d /tmp/new_timeshift.XXXX)
REPORT="$TMPDIR/report_${MODE}.txt"
HTML_REPORT="$TMPDIR/report_${MODE}.html"
RETRIES=2
SLEEP_BETWEEN=10          # Retry interval on failure
WAIT_IF_RUNNING=15        # Seconds to wait if another timeshift process is running

# Cleanup temp dir on exit
trap 'rm -rf "$TMPDIR"' EXIT

# Map mode -> tag/comment
if [[ "$MODE" == "Boottime" ]]; then
    TAG="B"
    COMMENT="Auto Boot Snapshot "
else
    TAG="O"
    COMMENT="Auto 12 Hour Snapshot "
fi

echo "== Timeshift snapshot (tag=$TAG) ==" > "$REPORT"
echo "Started: $(date -R)" >> "$REPORT"

# Wait if another timeshift process is running
while pgrep -x timeshift >/dev/null; do
    echo "Another timeshift process is running. Waiting $WAIT_IF_RUNNING seconds..." >> "$REPORT"
    sleep "$WAIT_IF_RUNNING"
done

# Create snapshot with retry
SUCCESS=0
for attempt in $(seq 1 $((RETRIES + 1))); do
    if "$TIMESHIFT_BIN" --create --tags "$TAG" --comments "$COMMENT" --scripted >> "$REPORT" 2>&1; then
        SUCCESS=1
        echo "Snapshot succeeded on attempt $attempt" >> "$REPORT"
        break
    else
        echo "WARNING: timeshift create failed on attempt $attempt" >> "$REPORT"
        if (( attempt <= RETRIES )); then
            echo "Retrying in $SLEEP_BETWEEN seconds..." >> "$REPORT"
            sleep "$SLEEP_BETWEEN"
        fi
    fi
done

if (( SUCCESS == 0 )); then
    echo "ERROR: Timeshift snapshot failed after $((RETRIES + 1)) attempts" >> "$REPORT"
fi

# Host and date info
echo >> "$REPORT"
echo "== Host / Date ==" >> "$REPORT"
echo "Host: $(hostname)" >> "$REPORT"
echo "Date: $(date -R)" >> "$REPORT"

# Disk usage
read -r DFPCT DFFREE < <(df -h / --output=pcent,avail | tail -1)
NUMUSED=$(echo "$DFPCT" | tr -d '%')
NUMFREE=$((100 - NUMUSED))
echo "Root: $(df -h / | tail -1)" >> "$REPORT"
echo "UsedPercent: ${NUMUSED}%  FreePercent: ${NUMFREE}%" >> "$REPORT"
if (( NUMFREE < 10 )); then
    echo "" >> "$REPORT"
    echo "WARNING: Free space < 10% on root (Free: ${NUMFREE}%)" >> "$REPORT"
fi

# Timeshift snapshot list
echo >> "$REPORT"
echo "== Timeshift snapshot list ==" >> "$REPORT"
SNAPSHOT_LIST=$("$TIMESHIFT_BIN" --list 2>&1 || true)
echo "$SNAPSHOT_LIST" >> "$REPORT"

# Systemd timers
echo >> "$REPORT"
echo "== Systemd timers (next runs) ==" >> "$REPORT"
NEWTIMERS=$(systemctl list-timers --all --no-legend | grep new_timeshift || true)
CINNAMON_TIMERS=$(systemctl list-timers --all --no-legend | grep -E "cinnamon|timeshift" || true)
echo "$NEWTIMERS" >> "$REPORT"
echo "$CINNAMON_TIMERS" >> "$REPORT"

# === HTML Helpers ===
colorize_line() {
    local line="$1"
    if [[ "$line" == *"ERROR"* ]]; then
        echo "<span style='color:red; font-weight:bold;'>$line</span>"
    elif [[ "$line" == *"WARNING"* ]]; then
        echo "<span style='color:orange; font-weight:bold;'>$line</span>"
    elif [[ "$line" == *"SUCCESS"* ]]; then
        echo "<span style='color:green; font-weight:bold;'>$line</span>"
    else
        echo "$line"
    fi
}

# Disk usage colors
if (( NUMFREE < 10 )); then
    USED_COLOR="red"
    FREE_COLOR="red"
elif (( NUMFREE < 20 )); then
    USED_COLOR="orange"
    FREE_COLOR="orange"
else
    USED_COLOR="green"
    FREE_COLOR="green"
fi

# === Build HTML Report ===
{
echo "<html><body style='font-family: Arial; background:#f4f4f4; padding:20px;'>"
echo "<div style='max-width:900px; margin:auto; background:white; border-radius:10px; padding:20px; border:1px solid #ddd;'>"

# Header
echo "<h2 style='background:#4a90e2; color:white; padding:15px; border-radius:8px; text-align:center;'>Timeshift Snapshot Report</h2>"

# Host info
echo "<table style='width:100%; border-collapse:collapse; margin-bottom:20px;'>"
for row in \
"Host|$(hostname)" \
"Date|$(date -R)" \
"Uptime|$(uptime -p)" \
"Kernel|$(uname -r)" \
"RAM|$(free -h | grep Mem:)"; do
    KEY=$(echo "$row" | cut -d'|' -f1)
    VAL=$(echo "$row" | cut -d'|' -f2-)
    echo "<tr style='background:#f0f7ff;'><th style='padding:10px; border:1px solid #ccc;'>$KEY</th><td style='padding:10px; border:1px solid #ccc;'>$VAL</td></tr>"
done
echo "</table>"

# Disk usage
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Disk Usage</h3>"
echo "<table style='width:100%; border-collapse:collapse; margin-bottom:20px;'>"
echo "<tr><th style='padding:10px; border:1px solid #ccc;'>Used %</th><td style='padding:10px; border:1px solid #ccc; color:$USED_COLOR;'>$NUMUSED%</td></tr>"
echo "<tr><th style='padding:10px; border:1px solid #ccc;'>Free %</th><td style='padding:10px; border:1px solid #ccc; color:$FREE_COLOR;'>$NUMFREE%</td></tr>"
echo "<tr><th style='padding:10px; border:1px solid #ccc;'>Root FS</th><td style='padding:10px; border:1px solid #ccc;'>$(df -h / | tail -1)</td></tr>"
echo "</table>"

# Cleanup log
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Snapshot Log</h3>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>"
while IFS= read -r line; do
    colorize_line "$line"
done < "$REPORT"
echo "</div>"

# Timeshift Snapshot List (plain text)
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Timeshift Snapshot List</h3>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>"
echo "$SNAPSHOT_LIST"
echo "</div>"

# Systemd timers
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Systemd Timers</h3>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>$NEWTIMERS</div>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>$CINNAMON_TIMERS</div>"

echo "<div style='text-align:center; font-size:12px; color:#777; margin-top:20px;'>Report generated automatically by Timeshift Snapshot Script — $(hostname)</div>"

echo "</div></body></html>"
} > "$HTML_REPORT"

# Send email
SUBJ="[${HOSTNAME}] Timeshift_report_snapshot mode=$MODE - $(date '+%Y-%m-%d %H:%M:%S')"
if command -v msmtp >/dev/null 2>&1; then
{
    echo "To: $LOG_EMAIL"
    echo "Subject: $SUBJ"
    echo "MIME-Version: 1.0"
    echo "Content-Type: multipart/mixed; boundary=\"BOUNDARY\""
    echo
    echo "--BOUNDARY"
    echo "Content-Type: text/html; charset=UTF-8"
    echo
    cat "$HTML_REPORT"
    echo "--BOUNDARY"
    echo "Content-Type: text/plain; name=\"snapshot_log.txt\""
    echo "Content-Disposition: attachment; filename=\"snapshot_log.txt\""
    echo
    cat "$REPORT"
    echo "--BOUNDARY--"
} | msmtp "$LOG_EMAIL" || echo "WARNING: Mail send failed"
else
    echo "msmtp not found. Report saved at $HTML_REPORT"
fi

exit 0

