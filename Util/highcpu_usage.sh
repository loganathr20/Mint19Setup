#!/bin/bash
# High CPU Usage Script
# At times, we need to monitor the high CPU usage in the system. We can use the below script to monitor the high CPU usage. 

while [ true ] ;do
used=`free -m |awk 'NR==3 {print $4}'`

if [ $used -lt 2048 ] && [ $used -gt 800 ]; then
echo "SYSTEM ALERT :: Free memory is below 2000MB. Possible memory leak!!!" 

# echo "Free memory is below 2000MB. Possible memory leak!!!" | /usr/bin/mail -s "HIGH MEMORY ALERT!!!" loganathr@gmail.com
 
echo "Free memory is below 2000MB. Possible memory leak!!!" | /usr/bin/mail -s "HIGH MEMORY ALERT!!!" lraja@lraja-Aspire-X3990
 

fi
sleep 1000 

done
