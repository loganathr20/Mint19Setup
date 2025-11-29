#!/bin/bash
clear

# Reload systemd
sudo systemctl daemon-reload

# Enable timers
sudo systemctl enable --now new_timeshift-8h.timer
sudo systemctl enable --now new_timeshift-boot.timer
sudo systemctl enable --now timeshift-cleanup.timer

# Reload again (not required but okay)
sudo systemctl daemon-reload

# Print blank lines
echo -e "\n\n\n"

# List matching timers
sudo systemctl list-timers --all | grep -E "cinnamon|timeshift"

echo -e "\n\n\n"

# Wait for user input
read -p "Press Enter to continue..." temp



