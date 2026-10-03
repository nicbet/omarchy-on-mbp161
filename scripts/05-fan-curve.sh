#!/bin/bash
# Step 5: quieter fan curve (70–90 °C instead of Omarchy's 55–75 °C).
source "$(dirname "$0")/common.sh"
put 644 etc/t2fand.conf
sudo systemctl restart t2fanrd
echo "Done. Active now."
