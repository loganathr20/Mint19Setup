#!/bin/bash

# notify-timer.sh
# Displays a desktop notification after a specified time, optionally playing a sound.
#
# Usage: notify-timer.sh <time> <message> [sound_file]
#
#   <time>: Duration in hh:mm:ss or mm:ss format (e.g., 1:30 for 1 min 30 secs, 0:0:90 is invalid mm/ss)
#   <message>: The notification message to display.
#   [sound_file]: Optional path to a sound file to play using mplayer after notification.
#
# Requires: notify-send (usually part of libnotify-bin), sleep (coreutils)
# Optional: mplayer for sound playback

# Function to display usage instructions
usage() {
    echo "Usage: $0 <time> <message> [sound_file]"
    echo "  <time> is the duration in hh:mm:ss or mm:ss format"
    echo "    (e.g., 1:30 for 1 minute 30 seconds, 00:01:30, 5 for 5 seconds)"
    echo "    Note: Minutes and seconds in mm:ss or hh:mm:ss format should be < 60."
    echo "  <message> is the notification message"
    echo "  [sound_file] is an optional path to a sound file to play with mplayer"
    echo ""
    echo "Requires: notify-send (e.g., libnotify-bin), sleep (coreutils)"
    echo "Optional: mplayer for sound playback"
    exit 1
}

# --- Input Validation and Parsing ---

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    usage
fi

time_str="$1"
message="$2"
sound_file="$3" # This will be empty if the third argument is not provided

sound_file="/home/lraja/Github/Mint19Setup/soundfiles/samsung_harmonics.mp3" # This will be empty if the third argument is not provided

# Parse time string into seconds
IFS=: read -ra time_parts <<< "$time_str"
seconds=0
valid_time=true

if [ "${#time_parts[@]}" -eq 1 ]; then
    # Assume it's just seconds
    if ! [[ "$time_str" =~ ^[0-9]+$ ]]; then
         echo "Error: Invalid time format. Single value must be non-negative integer seconds."
         valid_time=false
    else
        seconds="$time_str"
    fi
elif [ "${#time_parts[@]}" -eq 2 ]; then
    # mm:ss format
    minutes="${time_parts[0]}"
    secs="${time_parts[1]}"
    if ! [[ "$minutes" =~ ^[0-9]+$ ]] || ! [[ "$secs" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid time format. Minutes and seconds must be non-negative integers."
        valid_time=false
    elif [ "$secs" -ge 60 ]; then
         echo "Error: Invalid time format. Seconds must be less than 60 in mm:ss format."
         valid_time=false
    else
        seconds=$((minutes * 60 + secs))
    fi
elif [ "${#time_parts[@]}" -eq 3 ]; then
    # hh:mm:ss format
    hours="${time_parts[0]}"
    minutes="${time_parts[1]}"
    secs="${time_parts[2]}"
    if ! [[ "$hours" =~ ^[0-9]+$ ]] || ! [[ "$minutes" =~ ^[0-9]+$ ]] || ! [[ "$secs" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid time format. Hours, minutes, and seconds must be non-negative integers."
        valid_time=false
    elif [ "$minutes" -ge 60 ] || [ "$secs" -ge 60 ]; then
        echo "Error: Invalid time format. Minutes and seconds must be less than 60 in hh:mm:ss format."
        valid_time=false
    else
        seconds=$((hours * 3600 + minutes * 60 + secs))
    fi
else
    echo "Error: Invalid time format. Use hh:mm:ss, mm:ss, or just seconds."
    valid_time=false
fi

# Exit if time format is invalid
if [ "$valid_time" = false ]; then
    usage
fi

# Ensure seconds is non-negative
if [ "$seconds" -lt 0 ]; then
    echo "Error: Time duration cannot be negative."
    usage
fi

# --- Dependency Checks ---

# Check if required programs exist
if ! command -v notify-send &> /dev/null; then
    echo "Error: 'notify-send' not found. Please install it (e.g., sudo apt-get install libnotify-bin)."
    exit 1
fi

if ! command -v sleep &> /dev/null; then
     echo "Error: 'sleep' not found. This is part of coreutils and should be available."
     exit 1
fi

# Check for mplayer only if a sound file was provided
if [ -n "$sound_file" ]; then
    if ! command -v mplayer &> /dev/null; then
        echo "Warning: 'mplayer' not found. Sound playback is not available."
        # Clear sound_file so we don't attempt to play it later
        sound_file=""
    elif [ ! -f "$sound_file" ]; then
         echo "Warning: Sound file not found: '$sound_file'. Sound playback is not available."
         # Clear sound_file
         sound_file=""
    fi
fi


# --- Main Logic ---

# Wait for the specified time
echo "Setting timer for $time_str ($seconds seconds)..."
sleep "$seconds"

# Display notification
echo "Time's up! Displaying notification..."
# Use "Timer" as the title for consistency
notify-send "Timer" "$message"

# Play sound if specified and mplayer is available
if [ -n "$sound_file" ]; then
    echo "Playing sound: $sound_file"
    mplayer "$sound_file" &> /dev/null # Redirect output to /dev/null to keep the console clean
fi

echo "Script finished."


##########################################################3

# How to use the script:

# Save the script: Save the code above in a file, for example, notify-timer.sh.
# Make it executable: Open your terminal and run chmod +x notify-timer.sh.

# Run the script:
# To set a timer for 5 seconds with a message:
# Bash
# ./notify-timer.sh 5 "Quick test notification"

# To set a timer for 1 minute and 30 seconds with a message:
# Bash
# ./notify-timer.sh 1:30 "Take a break now"

# To set a timer for 1 hour, 5 minutes, and 10 seconds with a message:
# Bash

# ./notify-timer.sh 01:05:10 "Meeting reminder"
# To set a timer for 30 seconds with a message and play a sound (replace /path/to/your/sound.mp3 with the actual path):
# Bash

# ./notify-timer.sh 30 "Task complete" /path/to/your/sound.mp3

# ./notify-timer.sh 5 "Quick test notification" (5 Seconds)
# ./notify-timer.sh 00:30:00  "Lunch Timing notification" & ( 30 Minutes )
# ./notify-timer.sh 01:30:00  "Meeting notification" & (1 Hour 30 Minutes)


###################################################################
