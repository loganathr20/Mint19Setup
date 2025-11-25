
sudo systemctl daemon-reload
sudo systemctl enable --now new_timeshift-8h.timer
sudo systemctl enable --now new_timeshift-boot.timer
sudo systemctl enable --now timeshift-cleanup.timer
sudo systemctl daemon-reload

