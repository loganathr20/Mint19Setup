rm -rf /var/backups/lraja.tgz
rm -rf /var/backups/pvraja.tgz
rm -rf /var/backups/home.tgz
rm -rf /var/backups/lraja*.tgz
rm -rf /var/backups/pvraja*.tgz
rm -rf /var/backups/home*.tgz
rm -rf /mnt/Systemback/*.*
sudo rm /var/lib/dpkg/lock
sudo rm /var/cache/apt/archives/lock


# You can clean partial packages using a command
sudo apt-get autoclean
# You can auto cleanup apt-cache
sudo apt-get clean
# You can clean up of any unused dependencies
sudo apt-get autoremove




