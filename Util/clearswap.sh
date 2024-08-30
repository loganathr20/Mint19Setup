#!/bin/bash

# Sample script written for Part 4 of the RHCE series
# This script will return the following set of system information:
# -Hostname information:


echo "\e[31;43m***** HOSTNAME INFORMATION *****\e[0m"
hostnamectl
echo ""

# -File system disk space usage:
echo "\e[31;43m***** FILE SYSTEM DISK SPACE USAGE *****\e[0m"
df -h
echo ""

# -System uptime and load:
echo "\e[31;43m***** SYSTEM UPTIME AND LOAD *****\e[0m"
uptime
echo ""
# -Logged-in users:
echo "\e[31;43m***** CURRENTLY LOGGED-IN USERS *****\e[0m"
who
echo ""
# -Top 5 processes as far as memory usage is concerned
echo "\e[31;43m***** TOP 5 MEMORY-CONSUMING PROCESSES *****\e[0m"
ps -eo %mem,%cpu,comm --sort=-%mem | head -n 6
echo ""
echo "\e[1;32mDone.\e[0m"
echo ""
echo ""
echo ""
echo ""

# -Free and used memory in the system:
echo "\e[31;43m ***** FREE AND USED MEMORY *****\e[0m"
free
echo ""


echo  "\033[0;34m ***********************************************************************************************\e[0m"

echo  "\e[0;34m **********   PLEASE WAIT SOMETIME FOR SWAP SPACE CLEANUP TO COMPLETE . **********\e[0m"
echo ""
echo ""
echo  "\033[0;34m ***** Clearing Swap Space *****\e[0m"
swapoff -a
sleep 40
swapon -a
sleep 10
echo ""
echo ""
echo ""
echo  "\033[0;34m **********  SWAP SPACE CLEANUP COMPLETED . **********\e[0m"
echo ""
echo ""
echo  "\033[0;34m ***********************************************************************************************\e[0m"

echo "\e[31;43m ***** FREE AND USED MEMORY *****\e[0m"
free
echo ""

echo  "\033[0;34m ***********************************************************************************************\e[0m"


