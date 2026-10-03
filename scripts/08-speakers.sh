#!/bin/bash
# Step 8: speaker crossover + EQ through PipeWire's built-in filters.
source "$(dirname "$0")/common.sh"
put 644 etc/udev/rules.d/99-t2-audio-rename.rules
put 644 usr/share/t2linux-audio/16_1/graph.json
put 644 etc/wireplumber/wireplumber.conf.d/50-t2-speakers.conf
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=sound --action=change

systemctl --user restart wireplumber pipewire pipewire-pulse
sleep 2
wpctl status | grep -A6 'Sinks:' || true
echo "Done. \"MacBook Pro T2 DSP Speakers\" should be the default (*). If it's missing, reboot once."
