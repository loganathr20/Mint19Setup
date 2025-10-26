#!/bin/bash

# Usage: ./compare_folders.sh /path/to/folder1 /path/to/folder2

# Check if two arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <folder1> <folder2>"
    exit 1
fi

FOLDER1="$1"
FOLDER2="$2"

# Check if folders exist
if [ ! -d "$FOLDER1" ]; then
    echo "Error: $FOLDER1 does not exist."
    exit 1
fi

if [ ! -d "$FOLDER2" ]; then
    echo "Error: $FOLDER2 does not exist."
    exit 1
fi

# Get folder sizes in bytes
SIZE1=$(du -sb "$FOLDER1" | awk '{print $1}')
SIZE2=$(du -sb "$FOLDER2" | awk '{print $1}')

# Convert bytes to MB and GB
SIZE1_MB=$(echo "scale=2; $SIZE1/1024/1024" | bc)
SIZE1_GB=$(echo "scale=2; $SIZE1/1024/1024/1024" | bc)

SIZE2_MB=$(echo "scale=2; $SIZE2/1024/1024" | bc)
SIZE2_GB=$(echo "scale=2; $SIZE2/1024/1024/1024" | bc)

# Count number of files
FILES1=$(find "$FOLDER1" -type f | wc -l)
FILES2=$(find "$FOLDER2" -type f | wc -l)

# Compare sizes
if [ "$SIZE1" -eq "$SIZE2" ]; then
    MATCH="Yes"
else
    MATCH="No"
fi

# Report
echo "Folder Comparison Report:"
echo "--------------------------"
echo "Folder 1: $FOLDER1"
echo "Size: $SIZE1 bytes | $SIZE1_MB MB | $SIZE1_GB GB"
echo "Number of files: $FILES1"
echo
echo "Folder 2: $FOLDER2"
echo "Size: $SIZE2 bytes | $SIZE2_MB MB | $SIZE2_GB GB"
echo "Number of files: $FILES2"
echo
echo "Do sizes match? $MATCH"




