#!/bin/bash
# Timeshift Cleanup Script - Stable Version
# Deletes "O" snapshots older than 1 day (24 hours)
# Keeps W (weekly) / M (monthly) / B (boot)
# Sends full email report

EMAIL="loganathr20@gmail.com"
SUBJECT="Timeshift Cleanup Report - $(date '+%Y-%m-%d %H:%M')"
TMPFILE="/tmp/timeshift_cleanup_report.txt"
TIMESHIFT_CMD="/usr/bin/timeshift"
DELETE_DAYS=1
DRYRUN=0

# Test mode
if [[ "$1" == "test" ]]; then
    DRYRUN=1
fi

# Start log
echo "===== Timeshift Cleanup Report =====" > "$TMPFILE"
echo "Generated at: $(date)" >> "$TMPFILE"
echo "" >> "$TMPFILE"

# Disk usage BEFORE
echo "----- Disk Usage BEFORE Cleanup -----" >> "$TMPFILE"
df -h >> "$TMPFILE"
echo "" >> "$TMPFILE"

# Snapshots BEFORE
echo "----- Timeshift Snapshots BEFORE Cleanup -----" >> "$TMPFILE"
$TIMESHIFT_CMD --list >> "$TMPFILE" 2>&1
echo "" >> "$TMPFILE"

# Snapshot processing
OLD_SNAPS=""

SNAP_LIST=$($TIMESHIFT_CMD --list | grep -Eo "20[0-9]{2}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}.*")

while read -r line; do
    [[ -z "$line" ]] && continue

    SNAP=$(echo "$line" | awk '{print $1}')
    TAG=$(echo "$line" | awk '{print $NF}')

    # Skip weekly/monthly/boot snapshots
    [[ "$TAG" =~ ^[WMB]$ ]] && continue

    # Convert to epoch
    DATE="${SNAP%%_*}"
    TIME="${SNAP##*_}"
    TIME="${TIME//-/:}"  # convert

    SNAP_TS=$(date -d "$DATE $TIME" +%s 2>/dev/null)
    [[ -z "$SNAP_TS" ]] && continue

    NOW_TS=$(date +%s)
    AGE=$(( (NOW_TS - SNAP_TS) / 86400 ))

    if (( AGE >= DELETE_DAYS )); then
        OLD_SNAPS+="$SNAP"$'\n'
    fi
done <<< "$SNAP_LIST"

# Deletion section
if [[ -z "$OLD_SNAPS" ]]; then
    echo "No old snapshots older than $DELETE_DAYS day(s)." >> "$TMPFILE"
else
    echo "----- Snapshots Scheduled for Deletion -----" >> "$TMPFILE"
    echo "$OLD_SNAPS" >> "$TMPFILE"
    echo "" >> "$TMPFILE"

    if [[ $DRYRUN -eq 1 ]]; then
        echo "DRY-RUN: No deletions performed." >> "$TMPFILE"
    else
        echo "Deleting snapshots..." >> "$TMPFILE"
        while read -r snap; do
            [[ -z "$snap" ]] && continue
            sleep 2  # safety
            sudo $TIMESHIFT_CMD --delete --snapshot "$snap" --tag O >> "$TMPFILE" 2>&1
        done <<< "$OLD_SNAPS"
    fi
fi

# Snapshots AFTER
echo "" >> "$TMPFILE"
echo "----- Timeshift Snapshots AFTER Cleanup -----" >> "$TMPFILE"
$TIMESHIFT_CMD --list >> "$TMPFILE" 2>&1
echo "" >> "$TMPFILE"

# Disk usage AFTER
echo "----- Disk Usage AFTER Cleanup -----" >> "$TMPFILE"
df -h >> "$TMPFILE"
echo "" >> "$TMPFILE"

# Email report using msmtp
if command -v msmtp >/dev/null 2>&1; then
    {
        echo "From: $EMAIL"
        echo "To: $EMAIL"
        echo "Subject: $SUBJECT"
        echo ""
        cat "$TMPFILE"
    } | msmtp --read-envelope-from --read-recipients
else
    echo "msmtp not found. Report saved to $TMPFILE"
fi

rm -f "$TMPFILE"


