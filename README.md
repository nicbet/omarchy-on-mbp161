# Omarchy 4.0.4 on a MacBook Pro 16,1 (2019, 16")

What it takes to run Omarchy on this machine, and every change made on top of
a stock install.

- [`files/`](files/): exact copies of every changed file, laid out by their
  path on the system
- [`scripts/`](scripts/): one script per step below, so you can apply only what
  you want. Run them as your normal user; they call `sudo` themselves. Each
  can be re-run safely.

Hardware: MacBookPro16,1, Intel i9 + UHD 630 iGPU, AMD Radeon Pro 5300M/5500M
dGPU (Navi 14), Apple T2, 6 speakers, Touch Bar, 2× Titan Ridge Thunderbolt 3.

## What Omarchy already does (no action needed)

The installer detects the T2 chip (`/usr/share/omarchy/install/hardware/apple/fix-t2.sh`)
and sets up:

- `linux-t2` kernel + headers, `apple-bcm-firmware` (Wi-Fi/BT),
  `apple-t2-audio-config`, `t2fanrd` (fan daemon, enabled)
- `t2bce_vhci` + `hci_bcm4377` loaded at boot; keyboard modules in the initramfs
- Kernel params: `intel_iommu=on iommu=pt pm_async=off mem_sleep_default=deep`
- `/etc/modprobe.d/brcmfmac.conf`: fixes Wi-Fi rejecting the correct WPA password
- `/etc/modprobe.d/omarchy-usb-autosuspend.conf`: `usbcore autosuspend=-1`
  (USB autosuspend off; see the powertop warning below)
- `/etc/t2fand.conf` with a 55–75 °C fan curve (changed below)
- PipeWire + WirePlumber 0.5 (all the speaker fix needs)

## Installing

1. Make a USB boot drive (download the ISO, write it with `caligula`).
2. Power on holding **Cmd+R** → Utilities → Startup Security Utility →
   Secure Boot: **No Security**, External Boot: **Allow**.
3. Power on holding **Option**, pick **EFI Boot**, run the Omarchy installer.
4. **First boot:** use an external keyboard. At the boot menu press `e`,
   append `apple_gmux.force_igd=1`, press `F10` (boots on the Intel iGPU
   instead of the AMD dGPU; made permanent in step 1 below).
5. Accept the Omarchy update when asked.
6. Apply the changes below: one at a time, or all of them with
   `scripts/all.sh`, then reboot.

## Changes on top of stock

| # | Change | Script |
|---|--------|--------|
| 1 | Use the iGPU for the display | `scripts/01-igpu.sh` |
| 2 | Stable GPU names for Hyprland | `scripts/02-gpu-names.sh` |
| 3 | Power the dGPU off at boot | `scripts/03-dgpu-off.sh` |
| 4 | Swap Touch Bar media / F-keys | `scripts/04-fnmode.sh` |
| 5 | Quieter fan curve | `scripts/05-fan-curve.sh` |
| 6 | Never autosuspend the Touch Bar | `scripts/06-touchbar-no-autosuspend.sh` |
| 7 | USB-C ports on demand (`tb-on` / `tb-off`) | `scripts/07-thunderbolt.sh` |
| 8 | Speaker crossover + EQ | `scripts/08-speakers.sh` |

### 1. Use the iGPU for the display

The `apple_gmux` mux defaults to the AMD dGPU. Force the Intel iGPU so the
first-boot parameter isn't needed any more.

`/etc/modprobe.d/apple-gmux.conf`
```
options apple_gmux force_igd=1
```
Script: `scripts/01-igpu.sh` (also rebuilds the initramfs). Reboot afterwards.

### 2. Stable GPU device names for Hyprland (70- and 71- rules)

`card0`/`card1` numbering isn't stable between boots, so give each GPU a fixed
alias and tell Hyprland (Aquamarine) to prefer the iGPU.

`/etc/udev/rules.d/70-intel-igpu.rules`
```
SUBSYSTEM=="drm", KERNEL=="card[0-9]*" KERNELS=="0000:00:02.0", SYMLINK+="dri/intel-igpu"
```

`/etc/udev/rules.d/71-amd-gpu.rules`
```
SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:03:00.0", SYMLINK+="dri/amd-dgpu"
```

`~/.config/uwsm/env-hyprland`
```
export AQ_DRM_DEVICES=/dev/dri/intel-igpu:/dev/dri/amd-dgpu
```
Script: `scripts/02-gpu-names.sh`. Log out or reboot afterwards.

### 3. Power the dGPU off at boot

Even unused, the dGPU draws power and floods the log with amdgpu errors
(50–120 per boot; down to ~6 with it off). A oneshot service
([`amdgpu-off.service`](files/etc/systemd/system/amdgpu-off.service)) switches it
off through vgaswitcheroo once its debugfs node appears.

The script also adds these aliases to `~/.bashrc` (both toggles reboot):
```bash
# dGPU management (t2linux)
alias dgpu-off='sudo systemctl enable amdgpu-off.service; sleep 2; sudo reboot'
alias dgpu-on='sudo systemctl disable amdgpu-off.service; sleep 2; sudo reboot'
alias dgpu-status='sudo cat /sys/kernel/debug/vgaswitcheroo/switch'
```
Script: `scripts/03-dgpu-off.sh`. After a reboot, `dgpu-status` should show `DIS: :Off`.

### 4. Swap Touch Bar media / F-keys

`/etc/modprobe.d/hid_apple.conf`
```
options hid_apple fnmode=1
```
Script: `scripts/04-fnmode.sh` (also rebuilds the initramfs). Reboot afterwards.

### 5. Quieter fan curve

Omarchy's 55–75 °C curve spins the fans up early. Apple lets this machine run
hot and quiet, so let it reach 85–90 °C first.

