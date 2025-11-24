#!/bin/bash
set -euo pipefail

# New_timeshift_cleanup.sh
# Retention:
#  - Daily (W)   : keep snapshots not older than 2 days
#  - Weekly (W)  : keep snapshots not older than 7 days
#  - Monthly (M) : keep all
#  - Other (O)   : keep latest 3, delete older
#  - Boot (B)    : keep latest 3, delete older
#
# Usage:
#   sudo /usr/local/bin/New_timeshift_cleanup.sh        # run deletions
#   sudo /usr/local/bin/New_timeshift_cleanup.sh dryrun # simulate only, no deletes

EMAIL="loganathr20@gmail.com"
MSMTP_ACCOUNT="gmail"                 # msmtp account name in your msmtp config
PERSIST_LOG="/var/log/timeshift-cleanup.log"
DAILY_DAYS=2
WEEKLY_DAYS=7
KEEP_O=3          # keep most recent N Other (O) snapshots
KEEP_B=3          # keep most recent N Boot (B) snapshots
DRYRUN=false

if [ "${1-}" = "dryrun" ]; then
  DRYRUN=true
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
TMPDIR="$(mktemp -d)"
REPORT_TXT="$TMPDIR/report.txt"
REPORT_HTML="$TMPDIR/report.html"
DELETED_LIST="$TMPDIR/deleted.txt"
ACTION_PLAN="$TMPDIR/action_plan.txt"
RAW_LIST="$TMPDIR/raw_list.txt"

# Ensure persistent log exists
if [ ! -f "$PERSIST_LOG" ]; then
  sudo touch "$PERSIST_LOG" || true
  sudo chmod 640 "$PERSIST_LOG" || true
fi

append_persist() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$PERSIST_LOG"
}

# helpers
snap_to_datetime() {
  # input: 2025-11-24_10-39-49
  # output: 2025-11-24 10:39:49
  local s="$1"
  local dp="${s%%_*}"
  local tp="${s#*_}"
  tp="${tp//-/:}"
  echo "$dp $tp"
}

# collect snapshot table lines only (skip header text)
timeshift --list 2>/dev/null | sed -n '/^[-]\{3,\}/,$p' | tail -n +2 > "$RAW_LIST" || true

# extract snapshot name (col3) and tag (col4). Lines that don't match are ignored.
awk 'NF>=3 { name=$3; tag=(NF>=4?$4:""); print name "," tag }' "$RAW_LIST" > "$TMPDIR/snap_tag.csv"

# create action plan
: > "$ACTION_PLAN"
: > "$DELETED_LIST"

NOW_EPOCH=$(date +%s)

# First, build arrays of O and B snapshots (to keep most recent N)
# We'll read all snapshots into arrays with their epoch for sorting.
declare -A SNAP_EPOCH
declare -A SNAP_TAG

while IFS=',' read -r SNAP TAG; do
  [ -z "$SNAP" ] && continue
  # parse date
  SNAP_DT="$(snap_to_datetime "$SNAP")"
  SNAP_TS=0
  if SNAP_TS=$(date -d "$SNAP_DT" +%s 2>/dev/null); then
    SNAP_EPOCH["$SNAP"]=$SNAP_TS
    SNAP_TAG["$SNAP"]="$TAG"
  else
    # skip snapshots with unparsable dates
    append_persist "SKIP unparsable snapshot name: $SNAP"
  fi
done < "$TMPDIR/snap_tag.csv"

# Build lists by tag sorted newest->oldest
# Helper to sort and write to files
write_sorted_by_tag() {
  local tag="$1"
  # print SNAP and epoch then sort numeric descending
  for s in "${!SNAP_EPOCH[@]}"; do
    if [ "${SNAP_TAG[$s]}" = "$tag" ]; then
      echo "${SNAP_EPOCH[$s]},$s"
    fi
  done | sort -rn -t, -k1,1 | awk -F, '{print $2}'
}

# create ordered lists
mapfile -t LIST_O < <(write_sorted_by_tag "O")
mapfile -t LIST_B < <(write_sorted_by_tag "B")
mapfile -t LIST_W < <(write_sorted_by_tag "W")
mapfile -t LIST_M < <(write_sorted_by_tag "M")
# Additionally, some timeshift outputs may tag Daily snapshots as D - include D as daily
mapfile -t LIST_D < <(write_sorted_by_tag "D")

