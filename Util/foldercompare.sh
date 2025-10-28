#!/bin/bash

clear

# ================================================
#        FOLDER SIZE COMPARISON TOOL (Linux)
# ================================================

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <folder1> <folder2>"
    echo "Example: $0 /home/user/backup /mnt/archive"
    exit 1
fi

FOLDER1="$1"
FOLDER2="$2"

# Verify both folders exist
if [ ! -d "$FOLDER1" ]; then
    echo "ERROR: Folder 1 does not exist: $FOLDER1"
    exit 1
fi

if [ ! -d "$FOLDER2" ]; then
    echo "ERROR: Folder 2 does not exist: $FOLDER2"
    exit 1
fi

echo "================================"
echo "Comparing:"
echo "  Folder 1: $FOLDER1"
echo "  Folder 2: $FOLDER2"
echo "--------------------------------"

# Get total size in bytes for each folder
SIZE1=$(find "$FOLDER1" -type f -printf "%s\n" 2>/dev/null | awk '{total += $1} END {print total+0}')
SIZE2=$(find "$FOLDER2" -type f -printf "%s\n" 2>/dev/null | awk '{total += $1} END {print total+0}')

# Default to 0 if empty
SIZE1=${SIZE1:-0}
SIZE2=${SIZE2:-0}

# Calculate difference
DIFF=$(echo "$SIZE1 - $SIZE2" | bc)
if [ "$DIFF" -lt 0 ]; then
    DIFF=$(echo "$DIFF * -1" | bc)
fi

# Convert to MB and GB with 2 decimal places
DIFF_MB=$(awk "BEGIN {printf \"%.2f\", $DIFF/1024/1024}")
DIFF_GB=$(awk "BEGIN {printf \"%.4f\", $DIFF/1024/1024/1024}")

# Display results
echo "Folder 1 Size = $SIZE1 bytes"
echo "Folder 2 Size = $SIZE2 bytes"
echo "--------------------------------"
echo "Difference:"
echo "  $DIFF bytes"
echo "  $DIFF_MB MB"
echo "  $DIFF_GB GB"
echo "================================"