`/etc/t2fand.conf`
```ini
[Fan1]
low_temp=70
high_temp=90
speed_curve=linear
always_full_speed=false

[Fan2]
low_temp=70
high_temp=90
speed_curve=linear
always_full_speed=false
```
Script: `scripts/05-fan-curve.sh` (restarts `t2fanrd`, active immediately).

### 6. Never autosuspend the Touch Bar

If the Touch Bar (USB `05ac:8302` on the T2's virtual USB bus) is runtime-suspended,
`hid_appletb_kbd` deadlocks: tasks hang in `appletb_kbd_suspend`, and the
machine freezes and can't shut down. Omarchy's `autosuspend=-1` normally
prevents this; this rule makes sure the Touch Bar stays powered even if
something else turns autosuspend back on.

`/etc/udev/rules.d/90-touchbar-no-autosuspend.rules`
```
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", ATTR{idProduct}=="8302", ATTR{power/control}="on"
```
Script: `scripts/06-touchbar-no-autosuspend.sh` (also applies it to the running system).

### 7. USB-C / Thunderbolt ports: `tb-on` / `tb-off`

The Titan Ridge controllers (`8086:15ec`) stay runtime-suspended and don't wake
when a device is plugged in, so USB drives on the USB-C ports are not detected.
[`tb-on`](files/usr/local/bin/tb-on) wakes them and
[`tb-off`](files/usr/local/bin/tb-off) lets them sleep again. Turn them on
only when needed, since they draw power.

Script: `scripts/07-thunderbolt.sh` installs both to `/usr/local/bin`. Then:
```bash
sudo tb-on    # then plug in the device
sudo tb-off   # when done
```

### 8. Speakers

Out of the box the speakers work but sound thin and boxy ("5 euro headphones
in a bathtub"). All six drivers (2 tweeters, 4 woofers) get the same unfiltered
signal, with no crossover and no bass EQ; on macOS that's done by Apple's DSP.
This adds it back using only PipeWire's built-in biquad filters: no LV2 plugins,
no extra packages, no FIR `.wav` files. Added latency is about 20 ms.

What the filter graph does:
- Splits each channel at 2.2 kHz (4th-order crossover): lows go to the woofers,
  highs to the tweeters.
- Woofers: +18 dB at 75 Hz, +10 dB at 45 Hz, +8 dB low shelf at 250 Hz, and a
  28 Hz high-pass so the cones aren't pushed below what they can play.
- Tweeters: −3 dB at 3 kHz (takes the harshness out), +3 dB shelf above 5 kHz.
- Creates a new default output, **"MacBook Pro T2 DSP Speakers"**, and hides
  the raw 6-channel device.

Files:
- [`/etc/udev/rules.d/99-t2-audio-rename.rules`](files/etc/udev/rules.d/99-t2-audio-rename.rules):
  renames the ALSA card to `t2-16_1` so the config below can match it
- [`/usr/share/t2linux-audio/16_1/graph.json`](files/usr/share/t2linux-audio/16_1/graph.json):
  the crossover and EQ
- [`/etc/wireplumber/wireplumber.conf.d/50-t2-speakers.conf`](files/etc/wireplumber/wireplumber.conf.d/50-t2-speakers.conf):
  makes WirePlumber put the graph in front of the speakers (`node.software-dsp`)

Script: `scripts/08-speakers.sh` (restarts audio and lists the outputs).
"MacBook Pro T2 DSP Speakers" should be marked default (`*`) in
`wpctl status`. If it's missing, reboot once so the card gets renamed. If it's
there but not default: `wpctl set-default <id>`.

**Tuning:** all the sound lives in `graph.json`. Edit the `control` values
(`Freq`, `Q`, `Gain`) of both the `_L` and `_R` copies of a node, then
`sudo install -m 644 graph.json /usr/share/t2linux-audio/16_1/` and
`systemctl --user restart wireplumber pipewire pipewire-pulse`.

**Remove:**
```bash
sudo rm /etc/udev/rules.d/99-t2-audio-rename.rules \
        /etc/wireplumber/wireplumber.conf.d/50-t2-speakers.conf
sudo rm -r /usr/share/t2linux-audio
systemctl --user restart wireplumber pipewire pipewire-pulse
```

## Don't do this

- **powertop / `powertop --auto-tune`**: sets every USB device, including the
  Touch Bar and the other T2 devices, to autosuspend → Touch Bar deadlock and freezes
  (see 6). Same risk with TLP's USB autosuspend.
- **FIR convolution speaker DSP** (`t2-apple-audio-dsp` with `.wav` impulse
  responses, bankstown, lsp-plugins): sounds good but 100–500 ms lip-sync lag.
  A lower PipeWire quantum doesn't fix it.
- **CPU capping for battery** (turbo off, `max_perf_pct=60`): no clear gain.
- **`setpci` bus-master / udev rule for Thunderbolt**: wasn't the problem;
  runtime PM was (see 7).

## Known issues (not fixed)

- **Idle power ~12 W**, ~9 W with low brightness, even with the dGPU off.
- **Sleep/resume works but is slow** (several seconds).
- **T2 `bce_dma` driver bug**: `BUG: scheduling while atomic: irq/64-bce_dma`
  followed by soft lockups froze the machine twice on 2026-09-21 (kernel
  7.2.4-T2-3). Not seen since 7.2.7-T2-2. If it returns, report it to t2linux:
  `journalctl -b -1 -k | grep -A20 bce_dma`
- **Internal mic** is quiet and thin. `triforce` beamforming made it
  usable but still too quiet; the stock mic is left alone.
- **1Password** crashed with SIGILL on its very first launch right after
  install; it runs fine when relaunched.
