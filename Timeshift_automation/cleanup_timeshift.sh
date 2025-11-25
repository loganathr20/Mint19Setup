#!/bin/bash

# Timeshift Cleanup Script with Email Report
# Deletes snapshots older than 2 days, keeps W/M snapshots
# Sends email report via msmtp including snapshot list before and after cleanup

EMAIL="loganathr20@gmail.com"
DATE_STR=$(date '+%Y-%m-%d %H:%M')
SUBJECT="Timeshift Cleanup Report - $DATE_STR"

# Temporary log file
LOGFILE=$(mktemp /tmp/timeshift_cleanup_log.XXXXXX)

cutoff=$(date +%s --date="2 days ago")

{
    echo "Timeshift Cleanup Report"
    echo "======================="
    echo "Date: $DATE_STR"
    echo "Cutoff: $(date -d "@$cutoff")"
    echo
    echo "Snapshots BEFORE cleanup:"
    echo "-------------------------"
    timeshift --list --scripted
    echo
    echo "Deleted Snapshots:"
    echo "-----------------"

    timeshift --list --scripted | while read -r line; do
        if [[ "$line" =~ ^[0-9]+[[:space:]]+\>[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2})[[:space:]]+([A-Z]) ]]; then
            date_str="${BASH_REMATCH[1]}"
            tag="${BASH_REMATCH[2]}"

            # Skip weekly/monthly
            [[ "$tag" == "W" || "$tag" == "M" ]] && continue

            formatted_date="${date_str/_/ }"
            formatted_date="${formatted_date:0:10} ${formatted_date:11:2}:${formatted_date:14:2}:${formatted_date:17:2}"
            snap_epoch=$(date -d "$formatted_date" +%s 2>/dev/null)
            [[ -z "$snap_epoch" ]] && continue

            if (( snap_epoch < cutoff )); then
                snap_name="$date_str"  # timestamp used for deletion
                echo "Deleting snapshot: $snap_name (Tag: $tag, Date: $date_str)"
                timeshift --delete --snapshot "$snap_name" --scripted
            fi
        fi
    done

    echo
    echo "Snapshots AFTER cleanup:"
    echo "------------------------"
    timeshift --list --scripted
    echo
    echo "Timeshift cleanup finished at $(date)."

} > "$LOGFILE" 2>&1

# Send email using msmtp (subject included in message)
{
    echo "To: $EMAIL"
    echo "Subject: $SUBJECT"
    echo
    cat "$LOGFILE"
} | msmtp -a default "$EMAIL"

# Remove temporary log
rm -f "$LOGFILE"


