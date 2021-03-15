# script to free up RAM

echo off

clear

free -m 

swapoff -a 

sleep 40

free -m 

swapon -a 

free -m | grep -i mem | tr -d [A-z],\:,\+,\=,\-,\/, | awk '{print"Memory used: "100-(($3)/($1)*100)"%"}'

sync; echo 3 > /proc/sys/vm/drop_caches

cat /proc/meminfo

 dumpe2fs $(mount | grep 'on \/ ' | awk '{print $1}') | grep 'Filesystem created:'

free -h






