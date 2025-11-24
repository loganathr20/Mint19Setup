#!/usr/bin/env bash
# New_timeshift-job.sh
# Usage: New_timeshift-job.sh boot|other
# Runs timeshift snapshot, waits if another instance is running,
# performs cleanup, and emails reports with proper subjects.

set -euo pipefail
LOG_EMAIL="loganathr20@gmail.com"
SCRIPTNAME="$(basename "$0")"
INPUT_MODE="${1:-other}"   # user input: boot|other

# Map input to friendly mode names for subjects
if [[ "$INPUT_MODE" == "boot" ]]; then
    MODE="Boottime"
elif [[ "$INPUT_MODE" == "other" ]]; then
    MODE="Other"
else
    MODE="Other"
fi

KEEP_DAYS=2
NOW_EPOCH=$(date +%s)
TMPDIR=$(mktemp -d /tmp/new_timeshift.XXXX)
REPORT1="$TMPDIR/report_snapshot.txt"
REPORT2="$TMPDIR/report_cleanup.txt"
TIMESHIFT_BIN="/usr/bin/timeshift"

# Map MODE to Timeshift tag/comment
if [[ "$MODE" == "Boottime" ]]; then
    TAG="B"
    COMMENT="Auto Boot Snapshot"
else
    TAG="O"
    COMMENT="Auto Other Snapshot (10h)"
fi

# Determine mail command
MAIL_CMD=$(command -v msmtp || command -v mail)

# -------------------------------
# 1) Create snapshot
# -------------------------------
echo "== Creating Timeshift snapshot (tag=$TAG) ==" > "$REPORT1"
echo "Started: $(date -R)" >> "$REPORT1"
if ! $TIMESHIFT_BIN --create --comments "$COMMENT" --tags "$TAG" --scripted >> "$REPORT1" 2>&1; then
    echo "ERROR: timeshift create failed" >> "$REPORT1"
fi
echo >> "$REPORT1"

# -------------------------------
# 2) Collect diagnostics
# -------------------------------
echo "== Host / Date ==" >> "$REPORT1"
echo "Host: $(hostname)" >> "$REPORT1"
echo "Date: $(date -R)" >> "$REPORT1"
echo >> "$REPORT1"

echo "== Disk usage for / ==" >> "$REPORT1"
DFLINE=$(df -h / | tail -1)
DFPCT=$(echo "$DFLINE" | awk '{print $5}')
DFFREE=$(echo "$DFLINE" | awk '{print $4}')
echo "Root: $DFLINE" >> "$REPORT1"
NUMUSED=$(echo "$DFPCT" | tr -d '%')
NUMFREE=$((100 - NUMUSED))
echo "UsedPercent: ${NUMUSED}%  FreePercent: ${NUMFREE}%" >> "$REPORT1"
if (( NUMFREE < 10 )); then
    echo "" >> "$REPORT1"
    echo "WARNING: Free space < 10% on root (Free: ${NUMFREE}%). Consider cleaning snapshots or increasing backup disk." >> "$REPORT1"
fi
echo >> "$REPORT1"

echo "== Timeshift snapshot list ==" >> "$REPORT1"
$TIMESHIFT_BIN --list 2>&1 >> "$REPORT1" || true
echo >> "$REPORT1"

echo "== Systemd timers (next runs) ==" >> "$REPORT1"
systemctl list-timers --all --no-legend | grep New_timeshift || true
echo >> "$REPORT1"

echo "== Timeshift logs (tail 200 lines) ==" >> "$REPORT1"
if [ -f /var/log/timeshift/timeshift.log ]; then
    tail -n 200 /var/log/timeshift/timeshift.log >> "$REPORT1" 2>/dev/null || true
elif ls /var/log/timeshift* >/dev/null 2>&1; then
    tail -n 200 /var/log/timeshift* 2>/dev/null || true
else
    journalctl -u timeshift --no-pager -n 200 >> "$REPORT1" 2>/dev/null || true
fi

# -------------------------------
# 3) Send first email (snapshot report)
# -------------------------------
SUBJ1="[$(hostname)] Timeshift_report_snapshot mode=${MODE} - $(date '+%Y-%m-%d %H:%M:%S')"

