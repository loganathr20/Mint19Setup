#!/bin/bash

# =====================================================================
# New_timeshift-job-v5.sh
# Creates Timeshift snapshot + sends email notification using msmtp
# Cleanup disabled completely (NO deletion, NO cleanup email)
# =====================================================================

LOGFILE="/var/log/New_timeshift.log"
EMAIL="loganathr20@gmail.com"
HOSTNAME=$(hostname)
MODE="$1"      # BootTime or Scheduled

# Write to log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S')  $1" | tee -a "$LOGFILE"
}

log "=== Running Timeshift Job V5 ($MODE) ==="

# ---------------------------------------------------------------------
# CREATE SNAPSHOT
# ---------------------------------------------------------------------
log "Creating Timeshift snapshot (mode=$MODE)..."
SNAP_OUTPUT=$(timeshift --create --comments "$MODE-Snapshot" --tags D --scripted 2>&1)
RET=$?

echo "$SNAP_OUTPUT" >> "$LOGFILE"

# ---------------------------------------------------------------------
# EMAIL BODY
# ---------------------------------------------------------------------
EMAIL_SUBJECT="Timeshift Snapshot ($MODE) - $(date '+%b %d %H:%M')"

if [ $RET -eq 0 ]; then
    EMAIL_BODY="Timeshift snapshot created successfully.

Hostname: $HOSTNAME
Mode: $MODE
Date: $(date)

Full log stored at: $LOGFILE
"
    log "Snapshot SUCCESS"
else
    EMAIL_BODY="Timeshift snapshot FAILED.

Hostname: $HOSTNAME
Mode: $MODE
Date: $(date)

Error:
$SNAP_OUTPUT

Full log stored at: $LOGFILE
"
    log "Snapshot FAILED"
fi

# ---------------------------------------------------------------------
# SEND EMAIL (No cleanup summary included)
# ---------------------------------------------------------------------
log "Sending email notification..."
echo -e "Subject: $EMAIL_SUBJECT\n\n$EMAIL_BODY" | msmtp "$EMAIL"

log "Job completed (V5)"
exit 0

