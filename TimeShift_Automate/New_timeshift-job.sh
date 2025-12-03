#!/bin/bash
# -------------------------------------------------------------------
# New Timeshift Snapshot Job + HTML Email Report
# Wakes system → runs snapshot → emails report → system sleeps again
# -------------------------------------------------------------------

EMAIL="loganathr20@gmail.com"
HOSTNAME="$(hostname)"
SUBJECT="[$HOSTNAME] Timeshift Snapshot Report - $(date '+%Y-%m-%d %H:%M')"
TMP_HTML="/tmp/timeshift_report_$$.html"

# --- HTML HEADER ---
cat <<EOF > "$TMP_HTML"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
body { font-family: Arial, sans-serif; background: #f0f0f0; padding: 20px; }
h2 { color: #2a4d9b; }
pre {
  background: #1e1e1e;
  color: #d4d4d4;
  padding: 12px;
  border-radius: 8px;
  overflow-x: auto;
  font-size: 14px;
}
.ok { color: #4caf50; font-weight: bold; }
.err { color: #ff5252; font-weight: bold; }
.section { margin-top: 25px; }
</style>
</head>
<body>

<h2>Timeshift Snapshot Report</h2>

<p><b>Hostname:</b> $HOSTNAME</p>
<p><b>Timestamp:</b> $(date '+%Y-%m-%d %H:%M:%S')</p>
<hr>
EOF

# -------------------------------------------------------------------
# 1) RUN TIMESHIFT SNAPSHOT
# -------------------------------------------------------------------
echo "<div class='section'><h3>1. Running Timeshift Snapshot</h3>" >> "$TMP_HTML"

TS_OUTPUT=$(timeshift --create --comments "Auto Snapshot" --tags O 2>&1)
TS_EXIT=$?

if [[ $TS_EXIT -eq 0 ]]; then
    echo "<p class='ok'>Timeshift Snapshot: SUCCESS</p>" >> "$TMP_HTML"
else
    echo "<p class='err'>Timeshift Snapshot: FAILED</p>" >> "$TMP_HTML"
fi

echo "<pre>$TS_OUTPUT</pre>" >> "$TMP_HTML"
echo "</div>" >> "$TMP_HTML"

# -------------------------------------------------------------------
# 2) LIST TIMERS RELATED TO TIMESIFT & CINNAMON
# -------------------------------------------------------------------
echo "<div class='section'><h3>2. Active Related Timers</h3>" >> "$TMP_HTML"

TIMER_OUTPUT=$(systemctl list-timers --all | grep -E "cinnamon|timeshift" | sed 's/$/<br>/')
echo "<pre>$TIMER_OUTPUT</pre>" >> "$TMP_HTML"
echo "</div>" >> "$TMP_HTML"

# -------------------------------------------------------------------
# 3) LIST RECENT SNAPSHOTS
# -------------------------------------------------------------------
echo "<div class='section'><h3>3. Recent Timeshift Snapshots</h3>" >> "$TMP_HTML"

SNAP_OUTPUT=$(timeshift --list | sed 's/$/<br>/')
echo "<pre>$SNAP_OUTPUT</pre>" >> "$TMP_HTML"
echo "</div>" >> "$TMP_HTML"

# -------------------------------------------------------------------
# ENDING HTML
# -------------------------------------------------------------------
cat <<EOF >> "$TMP_HTML"
<hr>
<p>Report generated automatically by <b>new_timeshift-8h.service</b>.</p>
</body>
</html>
EOF

# -------------------------------------------------------------------
# SEND EMAIL
# -------------------------------------------------------------------
/usr/bin/mail -a "Content-Type: text/html" -s "$SUBJECT" "$EMAIL" < "$TMP_HTML"

rm -f "$TMP_HTML"

exit 0


