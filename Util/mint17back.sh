#!/bin/sh
now="$(date +'%d_%m_%Y_%H_%M_%S')"
# filename="db_backup_$now".gz
logfile="$backupfolder/"backup_log_"$(date +'%Y_%m')".txt
echo "mintbackup started at $(date +'%d-%m-%Y %H:%M:%S')" >> "$logfile"
echo 'ls -ltr HOME/mint17hub'  >> "$logfile"
cp /var/cache/apt/archives/*.deb $HOME/mint17hub/debarchives


