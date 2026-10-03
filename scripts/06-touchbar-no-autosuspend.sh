#!/bin/bash
# Step 6: never runtime-suspend the Touch Bar (prevents the hid_appletb_kbd deadlock).
source "$(dirname "$0")/common.sh"
put 644 etc/udev/rules.d/90-touchbar-no-autosuspend.rules
sudo udevadm control --reload-rules
# Apply to the running system too.
for d in /sys/bus/usb/devices/*; do
    [[ "$(cat "$d/idVendor" 2>/dev/null)" == 05ac && "$(cat "$d/idProduct" 2>/dev/null)" == 8302 ]] || continue
    echo on | sudo tee "$d/power/control" >/dev/null
    echo "  Touch Bar $(basename "$d"): power/control=on"
done
echo "Done. Active now."
