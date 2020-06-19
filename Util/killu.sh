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

killall leafpad
# killall /opt/whatsapp-desktop/WhatsApp
killall radiotray
# killall /opt/whatsapp-desktop/WhatsApp
# killall skype
# killall /usr/share/skypeforlinux/skypeforlinux
killall nemo
killall leafpad
killall gnome-do gnome-calculator nemo
killall gnome-terminal chrome  gnome-system-monitor gnome-terminal-server

killall gnome-do gnome-calculator evolution nemo
killall gnome-terminal  gnome-system-monitor gnome-terminal-server
# killall radiotray


