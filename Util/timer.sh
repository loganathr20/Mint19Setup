#!/bin/bash

SECS=3600
UNIT_TIME=60

clear
echo " Timer Set for 1 hour ";
echo " Timer Started "

sleep $UNIT_TIME

#UNIT_TIME is the interval in seconds between each sampling

STEPS=$(( $SECS / $UNIT_TIME ))

for ( i=1; i<STEPS; i++)
do
  clear
  echo "###############   $i minute completed  ######################### " ;
  sleep $UNIT_TIME
  uptime
done

echo "###############   1 Hour completed.  ######################### " ;
