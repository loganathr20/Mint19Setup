#!/bin/bash
# An oven timer. This script uses the "notify-send" program to display a
# message after a certain amount of time specified as command line arguments.
# It optionally plays a sound using "mplayer" after calling "notify-send".
# Waiting time can be specified in a user friendly (hours : minutes : seconds)
# format, e.g. "hh:mm:ss" or "mm:ss".
#
# Copyright (C) Ramin Honary 2014, all rights reserved.
# Licensed under the GNU General Public License:
# http://www.gnu.org/licenses/gpl.html
####################################################################################################
 
# Example usage:
#     timer -v 0:30 'Hello, world!'
# 
# will output the amount of time remaining every second, wait for 30 seconds,
# then use "notify-send" to display a "Hello, world!" notification. "-v"
# indicates verbose behavior, which reports how much time is remaining every
# second.
#     timer 2:45:00
# Will wait for 2 hours and 45 minutes and call "notify-send" using the default
# message. Since "-v" is not specified, it will not report how much time is
# remaining,
####################################################################################################
 
# First override these variables to whatever defaults you would like.
 
MESSAGE='Time is up!'
# ^ MESSAGE is the default message to use with the "notify-send" program.
 
SOUND_FILE='/usr/share/sounds/LinuxMint/stereo/phone-incoming-call.ogg';
ICON_FILE='/usr/share/icons/Mint-X/status/scalable/stock_volume-max.svg';
# ^ SOUND_FILE and ICON_FILE are optional, so you can comment out these lines of
# code entirely if you don't want to use them.
 
####################################################################################################
 
require() {
    # This function will check for the existence of programs in /bin and
    # /usr/bin that are necessary to make the script work. Reports an error and
    # evaluates "exit 1" if the file path argument is not found or executable.
    if [ -x "$*" ];
    then
        echo "$*";
    else
        echo "Script requires \"$*\" program, does not appear to be installed." >&2;
        exit 1;
    fi;
}
 
# Check for the following essential programs. The "notify-send" program is
# included in most modern desktop Linux distributions, it will simply pop-up a
# message on the screen in front of all windows.
NOTIFY_SEND="$( require '/usr/bin/notify-send' )" || exit 1;
DATE="$(        require '/bin/date'            )" || exit 1;
SED="$(         require '/bin/sed'             )" || exit 1;
SLEEP="$(       require '/bin/sleep'           )" || exit 1;
DC="$(          require '/usr/bin/dc'          )" || exit 1;
PRINTF="$(      require '/usr/bin/printf'      )" || exit 1;
 
# STEP 1: parse the command line arguments passed to this script.
 
# Verbose indicates whether or not this program will print out how much time is
# remaining in the timer every second.
VERBOSE=false;
 
# Loop through the command line arguments, checking for optional flags. In
# "bash", the "$1" variable is always the next command line argument.
while [ -n "$1" ];
do
    case "$1" in
    ('--sound-file=')   SOUND_FILE="${1%%'--sound-file='}"; shift;;
    ('--icon-file=')    ICON_FILE="${1%%'--icon-file='}"; shift;;
    ('-S'|'--no-sound') SOUND_FILE=''; shift;;
    ('-v'|'--verbose')  VERBOSE=true; shift;;
    (*) break;;
    esac;
done;
 
# Now that we have the optional arguments we need at least a wait time argument
# specified on the command line. Retrieve that now.
TIME="$1"; shift;
if [ -z "${TIME}" ];
then
    echo 'Please specify time to wait.' >&2;
    exit 1;
fi;
 
# Dump the rest of the command line arguments into the "MESSAGE" variable, if
# there are any left. If there are no arguments after the TIME argument, the
# default message is used.
if [ -n "$*" ];
then
    SUBMSG="${MESSAGE}";
    MESSAGE="$*";
fi;
 
# Command line argument passing is now completed.
 
# STEP 2: check if the file resources exist. This is done after command line
# arguments are parsed because the file paths of these resources may have been
# changed by the command line parameters.
 
resource() {
    # This function checks if file resources exist, specifically the sound file
    # and the icon file. If the file does not exist, an error message is
    # printed and "exit 1" is called. If the argument passed is a null string,
    # no error occurs.
    local RSRC="$1"; shift;
    local ERRMSG="$*";
    if [ -n "${RSRC}" -a ! -f "${RSRC}" ];
    then
        echo "Could not find ${ERRMSG}: ${RSRC}" >&2;
        exit 1;
    fi;
}
 
# Check if the "ICON_FILE" and "SOUND_FILE" resources exist. If they are not
# specified, no error occurs.
resource "${ICON_FILE}" 'icon file';
resource "${SOUND_FILE}" 'sound file;'
 
# "mplayer" is used to play the sound. If a sound file is not specified, this
# check need not be performed. If a sound file is specified and "mplayer" is
# not installed on this system, an warning message is printed to the standard
# error stream, and execution of this program continues.
if [ -n "$SOUND_FILE" ];
then
    MPLAYER=$(require '/usr/bin/mplayer');
fi;
 
