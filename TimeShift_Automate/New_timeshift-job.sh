#!/usr/bin/env bash
# New_timeshift-job.sh 
# Robust Timeshift snapshot script with retries, inline email report, and concurrency check.

set -euo pipefail

LOG_EMAIL="loganathr20@gmail.com"
MODE="${1:-Other}"   # Default to Other if not specified
TIMESHIFT_BIN="/usr/bin/timeshift"
TMPDIR=$(mktemp -d /tmp/new_timeshift.XXXX)
REPORT="$TMPDIR/report_${MODE}.txt"
RETRIES=2
SLEEP_BETWEEN=10          # Retry interval on failure
WAIT_IF_RUNNING=15        # Seconds to wait if another timeshift process is running

# Cleanup temp dir on exit
trap 'rm -rf "$TMPDIR"' EXIT

# Map mode -> tag/comment
if [[ "$MODE" == "Boottime" ]]; then
    TAG="B"
    COMMENT="Auto Boot Snapshot "
else
    TAG="O"
    COMMENT="Auto 6 Hour Snapshot "
fi

echo "== Timeshift snapshot (tag=$TAG) ==" > "$REPORT"
echo "Started: $(date -R)" >> "$REPORT"

# Wait if another timeshift process is running
while pgrep -x timeshift >/dev/null; do
    echo "Another timeshift process is running. Waiting $WAIT_IF_RUNNING seconds..." >> "$REPORT"
    sleep "$WAIT_IF_RUNNING"
done

# Create snapshot with retry
SUCCESS=0
for attempt in $(seq 1 $((RETRIES + 1))); do
    if "$TIMESHIFT_BIN" --create --tags "$TAG" --comments "$COMMENT" --scripted >> "$REPORT" 2>&1; then
        SUCCESS=1
        echo "Snapshot succeeded on attempt $attempt" >> "$REPORT"
        break
    else
        echo "WARNING: timeshift create failed on attempt $attempt" >> "$REPORT"
        if (( attempt <= RETRIES )); then
            echo "Retrying in $SLEEP_BETWEEN seconds..." >> "$REPORT"
            sleep "$SLEEP_BETWEEN"
        fi
    fi
done

if (( SUCCESS == 0 )); then
    echo "ERROR: Timeshift snapshot failed after $((RETRIES + 1)) attempts" >> "$REPORT"
fi

# Host and date info
echo >> "$REPORT"
echo "== Host / Date ==" >> "$REPORT"
echo "Host: $(hostname)" >> "$REPORT"
echo "Date: $(date -R)" >> "$REPORT"

# Disk usage
read -r DFPCT DFFREE < <(df -h / --output=pcent,avail | tail -1)
NUMUSED=$(echo "$DFPCT" | tr -d '%')
NUMFREE=$((100 - NUMUSED))
echo "Root: $(df -h / | tail -1)" >> "$REPORT"
echo "UsedPercent: ${NUMUSED}%  FreePercent: ${NUMFREE}%" >> "$REPORT"
if (( NUMFREE < 10 )); then
    echo "" >> "$REPORT"
    echo "WARNING: Free space < 10% on root (Free: ${NUMFREE}%)" >> "$REPORT"
fi

# Timeshift snapshot list
echo >> "$REPORT"
echo "== Timeshift snapshot list ==" >> "$REPORT"
"$TIMESHIFT_BIN" --list 2>&1 >> "$REPORT" || true

# Systemd timers
echo >> "$REPORT"
echo "== Systemd timers (next runs) ==" >> "$REPORT"
systemctl list-timers --all --no-legend | grep new_timeshift || true

# Send inline email report
SUBJ="[${HOSTNAME}] Timeshift_report_snapshot mode=$MODE - $(date '+%Y-%m-%d %H:%M:%S')"

{
    echo "To: $LOG_EMAIL"
    echo "Subject: $SUBJ"
    echo
    cat "$REPORT"
} | msmtp "$LOG_EMAIL" || echo "WARNING: mail send failed"

exit 0

