#!/bin/bash
# Apply every step in order, rebuilding the initramfs only once.
source "$(dirname "$0")/common.sh"
cd "$(dirname "$0")"
sudo -v
export SKIP_MKINITCPIO=1
for s in 0[1-8]-*.sh; do
    echo "== $s"
    "./$s"
done
sudo mkinitcpio -P
echo "All steps applied. Reboot now."
