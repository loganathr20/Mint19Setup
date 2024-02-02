#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m' # Reset color to default


clear

while true
do
        clear
        sh /home/lraja/Documents/update_git.sh
        
        clear
        
        echo "--------------------------------------------------------------"

#       echo -e "${GREEN} System Temperature -- HDD  "
#       sudo hddtemp /dev/sda
#       sudo sensors
 
        echo  "${GREEN} System Uptime :  "
        echo " "
        uptime
        echo " "
        echo  " ${RESET}"
        
        echo "--------------------------------------------------------------"
        echo  "${YELLOW}  Network Speed "
        echo " "
	    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
        echo "--------------------------------------------------------------"
        echo " "
        echo  " ${RESET} "

	    echo  "${RED} Running in Background. Hit [CTRL+C] to stop! ${RESET} "
        echo "--------------------------------------------------------------"
        sleep 58m

done




