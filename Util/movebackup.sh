# rm -rf /media/lraja/LinuxStorage/pvraja.tgz
# rm -rf /media/lraja/LinuxStorage/lraja.tgz
# rm -rf /media/lraja/LinuxStorage/suresh.tgz
# rm -rf /media/lraja/LinuxStorage/kandasubbu.tgz

# sleep 100


mv -f /var/backups/kandasubbu.tgz /media/lraja/LinuxStorage/
mv -f /var/backups/suresh.tgz /media/lraja/LinuxStorage/
mv -f  /var/backups/lraja.tgz /media/lraja/LinuxStorage/
mv -f /var/backups/pvraja.tgz /media/lraja/LinuxStorage/
mv -f /var/backups/home.tgz /media/lraja/LinuxStorage/

mv -f /mnt/Systemback/*.*  /media/lraja/LinuxStorage/

notify-send "Message from Cron ::: Backups from /var/backups moved sucessfully "



