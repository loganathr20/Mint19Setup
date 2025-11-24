#!/bin/bash
# New_timeshift-job-v4.sh
# Usage: New_timeshift-job-v4.sh Boottime|Other
# Runs timeshift snapshot, cleanup, and sends email using msmtp

set -euo pipefail

LOG_EMAIL="loganathr20@gmail.com"
SCRIPTNAME="$(basename "$0")"
MODE="${1:-Other}"   # default to 'Other'
KEEP_DAYS=2
NOW_EPOCH=$(date +%s)
TMPDIR=$(mktemp -d /tmp/new_timeshift.XXXX)
REPORT1="$TMPDIR/report_snapshot.txt"
REPORT2="$TMPDIR/report_cleanup.txt"
TIMESHIFT_BIN="/usr/bin/timeshift"

# map mode -> tag/comment
if [[ "$MODE" == "Boottime" ]]; then
  TAG="B"
  COMMENT="Auto Boottime Snapshot"
elif [[ "$MODE" == "Other" ]]; then
  TAG="O"
  COMMENT="Auto Other Snapshot (10h)"
else
  TAG="O"
  COMMENT="Auto Snapshot"
fi

# 1) Wait if another timeshift is running
while pidof timeshift >/dev/null; do
  echo "Another Timeshift job is running, waiting 5s..."
  sleep 5
done

# 2) Create snapshot
echo "== Creating Timeshift snapshot (tag=$TAG) ==" > "$REPORT1"
echo "Started: $(date -R)" >> "$REPORT1"

if ! $TIMESHIFT_BIN --create --comments "$COMMENT" --tags "$TAG" --scripted >> "$REPORT1" 2>&1; then
  echo "ERROR: timeshift create failed" >> "$REPORT1"
fi

# 3) Collect diagnostics
echo >> "$REPORT1"
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
  echo "WARNING: Free space < 10% on root (Free: ${NUMFREE}%)." >> "$REPORT1"
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

# 4) Send first email (snapshot completion report)
SUBJ1="[$(hostname)] Timeshift_report_snapshot mode=$MODE - $(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "Subject: $SUBJ1"
  echo "To: $LOG_EMAIL"
  echo "From: $LOG_EMAIL"
  echo
  cat "$REPORT1"
} | /usr/bin/msmtp "$LOG_EMAIL" || echo "Warning: msmtp failed (snapshot report)"

# 5) Cleanup: delete Other/Hourly older than KEEP_DAYS
echo "== Cleanup started: removing Other/Hourly older than ${KEEP_DAYS} days ==" > "$REPORT2"
echo "Started: $(date -R)" >> "$REPORT2"

$TIMESHIFT_BIN --list | sed -n 's/^[[:space:]]*\([0-9]\+\)[[:space:]]\+\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9:.-]\+\)[[:space:]]\+\([A-Z]\).*/\1 \2 \3/p' > "$TMPDIR/_snapshots_raw" || true

while read -r ID NAME TAGFOUND; do
  if [[ "$TAGFOUND" != "O" && "$TAGFOUND" != "H" ]]; then
    continue
  fi
  SNAP_DATE_STR="${NAME/_/ }"
  SNAP_DATE_STR=$(echo "$SNAP_DATE_STR" | sed 's/-/:/g')
  SNAP_EPOCH=$(date -d "$SNAP_DATE_STR" +%s 2>/dev/null || echo 0)
  if [ "$SNAP_EPOCH" -eq 0 ]; then
    echo "Could not parse date for snapshot '$NAME', skipping" >> "$REPORT2"
    continue
  fi
  AGE_SEC=$(( NOW_EPOCH - SNAP_EPOCH ))
  AGE_DAYS=$(( AGE_SEC / 86400 ))
  if (( AGE_DAYS >= KEEP_DAYS )); then
    echo "Deleting snapshot: $NAME tag=$TAGFOUND age=${AGE_DAYS}d" >> "$REPORT2"
    $TIMESHIFT_BIN --delete --snapshot "$NAME" >> "$REPORT2" 2>&1 || echo "Failed to delete $NAME" >> "$REPORT2"
  else
    echo "Keeping snapshot: $NAME tag=$TAGFOUND age=${AGE_DAYS}d" >> "$REPORT2"
  fi
done < "$TMPDIR/_snapshots_raw"

echo >> "$REPORT2"
echo "== Timeshift list (after cleanup) ==" >> "$REPORT2"
$TIMESHIFT_BIN --list 2>&1 >> "$REPORT2" || true
echo >> "$REPORT2"
echo "== Disk usage snapshot (after cleanup) ==" >> "$REPORT2"
df -h / | tail -1 >> "$REPORT2"

# 6) Send cleanup report email
SUBJ2="[$(hostname)] Timeshift_report_cleanup mode=$MODE - $(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "Subject: $SUBJ2"
  echo "To: $LOG_EMAIL"
  echo "From: $LOG_EMAIL"
  echo
  cat "$REPORT2"
} | /usr/bin/msmtp "$LOG_EMAIL" || echo "Warning: msmtp failed (cleanup report)"

# 7) Housekeeping
rm -rf "$TMPDIR"
exit 0

