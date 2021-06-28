#!/bin/bash

# PURPOSE: Script to check temperature of installed hard drives and report/shutdown if specified temperatures exceeded
#
# AUTHOR: feedback[AT]HaveTheKnowHow[DOT]com

# Expects three arguments:
#    1. Warning temperature
#    2. Critical shutdown temperature
#    3. If argument 3 is present then just check that drive letter
#    eg. using ./DriveTemps.sh 35 45
#	will warn when temperature of one or more drives reaches 35degrees and shutdown when any one of them hits 45
#    eg. using ./DriveTemps.sh 35 45 c
#	will warn when temperature of drive sdc reaches 35degrees and shutdown when it hits 45

# NOTES:
#  Change the string ">>/home/htkh" as required
#  Substitute string "myemail@myaddress.com" with your own email address in the string which starts "/usr/sbin/ssmtp myemail@myaddress.com"
#  Change the command   MyList='a b c d e' to the number of drives you have. In this case I'm using 6 drives

# Assumes  /usr/sbin/smartctl -n standby -a /dev/sd$i returns the string 'Temperature_Celsius' somewhere

echo "JOB RUN AT $(date)"
echo '============================'

echo ''
echo 'Drive Warning Limit set to =>' $1
echo 'Drive Shutdown Limit set to =>' $2
echo ''
echo ''

if [ $# -eq 2 ]
then
  MyList='a b c d e'
  echo 'Testing all drives'
else 
  MyList=($3)
  echo 'Testing only the system drive'
fi

echo ''

for i in $MyList
do
  echo 'Drive /dev/sd'$i
  /usr/sbin/smartctl -n standby -a /dev/sd$i | grep Temperature_Celsius
done

echo ''
echo ''

for i in $MyList
do
 #Check state of drive 'active/idle' or 'standby'
  stra=$(/sbin/hdparm -C /dev/sd$i | grep 'drive' | awk '{print $4}')

  echo 'Testing Drive sd'$i

  if [ ${stra} = 'standby' ]
  then 
    echo '    Drive sd'$i 'is in standby'
    echo ''
  else

    str1='/usr/sbin/smartctl -n standby -a /dev/sd'$i
    str2=$($str1 | grep Temperature_Celsius | awk '{print $10}')

    if [ ${str2} -ge $1 ]
    then

      echo '============================'					>>/home/htkh/Desktop/DriveWarning.Log
      echo $(date)                                                    		>>/home/htkh/Desktop/DriveWarning.Log
      echo ''									>>/home/htkh/Desktop/DriveWarning.Log
      echo 'WARNING: TEMPERATURE FOR DRIVE sd'$i 'EXCEEDED' $1 '=>' $str2	>>/home/htkh/Desktop/DriveWarning.Log
      echo ''									>>/home/htkh/Desktop/DriveWarning.Log
      echo '============================'					>>/home/htkh/Desktop/DriveWarning.Log
    fi

    if [ ${str2} -ge $2 ]
    then

      echo '============================'
      echo ''
      echo 'CRITICAL: TEMPERATURE FOR DRIVE sd'$i 'EXCEEDED' $2 '=>' $str2
      echo ''
      echo '============================'
      /sbin/shutdown -h now
      /usr/sbin/ssmtp myemail@myaddress.com </home/htkh/MyScripts/msg.txt
      echo 'Email Sent.....'
      exit
    else

      echo '    Temperature of Drive '$i' is OK at =>' $str2
      echo ''
    fi
  fi
done

echo 'All Drives are within limits'
echo ''



