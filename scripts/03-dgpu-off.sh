#!/bin/bash
# Step 3: switch the AMD dGPU off at every boot, plus dgpu-on/off/status aliases.
source "$(dirname "$0")/common.sh"
put 644 etc/systemd/system/amdgpu-off.service
sudo systemctl daemon-reload
sudo systemctl enable amdgpu-off.service

if ! grep -q '^# dGPU management (t2linux)$' ~/.bashrc 2>/dev/null; then
    echo "  add dgpu-* aliases to ~/.bashrc"
    cat >> ~/.bashrc <<'ALIASES'

# dGPU management (t2linux)
alias dgpu-off='sudo systemctl enable amdgpu-off.service; sleep 2; sudo reboot'
alias dgpu-on='sudo systemctl disable amdgpu-off.service; sleep 2; sudo reboot'
alias dgpu-status='sudo cat /sys/kernel/debug/vgaswitcheroo/switch'
ALIASES
fi
echo "Done. dGPU goes off from the next boot; check with dgpu-status (DIS: :Off)."
