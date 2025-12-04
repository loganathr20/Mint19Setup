#!/usr/bin/env bash
# Timeshift Cleanup Script - HTML Email Version
# Deletes "O" snapshots older than 1 day, keeps W/M/B, sends HTML report

set -euo pipefail

EMAIL="loganathr20@gmail.com"
MODE="${1:-Normal}"          # Default to Normal if no argument provided
TMPDIR=$(mktemp -d /tmp/timeshift_cleanup.XXXX)
RAW_REPORT="$TMPDIR/timeshift_cleanup_raw.txt"
HTML_REPORT="$TMPDIR/timeshift_cleanup.html"
TIMESHIFT_CMD="/usr/bin/timeshift"
DELETE_DAYS=1
DRYRUN=0

# Test mode
if [[ "$MODE" == "test" ]]; then
    DRYRUN=1
fi

SUBJECT="[${HOSTNAME}] Timeshift Cleanup Report - $(date '+%Y-%m-%d %H:%M:%S')"

# === Start raw log ===
echo "===== Timeshift Cleanup Report =====" > "$RAW_REPORT"
echo "Generated at: $(date)" >> "$RAW_REPORT"
echo "" >> "$RAW_REPORT"

# Disk BEFORE
echo "----- Disk Usage BEFORE Cleanup -----" >> "$RAW_REPORT"
df -h >> "$RAW_REPORT"
echo "" >> "$RAW_REPORT"

# Snapshots BEFORE
echo "----- Timeshift Snapshots BEFORE Cleanup -----" >> "$RAW_REPORT"
$TIMESHIFT_CMD --list >> "$RAW_REPORT" 2>&1
echo "" >> "$RAW_REPORT"

# === Snapshot Processing ===
OLD_SNAPS=""
SNAP_LIST=$($TIMESHIFT_CMD --list | grep -Eo "20[0-9]{2}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}.*")

declare -A SNAP_AGE_MAP
while read -r line; do
    [[ -z "$line" ]] && continue
    SNAP=$(echo "$line" | awk '{print $1}')
    TAG=$(echo "$line" | awk '{print $NF}')
    [[ "$TAG" =~ ^[WMB]$ ]] && continue
    DATE="${SNAP%%_*}"
    TIME="${SNAP##*_}"
    TIME="${TIME//-/:}"
    SNAP_TS=$(date -d "$DATE $TIME" +%s 2>/dev/null)
    [[ -z "$SNAP_TS" ]] && continue
    NOW_TS=$(date +%s)
    AGE=$(( (NOW_TS - SNAP_TS) / 86400 ))
    SNAP_AGE_MAP["$SNAP"]=$AGE
    if (( AGE >= DELETE_DAYS )); then
        OLD_SNAPS+="$SNAP"$'\n'
    fi
done <<< "$SNAP_LIST"

# Deletion
if [[ -z "$OLD_SNAPS" ]]; then
    echo -e "================================================================== \n" >> "$RAW_REPORT"
    echo -e "==========  No snapshots older than $DELETE_DAYS day(s) to Delete ======= \n"  >> "$RAW_REPORT"
    echo -e "================================================================== \n" >> "$RAW_REPORT"
else
    echo "----- Snapshots Scheduled for Deletion -----" >> "$RAW_REPORT"
    echo "$OLD_SNAPS" >> "$RAW_REPORT"
    echo "" >> "$RAW_REPORT"

    if [[ $DRYRUN -eq 1 ]]; then
        echo "DRY-RUN: No deletions performed." >> "$RAW_REPORT"
    else
        echo "Deleting snapshots..." >> "$RAW_REPORT"
        while read -r snap; do
            [[ -z "$snap" ]] && continue
            sleep 2
            sudo $TIMESHIFT_CMD --delete --snapshot "$snap"  >> "$RAW_REPORT" 2>&1
        done <<< "$OLD_SNAPS"
    fi
fi

# Snapshots AFTER
echo "" >> "$RAW_REPORT"
echo "----- Timeshift Snapshots AFTER Cleanup -----" >> "$RAW_REPORT"
$TIMESHIFT_CMD --list >> "$RAW_REPORT" 2>&1
echo "" >> "$RAW_REPORT"

