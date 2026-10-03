#!/bin/bash
# Step 7: install tb-on / tb-off to wake the USB-C ports when needed.
source "$(dirname "$0")/common.sh"
put 755 usr/local/bin/tb-on
put 755 usr/local/bin/tb-off
echo "Done. Use: sudo tb-on (then plug in), sudo tb-off when finished."
