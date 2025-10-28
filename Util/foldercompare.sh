#!/bin/bash

# ================================================
#     FOLDER SIZE COMPARISON TOOL (with colors)
# ================================================

# Define colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'
BOLD='\e[1m'
RESET='\e[0m'

# Check arguments
if [ "$#" -ne 2 ]; then
    echo -e "${YELLOW}Usage:${RESET} $0 <folder1> <folder2>"
    echo "Example: $0 /home/user/backup /mnt/archive"
    exit 1
fi

FOLDER1="$1"
FOLDER2="$2"

# Verify folders
if [ ! -d "$FOLDER1" ]; then
    echo -e "${RED}ERROR:${RESET} Folder 1 does not exist: $FOLDER1"
    exit 1
fi
if [ ! -d "$FOLDER2" ]; then
    echo -e "${RED}ERROR:${RESET} Folder 2 does not exist: $FOLDER2"
    exit 1
fi

echo -e "${CYAN}================================${RESET}"
echo -e "${BOLD}Comparing:${RESET}"
echo -e "${RED}  Folder 1: $FOLDER1 ${RESET}"
echo -e "${RED}  Folder 2: $FOLDER2 ${RESET}"
echo -e "${CYAN}--------------------------------${RESET}"

# Get folder sizes
SIZE1=$(find "$FOLDER1" -type f -printf "%s\n" 2>/dev/null | awk '{total += $1} END {print total+0}')
SIZE2=$(find "$FOLDER2" -type f -printf "%s\n" 2>/dev/null | awk '{total += $1} END {print total+0}')

SIZE1=${SIZE1:-0}
SIZE2=${SIZE2:-0}

DIFF=$(echo "$SIZE1 - $SIZE2" | bc)
if [ "$DIFF" -lt 0 ]; then
    DIFF=$(echo "$DIFF * -1" | bc)
fi

DIFF_MB=$(awk "BEGIN {printf \"%.2f\", $DIFF/1024/1024}")
DIFF_GB=$(awk "BEGIN {printf \"%.4f\", $DIFF/1024/1024/1024}")

# Display results
echo -e "${BLUE}Folder 1 Size:${RESET} ${BOLD}$SIZE1 bytes${RESET}"
echo -e "${BLUE}Folder 2 Size:${RESET} ${BOLD}$SIZE2 bytes${RESET}"
echo -e "${CYAN}--------------------------------${RESET}"
echo -e "${GREEN}Difference:${RESET}"
echo -e "  ${BOLD}$DIFF bytes${RESET}"
echo -e "  ${BOLD}$DIFF_MB MB${RESET}"
echo -e "  ${BOLD}$DIFF_GB GB${RESET}"
echo -e "${CYAN}================================${RESET}"