# For safety also include snapshots with unknown tag treated as O
mapfile -t LIST_QUESTION < <(write_sorted_by_tag "")

# Now decide actions
: > "$ACTION_PLAN"

# 1) Monthly (M) -> keep all : record as KEEP
for s in "${LIST_M[@]}"; do
  echo "KEEP,M,$s,${SNAP_EPOCH[$s]}" >> "$ACTION_PLAN"
done

# 2) Weekly (W) -> keep if age <= WEEKLY_DAYS else DELETE
for s in "${LIST_W[@]}"; do
  age_days=$(( (NOW_EPOCH - SNAP_EPOCH[$s]) / 86400 ))
  if [ "$age_days" -gt "$WEEKLY_DAYS" ]; then
    echo "DELETE,W,$s,$age_days" >> "$ACTION_PLAN"
  else
    echo "KEEP,W,$s,$age_days" >> "$ACTION_PLAN"
  fi
done

# 3) Daily (D) -> treat as daily same as W? (you confirmed daily = 2 days). We'll treat D similar to W as daily type.
for s in "${LIST_D[@]}"; do
  age_days=$(( (NOW_EPOCH - SNAP_EPOCH[$s]) / 86400 ))
  if [ "$age_days" -gt "$DAILY_DAYS" ]; then
    echo "DELETE,D,$s,$age_days" >> "$ACTION_PLAN"
  else
    echo "KEEP,D,$s,$age_days" >> "$ACTION_PLAN"
  fi
done

# 4) Other (O): keep first KEEP_O, delete rest
count=0
for s in "${LIST_O[@]}"; do
  count=$((count+1))
  age_days=$(( (NOW_EPOCH - SNAP_EPOCH[$s]) / 86400 ))
  if [ "$count" -le "$KEEP_O" ]; then
    echo "KEEP,O,$s,$age_days" >> "$ACTION_PLAN"
  else
    echo "DELETE,O,$s,$age_days" >> "$ACTION_PLAN"
  fi
done

# 5) Boot (B): keep first KEEP_B, delete rest
count=0
for s in "${LIST_B[@]}"; do
  count=$((count+1))
  age_days=$(( (NOW_EPOCH - SNAP_EPOCH[$s]) / 86400 ))
  if [ "$count" -le "$KEEP_B" ]; then
    echo "KEEP,B,$s,$age_days" >> "$ACTION_PLAN"
  else
    echo "DELETE,B,$s,$age_days" >> "$ACTION_PLAN"
  fi
done

# 6) unknown/untagged → treat as O (keep first KEEP_O)
count=0
for s in "${LIST_QUESTION[@]}"; do
  count=$((count+1))
  age_days=$(( (NOW_EPOCH - SNAP_EPOCH[$s]) / 86400 ))
  if [ "$count" -le "$KEEP_O" ]; then
    echo "KEEP,?,$s,$age_days" >> "$ACTION_PLAN"
  else
    echo "DELETE,?,$s,$age_days" >> "$ACTION_PLAN"
  fi
done

# Prepare report text header
{
  echo "Timeshift Cleanup Report"
  echo "Run: $TIMESTAMP"
  echo "Rules: Daily <= ${DAILY_DAYS}d | Weekly <= ${WEEKLY_DAYS}d | Other keep ${KEEP_O} | Boot keep ${KEEP_B} | Monthly keep all"
  echo
  echo "Snapshots (before):"
  timeshift --list 2>/dev/null || true
  echo
} >> "$REPORT_TXT"

# Execute action plan
DELETED_COUNT=0
ERROR_COUNT=0

