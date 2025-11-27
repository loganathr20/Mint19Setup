#!/bin/bash
# Timeshift Cleanup Script (Fixed Version)
# Deletes "O" snapshots older than 1 day (24 hours), preserves W/M/B
# Sends detailed email report

EMAIL="loganathr20@gmail.com"
SUBJECT="Timeshift Cleanup Report - $(date '+%Y-%m-%d %H:%M:%S')"
TMPFILE="/tmp/timeshift_cleanup_report.txt"
TIMESHIFT_CMD="/usr/bin/timeshift"
DELETE_DAYS=1
DRYRUN=0

# Check dry-run/test mode
if [[ "$1" == "test" ]]; then
    DRYRUN=1
fi

# Start log
echo "===== Timeshift Cleanup Report =====" > "$TMPFILE"
echo "Report generated at: $(date)" >> "$TMPFILE"
echo "" >> "$TMPFILE"

# Disk usage BEFORE cleanup
echo "----- Current Disk Usage BEFORE Cleanup -----" >> "$TMPFILE"
df -h >> "$TMPFILE"
echo "" >> "$TMPFILE"

# Snapshots BEFORE cleanup
echo "----- Timeshift Snapshots BEFORE Cleanup -----" >> "$TMPFILE"
$TIMESHIFT_CMD --list >> "$TMPFILE" 2>&1
echo "" >> "$TMPFILE"

# Process snapshots
OLD_SNAPS=""

# Get only snapshot lines with date pattern
SNAP_LIST=$($TIMESHIFT_CMD --list | grep -E "20[0-9]{2}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}")

while read -r line; do
    # Extract snapshot name
    SNAP=$(echo "$line" | grep -oE "20[0-9]{2}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}")
    # Extract tag (last word)
    TAG=$(echo "$line" | awk '{print $NF}')

    # Skip weekly/monthly snapshots
    [[ "$TAG" =~ [WM] ]] && continue

    # Convert snapshot to epoch
    DATE_PART="${SNAP%%_*}"      # before _
    TIME_PART="${SNAP##*_}"      # after _
    TIME_PART="${TIME_PART//-/:}" # 15-27-54 → 15:27:54
    SNAP_TS=$(date -d "$DATE_PART $TIME_PART" +%s 2>/dev/null)
    [ -z "$SNAP_TS" ] && continue

    NOW_TS=$(date +%s)
    DIFF=$(( (NOW_TS - SNAP_TS) / 86400 ))  # days

    if [ "$DIFF" -ge $DELETE_DAYS ]; then
        OLD_SNAPS+="$SNAP"$'\n'
    fi
done <<< "$SNAP_LIST"

# Delete snapshots
if [ -z "$OLD_SNAPS" ]; then
    echo "No snapshots older than $DELETE_DAYS day(s) to delete." >> "$TMPFILE"
else
    echo "----- Snapshots to be deleted -----" >> "$TMPFILE"
    echo "$OLD_SNAPS" >> "$TMPFILE"
    echo "" >> "$TMPFILE"

    if [[ $DRYRUN -eq 1 ]]; then
        echo "Dry-run mode: No snapshots will be deleted." >> "$TMPFILE"
    else
        echo "Deleting snapshots..." >> "$TMPFILE"
        while read -r snap; do
            sudo $TIMESHIFT_CMD --delete --snapshot "$snap" >> "$TMPFILE" 2>&1
        done <<< "$OLD_SNAPS"
    fi
fi

# Snapshots AFTER cleanup
echo "" >> "$TMPFILE"
echo "----- Timeshift Snapshots AFTER Cleanup -----" >> "$TMPFILE"
$TIMESHIFT_CMD --list >> "$TMPFILE" 2>&1
echo "" >> "$TMPFILE"

# Disk usage AFTER cleanup
echo "----- Current Disk Usage AFTER Cleanup -----" >> "$TMPFILE"
df -h >> "$TMPFILE"
echo "" >> "$TMPFILE"

# Send email report
if command -v msmtp >/dev/null 2>&1; then
    {
        echo "Subject: $SUBJECT"
        echo "To: $EMAIL"
        cat "$TMPFILE"
    } | msmtp "$EMAIL"
else
    echo "No mail client found. Report saved at $TMPFILE"
fi

# Cleanup temp file
rm -f "$TMPFILE"

