#!/bin/bash
# Timeshift Cleanup Script (Time-aware)
# Deletes O snapshots older than 1 day (24 hours), preserves W/M/B
# Supports dry-run mode ("test") and sends email report

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

echo "===== Timeshift Cleanup Report =====" > "$TMPFILE"
echo "Report generated at: $(date)" >> "$TMPFILE"
echo "" >> "$TMPFILE"

# Disk usage
echo "----- Current Disk Usage -----" >> "$TMPFILE"
df -h >> "$TMPFILE"
echo "" >> "$TMPFILE"

# Snapshots BEFORE cleanup
echo "----- Timeshift Snapshots BEFORE Cleanup -----" >> "$TMPFILE"
$TIMESHIFT_CMD --list | tee -a "$TMPFILE" > /dev/null
echo "" >> "$TMPFILE"

# Find snapshots older than DELETE_DAYS (skip W/M)
OLD_SNAPS=""

while read -r line; do
    # Only parse lines starting with number (Num)
    if [[ $line =~ ^[0-9]+ ]]; then
        NAME=$(echo "$line" | awk '{print $2}' | tr -d '>')
        TAG=$(echo "$line" | awk '{print $3}')

        # Skip weekly/monthly snapshots
        [[ "$TAG" =~ [WM] ]] && continue

        # Extract full timestamp YYYY-MM-DD_HH-MM-SS
        SNAP_DATETIME=${NAME:0:19}  # First 19 chars
        SNAP_TS=$(date -d "$SNAP_DATETIME" +%s 2>/dev/null)
        [ -z "$SNAP_TS" ] && continue

        NOW_TS=$(date +%s)
        DIFF=$(( (NOW_TS - SNAP_TS) / 86400 ))  # Difference in days (24h)

        if [ "$DIFF" -ge $DELETE_DAYS ]; then
            OLD_SNAPS+="$NAME"$'\n'
        fi
    fi
done < <($TIMESHIFT_CMD --list)

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
$TIMESHIFT_CMD --list | tee -a "$TMPFILE" > /dev/null
echo "" >> "$TMPFILE"

# Send email
if command -v msmtp >/dev/null 2>&1; then
    {
        echo "Subject: $SUBJECT"
        cat "$TMPFILE"
    } | msmtp "$EMAIL"
else
    echo "No mail client found. Report saved at $TMPFILE"
fi

rm -f "$TMPFILE"

