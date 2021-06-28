
#!/bin/bash

# PURPOSE: Script to check temperature of CPU cores and report/shutdown if specified temperatures exceeded
#
# AUTHOR: feedback[AT]HaveTheKnowHow[DOT]com

# Expects two arguments:
#    1. Warning temperature
#    2. Critical shutdown temperature
#    eg. using ./CPUTempShutdown.sh 30 40
#        will warn when temperature of one or more cores hit 30degrees and shutdown when either hits 40degrees.

# NOTES:
# Change the strings LOG_FILE, ERROR_LOGFILE & EMAIL_ADDRESS as required

# Assumes output from sensors command is as follows:
#
# atk0110-acpi-0
# Adapter: ACPI interface
# Vcore Voltage:       +1.08 V  (min =  +0.80 V, max =  +1.60 V)
#  +3.3 Voltage:       +3.25 V  (min =  +2.97 V, max =  +3.63 V)
#  +5 Voltage:         +4.99 V  (min =  +4.50 V, max =  +5.50 V)
#  +12 Voltage:       +12.21 V  (min = +10.20 V, max = +13.80 V)
# CPU FAN Speed:       992 RPM  (min =  600 RPM, max = 7200 RPM)
# CHASSIS1 FAN Speed:    0 RPM  (min =  600 RPM, max = 7200 RPM)
# POWER FAN Speed:       0 RPM  (min =  600 RPM, max = 7200 RPM)
# CPU Temperature:     +27.0°C  (high = +60.0°C, crit = +95.0°C)
# MB Temperature:      +40.0°C  (high = +45.0°C, crit = +95.0°C)

# coretemp-isa-0000
# Adapter: ISA adapter
# Core 0:       +35.0°C  (high = +78.0°C, crit = +100.0°C)
# Core 1:       +35.0°C  (high = +78.0°C, crit = +100.0°C)
#
# if not then modify the commands str=$(sensors | grep "Core $i:") & newstr=${str:14:2} below accordingly

LOG_FILE="/home/htkh/CPUWarning.Log"
ERROR_LOGFILE="/home/htkh/CPUExceeded.Log"
EMAIL_ADDRESS="myemail@myaddress.com"

echo "JOB RUN AT $(date)"
echo "======================================="

echo ''
echo 'CPU Warning Limit set to => '$1
echo 'CPU Shutdown Limit set to => '$2
echo ''
echo ''

sensors

echo ''
echo ''

for i in 0 1
do

  str=$(sensors | grep "Core $i:")
  newstr=${str:15:2}

  if [ ${newstr} -ge $1 ]
  then
    echo '============================'                             >>$LOG_FILE
    echo $(date)                                                    >>$LOG_FILE
    echo ''                                                         >>$LOG_FILE
    echo ' WARNING: TEMPERATURE CORE' $i 'EXCEEDED' $1 '=>' $newstr >>$LOG_FILE
    echo ''                                                         >>$LOG_FILE
    echo '============================'                             >>$LOG_FILE
  fi
  
  if [ ${newstr} -ge $2 ]
  then
    echo '============================'								>$ERROR_LOGFILE
    echo ''															>>$ERROR_LOGFILE
    echo 'CRITICAL: TEMPERATURE CORE' $i 'EXCEEDED' $2 '=>' $newstr	>>$ERROR_LOGFILE
    echo ''															>>$ERROR_LOGFILE
    echo '============================'								>>$ERROR_LOGFILE

    /usr/bin/mail -s "[MyMediaServer] CPU Temperature Exceeded - Server has shut itself down" "$EMAIL_ADDRESS" < $ERROR_LOGFILE &
    /sbin/shutdown -h now

    echo 'Email Sent.....'											>>$LOG_FILE
    exit
  else
    echo ' Temperature Core '$i' OK at =>' $newstr
    echo ''
  fi
done

echo 'Both CPU Cores are within limits'
echo ''






