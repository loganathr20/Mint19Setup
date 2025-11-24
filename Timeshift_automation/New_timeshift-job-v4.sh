#!/usr/bin/env bash
# New_timeshift-job-v4.sh
# Usage: New_timeshift-job-v4.sh Boottime|Other
# Runs timeshift snapshot, cleanup (remove Other/Hourly older than 2 days),
# builds reports and emails them using msmtp

set -euo pipefail

LOG_EMAIL="loganathr20@gmail.com"
SCRIPTNAME="$(basename "$0")"
MODE="${1:-Other}"   # Boottime or Other
KEEP_DAYS=2
NOW_EPOCH=$(date +%s)
TMPDIR=$(mktemp -d /tmp/new_timeshift.XXXX)
REPORT1="$TMPDIR/report_snapshot.txt"
REPORT2="$TMPDIR/report_cleanup.txt"
TIMESHIFT_BIN="/usr/bin/timeshift"
MSMTP_CMD="/usr/bin/msmtp"

# Force msmtp to log to /dev/null to avoid permission errors in systemd
export MSMTP_LOGFILE=/dev/null

# map mode -> tag/comment
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

# Wait for any existing Timeshift instance
while pidof timeshift > /dev/null; do
  echo "Another Timeshift job is running, waiting..."
  sleep 5
done

# 1) Create snapshot
echo "== Creating Timeshift snapshot (tag=$TAG) ==" > "$REPORT1"
echo "Started: $(date -R)" >> "$REPORT1"
if ! $TIMESHIFT_BIN --create --comments "$COMMENT" --tags "$TAG" --scripted >> "$REPORT1" 2>&1; then
  echo "ERROR: timeshift create failed" >> "$REPORT1"
fi
echo >> "$REPORT1"

# 2) Collect diagnostics
echo "== Host / Date ==" >> "$REPORT1"
echo "Host: $(hostname)" >> "$REPORT1"
echo "Date: $(date -R)" >> "$REPORT1"
echo >> "$REPORT1"

echo "== Disk usage for / ==" >> "$REPORT1"
DFLINE=$(df -h / | tail -1)
DFPCT=$(echo "$DFLINE" | awk '{print $5}')
DFFREE=$(echo "$DFLINE" | awk '{print $4}')
NUMUSED=$(echo "$DFPCT" | tr -d '%')
NUMFREE=$((100 - NUMUSED))
echo "Root: $DFLINE" >> "$REPORT1"
echo "UsedPercent: ${NUMUSED}%  FreePercent: ${NUMFREE}%" >> "$REPORT1"
if (( NUMFREE < 10 )); then
  echo "" >> "$REPORT1"
  echo "WARNING: Free space < 10% on root (Free: ${NUMFREE}%)" >> "$REPORT1"
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
else
  journalctl -u timeshift --no-pager -n 200 >> "$REPORT1" 2>/dev/null || true
fi

# 3) Send first email (snapshot report)
SUBJ1="Timeshift_report_snapshot_${MODE} - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "Subject: $SUBJ1"
  echo "To: $LOG_EMAIL"
  echo
  cat "$REPORT1"
} | $MSMTP_CMD "$LOG_EMAIL" || echo "Warning: msmtp failed (snapshot report)"

# 4) Cleanup: delete old Other/Hourly snapshots
echo "== Cleanup started: removing Other/Hourly older than ${KEEP_DAYS} days ==" > "$REPORT2"
echo "Started: $(date -R)" >> "$REPORT2"

$TIMESHIFT_BIN --list | sed -n 's/^[[:space:]]*\([0-9]\+\)[[:space:]]\+\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9:.-]\+\)[[:space:]]\+\([A-Z]\).*/\1 \2 \3/p' > "$TMPDIR/_snapshots_raw" || true
if [ ! -s "$TMPDIR/_snapshots_raw" ]; then
  $TIMESHIFT_BIN --list | awk '{ if ($2 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}_/) print $1, $2, $3 }' > "$TMPDIR/_snapshots_raw" || true
fi

while read -r ID NAME TAGFOUND; do
  [[ "$TAGFOUND" != "O" && "$TAGFOUND" != "H" ]] && continue
  SNAP_DATE_STR="${NAME/_/ }"
  SNAP_DATE_STR=$(echo "$SNAP_DATE_STR" | sed 's/-/:/g')
  SNAP_EPOCH=$(date -d "$SNAP_DATE_STR" +%s 2>/dev/null || echo 0)
  [ "$SNAP_EPOCH" -eq 0 ] && { echo "Could not parse date for snapshot '$NAME'"; continue; }
  AGE_SEC=$(( NOW_EPOCH - SNAP_EPOCH ))
  AGE_DAYS=$(( AGE_SEC / 86400 ))
  if (( AGE_DAYS >= KEEP_DAYS )); then
    echo "Deleting snapshot: id=$ID name=$NAME tag=$TAGFOUND age=${AGE_DAYS}d" >> "$REPORT2"
    $TIMESHIFT_BIN --delete --snapshot "$NAME" >> "$REPORT2" 2>&1 || echo "Failed to delete: $NAME" >> "$REPORT2"
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

# 5) Send cleanup report
SUBJ2="Timeshift_report_cleanup_${MODE} - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "Subject: $SUBJ2"
  echo "To: $LOG_EMAIL"
  echo
  cat "$REPORT2"
} | $MSMTP_CMD "$LOG_EMAIL" || echo "Warning: msmtp failed (cleanup report)"

# 6) Housekeeping
rm -rf "$TMPDIR"
exit 0