# Global variable "SECONDS" is set, which indicates the number of seconds the
# timer should wait.
parse_time() {
    # Parse time expressions using "sed", convert times like "1:23:45" (hours :
    # minutes : seconds) or "1:23" (minutes : seconds) to an expression that
    # can be computed by the "dc" program.
    local REGEX="$1"; shift;
    local EQUATION="$1"; shift;
    local INPUT="$*"; shift;
    EQUATION=$(echo "$INPUT" | "${SED}" -ne "s,${REGEX},${EQUATION},p")
    if [ -z "${EQUATION}" ];
    then
        # This should never happen, because the "parse_time()" function is only
        # ever called by other functions in this program.
        echo 'Invalid time computation.' >&2;
        exit 1;
    fi;
    declare -gi SECONDS=$("${DC}" -e "${EQUATION}") || exit 1;
}
 
D='\([[:digit:]][[:digit:]]\?\)';
# "D" is a regular expression that matches one or two digit characters. I will
# be using it a lot, so I saved it to a variable.
 
days_hrs_mins_secs() {
    parse_time '\([[:digit:]]\+\)'":$D:$D:$D" '86400 \1 * 3600 \2 * 60 \3 * \4 + + + p' "$@";
}
hrs_mins_secs()      { parse_time "$D:$D:$D" '3600 \1 * 60 \2 * \3 + + p' "$@"; }
mins_secs()          { parse_time "$D:$D"    '60 \1 * \2 + p' "$@"; }
secs()               { declare -gi SECONDS=$("${PRINTF}" '%i' "$1") || exit 1; }
 
case "${TIME}" in
(*:??:??:??) days_hrs_mins_secs "${TIME}";;
(??:??:??)        hrs_mins_secs "${TIME}";;
(?:??:??)         hrs_mins_secs "${TIME}";;
(??:??)               mins_secs "${TIME}";;
(?:??)                mins_secs "${TIME}";;
(?:?)                 mins_secs "${TIME}";;
(*)                        secs "${TIME}";;
esac;
 
if [ -z "${SECONDS}" ];
then
    echo "Invalid input time \"$TIME\"" >&2;
    echo 'Time should be written as a number of seconds, or as one of the following formats:'
    echo '         mm:ss'
    echo '      hh:mm:ss'
    echo '    D:hh:mm:ss'
    exit 1;
fi;
 
display_time() {
    # This function takes a number of seconds as an argument and uses "Bash"
    # built-in arithmetic functions in the "let" expression to convert the
    # seconds to a time string of the format: (days : hours : minutes :
    # seconds), where "days" and "hours" are not printed if they are zero.
    let DAY="$1"; shift;
    let SEC="${DAY} % 60";
    let DAY="${DAY} / 60";
    let MIN="${DAY} % 60";
    let DAY="${DAY} / 60";
    let HRS="${DAY} % 24";
    let DAY="${DAY} / 24";
    if [ "${DAY}" -ne 0 ];
    then "${PRINTF}" '%i:%.2i:%.2i:%.2i' "${DAY}" "${HRS}" "${MIN}" "${SEC}";
    elif [ "${HRS}" -ne 0 ];
    then "${PRINTF}" '%.2i:%.2i:%.2i' "${HRS}" "${MIN}" "${SEC}";
    else "${PRINTF}" '%.2i:%.2i' "${MIN}" "${SEC}";
    fi;
}
 
### MAIN PROGRAM ###
# The start time is taken right now using the "date" program formatted as a
# single integer value indicating the number of seconds since the UNIX epoch.
# The end time is the start time plus the number of seconds specified as the
# command line argument to this program.
 
let START_TIME=$("${DATE}" '+%s');
let END_TIME="${START_TIME} + ${SECONDS}";
 
# Then a "while" loop is entered which sleeps for one second at the start of
# each loop. Every second, the "date" program is used to retrieve the current
# UNIX epoch time. The Bash arithmetic "let "expression is used to compute the
# difference between the current time and the end time. If this time difference
# is less than or equal to zero seconds, the alarm is triggered and the loop is
# exited by evaluating "exit 0".
# 
# If the "-v" or "--verbose" command line arguments have been specified, then
# every loop also reports the number of seconds remaining until the timer is
# triggered.
 
while "${SLEEP}" 1;
do
    let NOW="$("${DATE}" '+%s')";
    let TIME="${END_TIME} - ${NOW}";
    if [ "${TIME}" -le 0 ];
    then
        # The notify-send program is executed in an "if" expression because I
        # do not want the sound to play if there has been no notification.
        if "${NOTIFY_SEND}" -i "${ICON_FILE}" "${MESSAGE}" "${SUBMSG}";
        then
            # Use of mplayer is optional, and predicated on whether or not it
            # is installed and whether or not a sound file has been specified.
            if [ -x "${MPLAYER}" -a -n "${SOUND_FILE}" ];
            then
                "${MPLAYER}" --quiet "${SOUND_FILE}" >'/dev/null' 2>&1;
            fi;
        fi;
        exit 0;
    else
        if "${VERBOSE}";
        then
            DISPLAY_TIME=$(display_time "${TIME}");
            if [ -n "${SUBMSG}" ];
            then echo "${DISPLAY_TIME} until ${MESSAGE}";
            else echo "${DISPLAY_TIME}";
            fi; 
        fi;
    fi;
done;
 