if command -v msmtp >/dev/null 2>&1; then
    msmtp --from=default -t "$LOG_EMAIL" <<EOF
Subject: $SUBJ1

$(cat "$REPORT1")
EOF
else
    /bin/mail -s "$SUBJ1" "$LOG_EMAIL" < "$REPORT1" || echo "Warning: mail failed (snapshot report)"
fi

# -------------------------------
# 4) Cleanup: delete Old Other/Hourly snapshots
# Wait for any running timeshift process to finish
# -------------------------------
echo "== Cleanup started: removing Other/Hourly older than ${KEEP_DAYS} days ==" > "$REPORT2"
echo "Started: $(date -R)" >> "$REPORT2"

while pgrep -x timeshift >/dev/null 2>&1; do
    echo "Timeshift process is already running, waiting 10 seconds..." >> "$REPORT2"
    sleep 10
done

$TIMESHIFT_BIN --list | sed -n 's/^[[:space:]]*\([0-9]\+\)[[:space:]]\+\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9:.-]\+\)[[:space:]]\+\([A-Z]\).*/\1 \2 \3/p' > "$TMPDIR/_snapshots_raw" || true
if [ ! -s "$TMPDIR/_snapshots_raw" ]; then
    $TIMESHIFT_BIN --list | awk '{ if ($2 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}_/) print $1, $2, $3 }' > "$TMPDIR/_snapshots_raw" || true
fi

while read -r ID NAME TAGFOUND; do
    if [[ "$TAGFOUND" != "O" && "$TAGFOUND" != "H" ]]; then
        continue
    fi
    SNAP_DATE_STR="${NAME/_/ }"
    SNAP_DATE_STR=$(echo "$SNAP_DATE_STR" | sed 's/-/:/g')
    SNAP_EPOCH=$(date -d "$SNAP_DATE_STR" +%s 2>/dev/null || echo 0)
    if [ "$SNAP_EPOCH" -eq 0 ]; then
        echo "Could not parse date for snapshot '$NAME' (id $ID), skipping" >> "$REPORT2"
        continue
    fi
    AGE_SEC=$(( NOW_EPOCH - SNAP_EPOCH ))
    AGE_DAYS=$(( AGE_SEC / 86400 ))
    if (( AGE_DAYS >= KEEP_DAYS )); then
        echo "Deleting snapshot: id=$ID name=$NAME tag=$TAGFOUND age=${AGE_DAYS}d" >> "$REPORT2"
        if $TIMESHIFT_BIN --delete --snapshot "$NAME" >> "$REPORT2" 2>&1; then
            echo "Deleted OK: $NAME" >> "$REPORT2"
        else
            echo "Failed to delete: $NAME" >> "$REPORT2"
        fi
    else
        echo "Keeping snapshot: id=$ID name=$NAME tag=$TAGFOUND age=${AGE_DAYS}d" >> "$REPORT2"
    fi
done < "$TMPDIR/_snapshots_raw"

echo >> "$REPORT2"
echo "== Timeshift list (after cleanup) ==" >> "$REPORT2"
$TIMESHIFT_BIN --list 2>&1 >> "$REPORT2" || true

echo >> "$REPORT2"
echo "== Disk usage snapshot (after cleanup) ==" >> "$REPORT2"
df -h / | tail -1 >> "$REPORT2"

# -------------------------------
# 5) Send cleanup report
# -------------------------------
SUBJ2="[$(hostname)] Timeshift_report_cleanup mode=${MODE} - $(date '+%Y-%m-%d %H:%M:%S')"

if command -v msmtp >/dev/null 2>&1; then
    msmtp --from=default -t "$LOG_EMAIL" <<EOF
Subject: $SUBJ2

$(cat "$REPORT2")
EOF
else
    /bin/mail -s "$SUBJ2" "$LOG_EMAIL" < "$REPORT2" || echo "Warning: mail failed (cleanup report)"
fi

# -------------------------------
# 6) Housekeeping
# -------------------------------
rm -rf "$TMPDIR"
exit 0


