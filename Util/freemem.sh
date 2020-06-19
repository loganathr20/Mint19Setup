# script to free up RAM

echo off

clear

echo " Memory Statistics "
echo ""
echo ""
echo ""

free -m | grep -i mem | tr -d [A-z],\:,\+,\=,\-,\/, | awk '{print"Memory used: "100-(($3)/($1)*100)"%"}'

echo ""
echo ""
echo ""

echo " Press any key to continue"

read a

sync; echo 3 > /proc/sys/vm/drop_caches

cat /proc/meminfo

 dumpe2fs $(mount | grep 'on \/ ' | awk '{print $1}') | grep 'Filesystem created:'

free -h

echo " Press any key to exit"

read a




