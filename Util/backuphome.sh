
tar -zcvf /var/backups/pvraja.tgz /home/pvraja

tar -zcf /var/backups/home.tgz /home/

tar -zcvf /var/backups/lraja.tgz /home/lraja

# tar -zcvf /var/backups/suresh.tgz /home/suresh

# tar -zcvf /var/backups/kandasubbu.tgz /home/kandasubbu

sleep 100

notify-send "Message from cron ::: Compression sucessful for /home/ folder. tgz files stored in /var/backup folder "




