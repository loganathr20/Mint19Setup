#!/bin/sh

rm -rf /home/lraja/gdrive/CV
rm -rf /home/lraja/gdrive/Shares
rm -rf /home/lraja/Documents/LCloud/Assembla/CV
rm -rf /home/lraja/Documents/LCloud/Assembla/Shares
sleep 20

cp -r /media/lraja/LinuxStorage1/SVN/MountainView/Documents/Shares /home/lraja/gdrive
sleep 20
cp -r /media/lraja/LinuxStorage1/SVN/MountainView/CV /home/lraja/gdrive
sleep 20

cp -r /media/lraja/LinuxStorage1/SVN/MountainView/Documents/Shares /home/lraja/Documents/LCloud/Assembla
sleep 20
cp -r /media/lraja/LinuxStorage1/SVN/MountainView/CV /home/lraja/Documents/LCloud/Assembla
sleep 20

cd /home/lraja/Documents/LCloud/Assembla
svn commit CV/ -m "updating cloud"
svn commit Shares/ -m "updating cloud"
svn update

cp -r /var/cache/apt/archives/*.* /media/lraja/LinuxStorage1/Net_Downloads
sleep 20

