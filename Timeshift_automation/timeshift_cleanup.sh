#!/bin/bash

# -------------------------------
# Timeshift Cleanup Script
# Works interactively or automatically via cron
# -------------------------------

# Email recipient
EMAIL="loganathr20@gmail.com"

# -------------------------------
# Determine DAYS_THRESHOLD
# -------------------------------
if [ -t 0 ]; then
    # Interactive terminal
    read -p "Enter number of days to keep snapshots (default 2): " DAYS_THRESHOLD
    DAYS_THRESHOLD=${DAYS_THRESHOLD:-2}
else
    # Non-interactive (cron)
    DAYS_THRESHOLD=2
fi

echo "Snapshots older than $DAYS_THRESHOLD days (except monthly) will be deleted."

# -------------------------------
# Log file
# -------------------------------
LOG_FILE="/tmp/timeshift_cleanup_$(date +%Y%m%d_%H%M%S).log"

# Start log
echo "Timeshift Cleanup Report - $(date)" > "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"

# List all snapshots
echo "Current Timeshift snapshots:" >> "$LOG_FILE"
timeshift --list >> "$LOG_FILE" 2>&1
echo "----------------------------------------" >> "$LOG_FILE"

# -------------------------------
# Cleanup snapshots older than DAYS_THRESHOLD (except monthly)
# -------------------------------
echo "Cleaning up snapshots older than $DAYS_THRESHOLD days (except monthly)..." >> "$LOG_FILE"

# Get list of snapshots
snapshots=$(timeshift --list | grep '^  ' | awk '{print $2}')

for snap in $snapshots; do
    # Extract snapshot type from name
    type=$(echo "$snap" | cut -d'-' -f1)
    
    # Skip monthly snapshots
    if [[ "$type" == "Monthly" ]]; then
        echo "Skipping monthly snapshot: $snap" >> "$LOG_FILE"
        continue
    fi

    # Extract snapshot date
    snap_date=$(echo "$snap" | grep -oP '\d{4}-\d{2}-\d{2}')
    
    if [[ -n "$snap_date" ]]; then
        snap_ts=$(date -d "$snap_date" +%s)
        now_ts=$(date +%s)
        diff_days=$(( (now_ts - snap_ts) / 86400 ))
        
        if [[ $diff_days -gt $DAYS_THRESHOLD ]]; then
            echo "Deleting snapshot: $snap" >> "$LOG_FILE"
            timeshift --delete --snapshot "$snap" --yes >> "$LOG_FILE" 2>&1
        fi
    fi
done

echo "----------------------------------------" >> "$LOG_FILE"
echo "Timeshift snapshots after cleanup:" >> "$LOG_FILE"
timeshift --list >> "$LOG_FILE" 2>&1

# -------------------------------
# Send report via email
# -------------------------------
if command -v msmtp &>/dev/null; then
    cat "$LOG_FILE" | msmtp "$EMAIL"
elif command -v mail &>/dev/null; then
    cat "$LOG_FILE" | mail -s "Timeshift Cleanup Report $(date)" "$EMAIL"
else
    echo "No email client found. Please install msmtp or mail."
fi

echo "Cleanup completed."

