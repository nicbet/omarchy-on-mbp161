#!/bin/bash
# Step 2: stable /dev/dri/intel-igpu and /dev/dri/amd-dgpu names, and tell Hyprland to use them.
source "$(dirname "$0")/common.sh"
put 644 etc/udev/rules.d/70-intel-igpu.rules
put 644 etc/udev/rules.d/71-amd-gpu.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=drm --action=change

ENV=~/.config/uwsm/env-hyprland
LINE='export AQ_DRM_DEVICES=/dev/dri/intel-igpu:/dev/dri/amd-dgpu'
mkdir -p "$(dirname "$ENV")"
if ! grep -qxF "$LINE" "$ENV" 2>/dev/null; then
    echo "  append AQ_DRM_DEVICES to $ENV"
    echo "$LINE" >> "$ENV"
fi
echo "Done. Takes effect after logging out or rebooting."
