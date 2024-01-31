#!/bin/bash

clear

while true
do
        clear

        echo "--------------------------------------------------------------"
        echo " System Temperature -- HDD  "
        # sudo hddtemp /dev/sda
        sudo sensors
        uptime
        echo " "
        echo " "
        
        echo "--------------------------------------------------------------"
        echo " Network Speed  "
        echo " "
	curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
        echo "--------------------------------------------------------------"
        echo " "
        echo " "
	echo "Running in Background. Hit [CTRL+C] to stop!"
        echo "--------------------------------------------------------------"
        # sleep 10
        sleep 50m

done




