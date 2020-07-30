# to kill processes highcpu_usage.sh 
#!/bin/sh

for process in `ps -ax | grep /home/lraja/Util/highcpu_usage.sh | awk '{print $1}' `
do
  kill -9 $process
  echo "highcpu_usage.sh $process killed "
done


for process in `ps -ax | grep 'sleep 1000' | awk '{print $1}' `
do
  kill -9 $process
  echo "Sleep process $process killed "
done


killall /opt/whatsapp-desktop/WhatsApp
killall radiotray
killall /opt/whatsapp-desktop/WhatsApp
killall skype
killall /usr/share/skypeforlinux/skypeforlinux
killall nemo
killall leafpad
killall gnome-do gnome-calculator tomboy skype  pidgin  evolution nemo
killall gnome-terminal chrome  gnome-terminal-server tomboy dropbox leafpad
killall tomboy
killall gnome-system-monitor
killall radio-tray
killall /usr/lib/firefox/firefox
killall googleearth-bin
killall google-earth-pro





