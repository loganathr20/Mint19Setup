#!/bin/bash

ADMIN=loganathr@gmail.com

ALERT=90
df -H | grep -vE 'abc:/xyz/pqr | tmpfs |cdrom|Used' | awk '{ print $5 " " $1 }' | while read output; do 
usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1 ) 
echo $usep
partition=$(echo $output | awk '{ print $2 }' ) 
if [ $usep -ge $ALERT ]; then 
  echo  "Alert: Almost out of disk space $usep" 
  df -H | mail -s "Alert: out of disk space $usep"  $ADMIN
fi 
done