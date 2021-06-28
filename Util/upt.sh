#!/bin/bash


while true
do
        clear
        echo "\n"
        echo "--------------------------------------------------------------"
        uptime
        echo "\n"
        echo "\n"        
        echo " System Temperature -- HDD  "
        sudo hddtemp /dev/sda
        
        echo "\n"
	echo "Running in Background. Hit [CTRL+C] to stop!"
        echo "--------------------------------------------------------------"
        sleep 5



done




