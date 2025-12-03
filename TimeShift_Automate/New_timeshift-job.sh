#!/usr/bin/env bash
# New_timeshift-job.sh with HTML email, tables, color-coded logs, attachments, host info
# Timeshift snapshot list now in proper HTML table

set -euo pipefail

LOG_EMAIL="loganathr20@gmail.com"
MODE="${1:-Other}"
TIMESHIFT_BIN="/usr/bin/timeshift"
TMPDIR=$(mktemp -d /tmp/new_timeshift.XXXX)
RAW_REPORT="$TMPDIR/raw_report.txt"
HTML_REPORT="$TMPDIR/final_report.html"
RETRIES=2
SLEEP_BETWEEN=10
WAIT_IF_RUNNING=15

trap 'rm -rf "$TMPDIR"' EXIT

# === Tag mapping ===
if [[ "$MODE" == "Boottime" ]]; then
    TAG="B"
    COMMENT="Auto Boot Snapshot "
else
    TAG="O"
    COMMENT="Auto 12 Hour Snapshot "
fi

# === RAW LOG COLLECTION ===
echo "== Timeshift snapshot (tag=$TAG) ==" > "$RAW_REPORT"
echo "Started: $(date -R)" >> "$RAW_REPORT"

while pgrep -x timeshift >/dev/null; do
    echo "WARNING: Another Timeshift instance running. Waiting $WAIT_IF_RUNNING seconds..." >> "$RAW_REPORT"
    sleep "$WAIT_IF_RUNNING"
done

SUCCESS=0
for attempt in $(seq 1 $((RETRIES+1))); do
    if "$TIMESHIFT_BIN" --create --tags "$TAG" --comments "$COMMENT" --scripted >> "$RAW_REPORT" 2>&1; then
        echo "SUCCESS: Snapshot succeeded on attempt $attempt" >> "$RAW_REPORT"
        SUCCESS=1
        break
    else
        echo "WARNING: Snapshot attempt $attempt failed" >> "$RAW_REPORT"
        if (( attempt <= RETRIES )); then
            echo "Retrying in $SLEEP_BETWEEN seconds..." >> "$RAW_REPORT"
            sleep "$SLEEP_BETWEEN"
        fi
    fi
done

if (( SUCCESS == 0 )); then
    echo "ERROR: Snapshot failed after $((RETRIES+1)) attempts" >> "$RAW_REPORT"
fi

echo >> "$RAW_REPORT"
echo "== Host / Date ==" >> "$RAW_REPORT"
echo "Host: $(hostname)" >> "$RAW_REPORT"
echo "Date: $(date -R)" >> "$RAW_REPORT"
echo "Uptime: $(uptime -p)" >> "$RAW_REPORT"
echo "Kernel: $(uname -r)" >> "$RAW_REPORT"
echo "RAM Usage: $(free -h | grep Mem:)" >> "$RAW_REPORT"

# Disk
read -r DFPCT DFFREE < <(df -h / --output=pcent,avail | tail -1)
NUMUSED=$(echo "$DFPCT" | tr -d '%')
NUMFREE=$((100 - NUMUSED))
ROOT_FS=$(df -h / | tail -1)

echo >> "$RAW_REPORT"
echo "Disk usage: $ROOT_FS" >> "$RAW_REPORT"
echo "UsedPercent: ${NUMUSED}%" >> "$RAW_REPORT"
echo "FreePercent: ${NUMFREE}%" >> "$RAW_REPORT"
if (( NUMFREE < 10 )); then
    echo "WARNING: Free space < 10%" >> "$RAW_REPORT"
fi

# Timeshift snapshot list
SNAPSHOT_RAW=$("$TIMESHIFT_BIN" --list 2>/dev/null || true)

