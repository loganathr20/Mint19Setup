
# sudo service tomcat7 stop
# sudo /etc/init.d/jenkins start
# sudo /etc/init.d/jenkins stop
sudo /etc/init.d/mysql stop

killall blender
killall supertuxkart
killall googleearth-bin
killall stellarium

# killall tomboy
# killall tomcat7
# killall jenkins

killall banshee
killall nemo
# killall chrome
killall thunderbird
killall notepad
killall leafpad
killall gnemo-terminal

killall nemo
killall mysqld
killall mysql
killall sleep
killall mysqld
killall teamviewerd
killall dropbox
killall skype
killall pidgin
killall evolution
killall evolution-alarm-notify
killall evolution-source-registry
killall evolution-calendar-factory
killall bash
killall tomboy-notes
killall gnome-system-monitor
killall google
killall Transmission
killall teamviewerd
# killall cairo-dock
killall leafpad
killall gnome-do
killall gnome-calculator


cat /proc/cpuinfo

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

cat /proc/cpuinfo | grep processor

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

lshw -class processor

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

uptime

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

free

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
uname -a

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
cat /proc/version

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
cat /etc/*release 

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
cat /etc/*version 

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
cat /etc/issue.net


echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
who am i
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
env

ifconfig

sync; echo 3 > /proc/sys/vm/drop_caches

cat /proc/meminfo

# dumpe2fs $(mount | grep 'on \/ ' | awk '{print $1}') | grep 'Filesystem created:'

free -h

# sh $HOME/Util/highcpu_usage.sh &

# sh $HOME/Util/killusage.sh

# google-drive-ocamlfuse ~/gdrive

 
# echo " Press any key to exit"
# read a
