#!/bin/bash
# Step 1: use the Intel iGPU for the display (apple_gmux force_igd=1).
source "$(dirname "$0")/common.sh"
put 644 etc/modprobe.d/apple-gmux.conf
rebuild_initramfs
echo "Done. Takes effect after reboot."