# Extract header and rows
SNAPSHOT_TABLE_HTML="<table style='width:100%; border-collapse:collapse;'>
<tr style='background:#4a90e2; color:white;'>
<th style='padding:8px; border:1px solid #ccc;'>Num</th>
<th style='padding:8px; border:1px solid #ccc;'>Name</th>
<th style='padding:8px; border:1px solid #ccc;'>Tags</th>
<th style='padding:8px; border:1px solid #ccc;'>Description</th>
</tr>"

# Parse snapshot lines into HTML table rows
while IFS= read -r line; do
    # Skip empty lines and header line with dashes
    [[ -z "$line" || "$line" =~ ^[-]+$ ]] && continue
    # Columns may be separated by spaces (Num Name Tags Description)
    NUM=$(echo "$line" | awk '{print $1}')
    NAME=$(echo "$line" | awk '{print $2}')
    TAGS=$(echo "$line" | awk '{print $3}')
    DESC=$(echo "$line" | cut -d' ' -f4-)
    # Alternate row color
    ROW_COLOR="#f9f9f9"
    SNAPSHOT_TABLE_HTML+="<tr style='background:$ROW_COLOR;'>
        <td style='padding:6px; border:1px solid #ccc;'>$NUM</td>
        <td style='padding:6px; border:1px solid #ccc;'>$NAME</td>
        <td style='padding:6px; border:1px solid #ccc;'>$TAGS</td>
        <td style='padding:6px; border:1px solid #ccc;'>$DESC</td>
    </tr>"
done <<< "$SNAPSHOT_RAW"
SNAPSHOT_TABLE_HTML+="</table>"

# Systemd timers
NEWTIMERS=$(systemctl list-timers --all --no-legend | grep new_timeshift || true)
CINNAMON_TIMERS=$(systemctl list-timers --all --no-legend | grep -E "cinnamon|timeshift" || true)

# === HTML COLOR HELPERS ===
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

# Disk colors
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

# === BUILD FINAL HTML ===
{
echo "<html><body style='font-family: Arial; background:#f4f4f4; padding:20px;'>"
echo "<div style='max-width:900px; margin:auto; background:white; border-radius:10px; padding:20px; border:1px solid #ddd;'>"

# Header
echo "<h2 style='background:#4a90e2; color:white; padding:15px; border-radius:8px; text-align:center; margin-top:0;'>Timeshift Snapshot Report — Mode: <span style='color:yellow;'>$MODE</span></h2>"

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
echo "<tr><th style='padding:10px; border:1px solid #ccc;'>Root FS</th><td style='padding:10px; border:1px solid #ccc;'>$ROOT_FS</td></tr>"
echo "</table>"

# Snapshot log block
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Snapshot Log</h3>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>"
while IFS= read -r line; do
    colorize_line "$line"
done < "$RAW_REPORT"
echo "</div>"

# Snapshot list table
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Timeshift Snapshot List</h3>"
echo "$SNAPSHOT_TABLE_HTML"

# Systemd timers
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Systemd Timers (new_timeshift)</h3>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>$NEWTIMERS</div>"

echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Systemd Timers (cinnamon & timeshift)</h3>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>$CINNAMON_TIMERS</div>"

# Footer
echo "<div style='text-align:center; font-size:12px; color:#777; margin-top:20px;'>Report generated automatically by Timeshift Script — LinuxMint $(hostname)</div>"

echo "</div></body></html>"
} > "$HTML_REPORT"

# === SEND EMAIL WITH ATTACHMENT ===
SUBJ="[${HOSTNAME}] Timeshift_report_snapshot mode=$MODE - $(date '+%Y-%m-%d %H:%M:%S')"

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
    echo "Content-Type: text/plain; name=\"timeshift_raw_report.txt\""
    echo "Content-Disposition: attachment; filename=\"timeshift_raw_report.txt\""
    echo
    cat "$RAW_REPORT"
    echo "--BOUNDARY--"
} | msmtp "$LOG_EMAIL" || echo "WARNING: mail send failed"

exit 0


