#!/bin/bash
clear

# =============================
# Color Codes for echo
# =============================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# =============================
# Helper function for colored echo
# =============================
cecho() {
    local color="$1"
    local message="$2"
    echo -e "${color}${BOLD}${message}${RESET}"
}

# =============================
# Reload systemd
# =============================
cecho $CYAN "Reloading systemd daemon..."
sudo systemctl daemon-reload

# =============================
# Enable and start timers
# =============================
cecho $BLUE "Enabling and starting timers..."
for timer in new_timeshift-8h.timer new_timeshift-boot.timer timeshift-cleanup.timer linux_hardware_report.timer; do
    cecho $YELLOW "-> Enabling and starting $timer"
    sudo systemctl enable --now "$timer"
done

# Optional second reload
sudo systemctl daemon-reload

# =============================
# List relevant timers
# =============================
cecho $CYAN "\nListing active timers..."
sudo systemctl list-timers --all | grep -E "cinnamon|timeshift|linux_hardware_report"

# =============================
# Run hardware healthcheck report
# =============================
cecho $BLUE "\nRunning Linux Hardware Health Check Report..."
if [[ -f /usr/local/bin/linux_hardware_report.sh ]]; then
    sudo chmod +x /usr/local/bin/linux_hardware_report.sh
    sudo /usr/local/bin/linux_hardware_report.sh
    cecho $GREEN "Linux Hardware Health Check Report generated successfully. Check email: loganathr20@gmail.com"
else
    cecho $RED "Error: /usr/local/bin/linux_hardware_report.sh not found!"
fi

sleep 20

# =============================
# Run Timeshift Cleanup report
# =============================
cecho $BLUE "\nRunning Timeshift Cleanup Report..."
if [[ -f /usr/local/bin/timeshift_cleanup_cron.sh ]]; then
    sudo chmod +x /usr/local/bin/timeshift_cleanup_cron.sh
    sudo /usr/local/bin/timeshift_cleanup_cron.sh
    cecho $GREEN "Timeshift Cleanup Report generated successfully. Check email: loganathr20@gmail.com"
else
    cecho $RED "Error: /usr/local/bin/timeshift_cleanup_cron.sh not found!"
fi


# =============================
# Final message and pause
# =============================
cecho $CYAN "\nAll tasks completed."
read -p "Press Enter to exit..." 


