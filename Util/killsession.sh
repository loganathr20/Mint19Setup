#!/bin/bash
TEMP1=`who | grep sandhya | grep tty | awk '{ print $5 }'`
export DISPLAY=`echo "${TEMP1:1:${#string}-1}"`
cinnamon-session-quit --logout --force