# Disk AFTER
echo "----- Disk Usage AFTER Cleanup -----" >> "$RAW_REPORT"
df -h >> "$RAW_REPORT"
echo "" >> "$RAW_REPORT"

# Systemd timers
NEWTIMERS=$(systemctl list-timers --all --no-legend | grep new_timeshift || true)
CINNAMON_TIMERS=$(systemctl list-timers --all --no-legend | grep -E "cinnamon|timeshift|linux_hardware_report.timer" || true)

echo "----- System D Timers  -----" >> "$RAW_REPORT"  2>&1
echo "$CINNAMON_TIMERS" >> "$RAW_REPORT" 2>&1
echo "" >> "$RAW_REPORT"


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
read -r DFPCT DFFREE < <(df -h / --output=pcent,avail | tail -1)
NUMUSED=$(echo "$DFPCT" | tr -d '%')
NUMFREE=$((100 - NUMUSED))
ROOT_FS=$(df -h / | tail -1)

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
echo "<h2 style='background:#4a90e2; color:white; padding:15px; border-radius:8px; text-align:center;'>Timeshift Cleanup Report</h2>"

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

# Disk BEFORE/AFTER
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Disk Usage</h3>"
echo "<table style='width:100%; border-collapse:collapse; margin-bottom:20px;'>"
echo "<tr><th style='padding:10px; border:1px solid #ccc;'>Used %</th><td style='padding:10px; border:1px solid #ccc; color:$USED_COLOR;'>$NUMUSED%</td></tr>"
echo "<tr><th style='padding:10px; border:1px solid #ccc;'>Free %</th><td style='padding:10px; border:1px solid #ccc; color:$FREE_COLOR;'>$NUMFREE%</td></tr>"
echo "<tr><th style='padding:10px; border:1px solid #ccc;'>Root FS</th><td style='padding:10px; border:1px solid #ccc;'>$ROOT_FS</td></tr>"
echo "</table>"

# Cleanup log
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Cleanup Log</h3>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>"
while IFS= read -r line; do
    colorize_line "$line"
done < "$RAW_REPORT"
echo "</div>"

# Timeshift Snapshots (plain text)
SNAPSHOT_RAW=$($TIMESHIFT_CMD --list 2>/dev/null || true)
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Timeshift Snapshots</h3>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>"
echo "$SNAPSHOT_RAW"
echo "</div>"

# Systemd timers
echo "<h3 style='background:#eee; padding:10px; border-left:5px solid #4a90e2;'>Systemd Timers</h3>"
# echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>$NEWTIMERS</div>"
echo "<div style='background:#fafafa; border:1px solid #ddd; padding:10px; border-radius:6px; font-family:monospace; white-space:pre-wrap;'>$CINNAMON_TIMERS</div>"

echo "<div style='text-align:center; font-size:12px; color:#777; margin-top:20px;'>Report generated automatically by Timeshift Cleanup Script — $(hostname)</div>"

echo "</div></body></html>"
} > "$HTML_REPORT"

# === SEND EMAIL WITH ATTACHMENT ===
if command -v msmtp >/dev/null 2>&1; then
{
    echo "To: $EMAIL"
    echo "Subject: $SUBJECT"
    echo "MIME-Version: 1.0"
    echo "Content-Type: multipart/mixed; boundary=\"BOUNDARY\""
    echo
    echo "--BOUNDARY"
    echo "Content-Type: text/html; charset=UTF-8"
    echo
    cat "$HTML_REPORT"
    echo "--BOUNDARY"
    echo "Content-Type: text/plain; name=\"timeshift_cleanup_raw.txt\""
    echo "Content-Disposition: attachment; filename=\"timeshift_cleanup_raw.txt\""
    echo
    cat "$RAW_REPORT"
    echo "--BOUNDARY--"
} | msmtp "$EMAIL" || echo "WARNING: Mail send failed"
else
    echo "msmtp not found. Raw report saved at $RAW_REPORT"
fi

rm -f "$RAW_REPORT"

