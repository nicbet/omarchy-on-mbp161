# Sourced by every step script. Run the steps as your normal user; they call sudo.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not with sudo (it calls sudo itself)." >&2
    exit 1
fi

FILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../files" && pwd)"

# put <mode> <system path>: install files/<path> to /<path>
put() {
    echo "  install /$2"
    sudo install -m "$1" -D "$FILES/$2" "/$2"
}

# Rebuild the initramfs so modprobe options apply early. all.sh sets
# SKIP_MKINITCPIO=1 and runs it once at the end instead.
rebuild_initramfs() {
    [[ "${SKIP_MKINITCPIO:-}" == 1 ]] || sudo mkinitcpio -P
}
