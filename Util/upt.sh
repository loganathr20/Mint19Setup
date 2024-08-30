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
 
        echo -e "${GREEN} System Uptime :  "
        echo " "
        uptime
        echo " "
        echo -e " ${RESET}"
        
        echo "--------------------------------------------------------------"
        echo -e "${YELLOW}  Network Speed "
        echo " "
	    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
        echo "--------------------------------------------------------------"
        echo " "
        echo -e "${GREEN}  TimeShift Backup Status "
        sudo timeshift --list
	sudo timeshift --check

        echo "--------------------------------------------------------------"
        echo " "



        sh /home/lraja/Github/Mint19Setup/Util/clearswap.sh
       
        echo "--------------------------------------------------------------"

        echo -e " ${RESET} "
        
        echo -e "${RED} Running in Background. Hit [CTRL+C] to stop! ${RESET} "
        echo "--------------------------------------------------------------"
        sleep 30m



done




