#!/usr/bin/env bash
# New_timeshift-job-v2.sh
# Usage: New_timeshift-job-v2.sh Boottime|Other
# Timeshift snapshot + cleanup + email

set -e

LOG_EMAIL="loganathr20@gmail.com"
SCRIPTNAME="$(basename "$0")"
MODE="${1:-Other}"   # default to Other
KEEP_DAYS=2
NOW_EPOCH=$(date +%s)
TMPDIR=$(mktemp -d /tmp/new_timeshift.XXXX)
REPORT_SNAP="$TMPDIR/report_snapshot.txt"
REPORT_CLEAN="$TMPDIR/report_cleanup.txt"
TIMESHIFT_BIN="/usr/bin/timeshift"
MAIL_CMD="/usr/bin/msmtp"
LOCKFILE="/tmp/New_timeshift-job.lock"
BACKUP_PART="/"

# === Prevent overlapping runs ===
if [ -f "$LOCKFILE" ]; then
    echo "Another Timeshift job is running, exiting."
    exit 1
fi
trap 'rm -f "$LOCKFILE"' EXIT
touch "$LOCKFILE"

# === Mode mapping ===
if [[ "$MODE" == "Boottime" ]]; then
    TAG="B"
    COMMENT="Auto Boot Snapshot"
elif [[ "$MODE" == "Other" ]]; then
    TAG="O"
    COMMENT="Auto Other Snapshot (10h)"
else
    TAG="O"
    COMMENT="Auto Snapshot"
fi

# === 1) Create snapshot ===
echo "== Creating Timeshift snapshot (tag=$TAG) ==" > "$REPORT_SNAP"
echo "Started: $(date -R)" >> "$REPORT_SNAP"
$TIMESHIFT_BIN --create --comments "$COMMENT" --tags "$TAG" --scripted >> "$REPORT_SNAP" 2>&1 || echo "ERROR: timeshift create failed" >> "$REPORT_SNAP"

# === Diagnostics ===
echo >> "$REPORT_SNAP"
echo "== Host / Date ==" >> "$REPORT_SNAP"
echo "Host: $(hostname)" >> "$REPORT_SNAP"
echo "Date: $(date -R)" >> "$REPORT_SNAP"

# Disk usage
echo >> "$REPORT_SNAP"
echo "== Disk usage for $BACKUP_PART ==" >> "$REPORT_SNAP"
DFLINE=$(df -h "$BACKUP_PART" | tail -1)
DFPCT=$(echo "$DFLINE" | awk '{print $5}')
NUMUSED=$(echo "$DFPCT" | tr -d '%')
NUMFREE=$((100 - NUMUSED))
echo "$DFLINE" >> "$REPORT_SNAP"
echo "UsedPercent: ${NUMUSED}%  FreePercent: ${NUMFREE}%" >> "$REPORT_SNAP"
if (( NUMFREE < 10 )); then
    echo "" >> "$REPORT_SNAP"
    echo "WARNING: Free space < 10% (Free: ${NUMFREE}%)." >> "$REPORT_SNAP"
fi

# Timeshift list
echo >> "$REPORT_SNAP"
echo "== Timeshift snapshot list ==" >> "$REPORT_SNAP"
$TIMESHIFT_BIN --list 2>&1 >> "$REPORT_SNAP" || echo "Failed to get Timeshift list" >> "$REPORT_SNAP"

# Systemd timers
echo >> "$REPORT_SNAP"
echo "== Systemd timers ==" >> "$REPORT_SNAP"
systemctl list-timers --all --no-legend | grep New_timeshift || true

# Timeshift log tail
echo >> "$REPORT_SNAP"
echo "== Timeshift logs (tail 200 lines) ==" >> "$REPORT_SNAP"
if [ -f /var/log/timeshift/timeshift.log ]; then
    tail -n 200 /var/log/timeshift/timeshift.log >> "$REPORT_SNAP" 2>/dev/null
else
    journalctl -u timeshift --no-pager -n 200 >> "$REPORT_SNAP" 2>/dev/null
fi

# Send snapshot report email
SUBJ1="[$(hostname)] Timeshift_report_snapshot mode=$MODE - $(date '+%Y-%m-%d %H:%M:%S')"
/bin/cat "$REPORT_SNAP" | $MAIL_CMD -t "$LOG_EMAIL" -s "$SUBJ1" || echo "Warning: mail send failed (snapshot report)"

# === 2) Cleanup old Other/Hourly snapshots ===
echo "== Cleanup started: removing Other/Hourly older than ${KEEP_DAYS} days ==" > "$REPORT_CLEAN"
echo "Started: $(date -R)" >> "$REPORT_CLEAN"

$TIMESHIFT_BIN --list | sed -n 's/^[[:space:]]*\([0-9]\+\)[[:space:]]\+\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9:.-]\+\)[[:space:]]\+\([A-Z]\).*/\1 \2 \3/p' > "$TMPDIR/_snapshots_raw" || true

while read -r ID NAME TAGFOUND; do
    [[ "$TAGFOUND" != "O" && "$TAGFOUND" != "H" ]] && continue
    SNAP_DATE_STR="${NAME/_/ }"
    SNAP_DATE_STR=$(echo "$SNAP_DATE_STR" | sed 's/-/:/g')
    SNAP_EPOCH=$(date -d "$SNAP_DATE_STR" +%s 2>/dev/null || echo 0)
    (( SNAP_EPOCH == 0 )) && echo "Could not parse date for snapshot '$NAME', skipping" >> "$REPORT_CLEAN" && continue
    AGE_SEC=$(( NOW_EPOCH - SNAP_EPOCH ))
    AGE_DAYS=$(( AGE_SEC / 86400 ))
    if (( AGE_DAYS >= KEEP_DAYS )); then
        echo "Deleting snapshot: id=$ID name=$NAME tag=$TAGFOUND age=${AGE_DAYS}d" >> "$REPORT_CLEAN"
        $TIMESHIFT_BIN --delete --snapshot "$NAME" >> "$REPORT_CLEAN" 2>&1 || echo "Failed to delete $NAME" >> "$REPORT_CLEAN"
    else
        echo "Keeping snapshot: id=$ID name=$NAME tag=$TAGFOUND age=${AGE_DAYS}d" >> "$REPORT_CLEAN"
    fi
done < "$TMPDIR/_snapshots_raw"

echo >> "$REPORT_CLEAN"
echo "== Timeshift list (after cleanup) ==" >> "$REPORT_CLEAN"
$TIMESHIFT_BIN --list 2>&1 >> "$REPORT_CLEAN"

echo >> "$REPORT_CLEAN"
echo "== Disk usage snapshot (after cleanup) ==" >> "$REPORT_CLEAN"
df -h "$BACKUP_PART" | tail -1 >> "$REPORT_CLEAN"

# Send cleanup report email
SUBJ2="[$(hostname)] Timeshift_report_cleanup mode=$MODE - $(date '+%Y-%m-%d %H:%M:%S')"
/bin/cat "$REPORT_CLEAN" | $MAIL_CMD -t "$LOG_EMAIL" -s "$SUBJ2" || echo "Warning: mail send failed (cleanup report)"

# Cleanup temp
rm -rf "$TMPDIR"
rm -f "$LOCKFILE"
exit 0

