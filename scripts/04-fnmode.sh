#!/bin/bash
# Step 4: swap Touch Bar media / F-keys (hid_apple fnmode=1).
source "$(dirname "$0")/common.sh"
put 644 etc/modprobe.d/hid_apple.conf
rebuild_initramfs
echo "Done. Takes effect after reboot."
