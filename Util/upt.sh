#!/bin/bash


while true
do
        clear
        echo "--------------------------------------------------------------"
        echo " System Temperature -- HDD  "
        # sudo hddtemp /dev/sda
        sudo sensors
        uptime
        echo "\n"
	echo "Running in Background. Hit [CTRL+C] to stop!"
        echo "--------------------------------------------------------------"
        # sleep 10
        sleep 0.06m

done