while IFS=',' read -r ACTION TAG SNAP AGE; do
  [ -z "$ACTION" ] && continue
  if [ "$ACTION" = "DELETE" ]; then
    if [ "$DRYRUN" = true ]; then
      echo "[DRYRUN] Would delete: $SNAP  (tag=$TAG, age=${AGE}d)" >> "$REPORT_TXT"
    else
      echo "Deleting: $SNAP  (tag=$TAG, age=${AGE}d)" >> "$REPORT_TXT"
      if timeshift --delete --snapshot "$SNAP" >> "$REPORT_TXT" 2>&1; then
        echo "$SNAP,$TAG,$AGE" >> "$DELETED_LIST"
        append_persist "Deleted snapshot $SNAP (tag=$TAG, age=${AGE}d)"
        DELETED_COUNT=$((DELETED_COUNT+1))
      else
        echo "ERROR deleting $SNAP" >> "$REPORT_TXT"
        append_persist "ERROR deleting snapshot $SNAP"
        ERROR_COUNT=$((ERROR_COUNT+1))
      fi
    fi
  else
    echo "Keeping: $SNAP  (tag=$TAG, age=${AGE}d)" >> "$REPORT_TXT"
  fi
done < "$ACTION_PLAN"

# After snapshot list and disk usage
{
  echo
  echo "Snapshots (after):"
  timeshift --list 2>/dev/null || true
  echo
  echo "Disk usage (root):"
  df -h / 2>/dev/null || true
  echo
  echo "Deleted count: $DELETED_COUNT"
  echo "Errors: $ERROR_COUNT"
} >> "$REPORT_TXT"

# Build simple HTML email (style A - clean)
SPACE_RECLAIMED_BYTES=0
# attempt to estimate reclaimed space by reading df before/after via a simple approach:
# run df before was not stored; instead we will not attempt to estimate if not saved.
# (We can add exact before/after if needed)

HTML_HEADER='<!doctype html><html><head><meta charset="utf-8"><style>body{font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#222}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ddd;padding:6px;text-align:left}th{background:#f7fafc}</style></head><body>'
HTML_FOOTER='</body></html>'

{
  echo "$HTML_HEADER"
  echo "<h2>Timeshift Cleanup Report</h2>"
  echo "<p><strong>Run:</strong> $TIMESTAMP</p>"
  echo "<p><strong>Rules:</strong> Daily ≤ ${DAILY_DAYS}d • Weekly ≤ ${WEEKLY_DAYS}d • Keep ${KEEP_O} Other • Keep ${KEEP_B} Boot • Monthly keep all</p>"
  echo "<h3>Summary</h3>"
  echo "<table><tr><th>Deleted</th><td>${DELETED_COUNT}</td></tr><tr><th>Errors</th><td>${ERROR_COUNT}</td></tr></table>"
  echo "<h3>Deleted snapshots</h3>"
  if [ -s "$DELETED_LIST" ]; then
    echo "<table><tr><th>Snapshot</th><th>Tag</th><th>Age (days)</th></tr>"
    while IFS=',' read -r sn tag age; do
      echo "<tr><td><code>$sn</code></td><td>$tag</td><td>$age</td></tr>"
    done < "$DELETED_LIST"
    echo "</table>"
  else
    echo "<p>No snapshots deleted.</p>"
  fi
  echo "<h3>Timeshift list (after)</h3>"
  echo "<pre>$(timeshift --list 2>/dev/null | sed 's/&/\&amp;/g')</pre>"
  echo "$HTML_FOOTER"
} > "$REPORT_HTML"

# Send email only if changes occurred or errors (you asked email always earlier; here we'll always send)
EMAIL_SUBJ="Timeshift Cleanup Report - ${TIMESTAMP} - deleted:${DELETED_COUNT} errors:${ERROR_COUNT}"

{
  echo "To: ${EMAIL}"
  echo "Subject: ${EMAIL_SUBJ}"
  echo "MIME-Version: 1.0"
  echo "Content-Type: text/html; charset=UTF-8"
  echo ""
  cat "$REPORT_HTML"
} | msmtp -a "${MSMTP_ACCOUNT}" "${EMAIL}" 2>>"$PERSIST_LOG" || append_persist "msmtp send failed at $(date)"

# append plain text report to persistent log for historical record
cat "$REPORT_TXT" >> "$PERSIST_LOG"
echo "--------------------------------------------------------" >> "$PERSIST_LOG"

# cleanup
rm -rf "$TMPDIR"

exit 0

