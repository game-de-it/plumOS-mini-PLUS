#!/usr/bin/env bash
set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
target=${PLUMOS_MINI_PLUS_SSH_TARGET:-root@192.168.10.101}
password=${PLUMOS_MINI_PLUS_SSH_PASSWORD:-plumos}
out="$root_dir/artifacts/vendor/mini-plus-stock-source/runtime-live"

[ "${PLUMOS_MINI_PLUS_CAPTURE_VENDOR:-0}" = 1 ] || {
    printf '%s\n' \
        'error: this creates ignored private vendor captures' \
        'set PLUMOS_MINI_PLUS_CAPTURE_VENDOR=1 after confirming the stock source device' >&2
    exit 1
}

known_hosts=$(mktemp)
trap 'rm -f "$known_hosts"' EXIT
ssh_opts=(
    -o PreferredAuthentications=password,keyboard-interactive
    -o PubkeyAuthentication=no
    -o NumberOfPasswordPrompts=1
    -o ConnectTimeout=8
    -o StrictHostKeyChecking=accept-new
    -o UserKnownHostsFile="$known_hosts"
)
remote() { sshpass -p "$password" ssh "${ssh_opts[@]}" "$target" "$@"; }
copy() { sshpass -p "$password" scp "${ssh_opts[@]}" "$target:$1" "$2"; }
copy_stream() { remote "cat '$1'" >"$2"; }

identity=$(remote 'printf "%s|" "$(uname -r)"; cat /etc/os-release 2>/dev/null')
case "$identity" in
    4.19.193-g5a07852a55cf-dirty*MINIPLUS*|4.19.193-g5a07852a55cf-dirty*BBG*) ;;
    *) printf 'error: unexpected mini PLUS source identity: %s\n' "$identity" >&2; exit 1 ;;
esac

mkdir -p \
    "$out/gpu" \
    "$out/modules" \
    "$out/firmware/rtl_bt" \
    "$out/firmware/wifi" \
    "$out/firmware/bluetooth"
copy_stream /proc/config.gz "$out/config.gz"
copy_stream /sys/firmware/fdt "$out/runtime.dtb"
copy /usr/lib/libmali.so.1.9.0 "$out/gpu/libmali-aarch64.so.1.9.0"
armhf=$(remote 'test -f /usr/lib32/libmali.so.1.9.0 && printf %s /usr/lib32/libmali.so.1.9.0')
[ -n "$armhf" ] || { printf 'error: ARMhf Mali runtime not found\n' >&2; exit 1; }
copy "$armhf" "$out/gpu/libmali-armhf.so.1.9.0"

for name in 8821cs.ko dwc3.ko udc-core.ko dwc3-of-simple.ko; do
    path=$(remote "find /usr/lib/kernel-overlays/base/lib/modules -type f -name '$name' 2>/dev/null | head -n1")
    [ -n "$path" ] || { printf 'error: stock module not found: %s\n' "$name" >&2; exit 1; }
    copy "$path" "$out/modules/$name"
done
for name in rtl8821cs_config.bin rtl8821cs_fw.bin; do
    path=$(remote "find /usr/lib/kernel-overlays/base/lib/firmware/rtl_bt -type f -name '$name' 2>/dev/null | head -n1")
    [ -n "$path" ] || { printf 'error: stock firmware not found: %s\n' "$name" >&2; exit 1; }
    copy "$path" "$out/firmware/rtl_bt/$name"
done

# Do not infer the internal Wi-Fi chip from similarly named files in SYSTEM.
# Resolve the driver that is bound to the live SDIO device, then retain the
# exact firmware/NVRAM paths selected by that driver at interface bring-up.
sdio_id=$(remote 'cat /sys/bus/sdio/devices/*/uevent 2>/dev/null | sed -n "s/^SDIO_ID=//p" | sort -u | tr "\n" ","')
sdio_driver=$(remote 'for d in /sys/bus/sdio/devices/*; do basename "$(readlink -f "$d/driver")"; break; done')
live_module=$(remote 'grep "^bcmdhd " /proc/modules | cut -d" " -f1')
case "$sdio_id|$sdio_driver|$live_module" in
    *02D0:A9A6*'|bcmsdh_sdmmc|bcmdhd') ;;
    *)
        printf 'error: unexpected live Wi-Fi binding: id=%s driver=%s module=%s\n' \
            "$sdio_id" "$sdio_driver" "$live_module" >&2
        exit 1
        ;;
esac

module_path=$(remote "readlink -f \"\$(modinfo -n '$live_module')\"")
copy "$module_path" "$out/modules/$live_module.ko"

firmware_path=$(remote 'dmesg | sed -n "s/.*Final fw_path=\([^ ]*\).*/\1/p" | tail -n1')
nvram_path=$(remote 'dmesg | sed -n "s/.*Final nv_path=\([^ ]*\).*/\1/p" | tail -n1')
for path in "$firmware_path" "$nvram_path"; do
    [ -n "$path" ] || { printf 'error: live Wi-Fi payload path was not found\n' >&2; exit 1; }
    copy "$path" "$out/firmware/wifi/$(basename "$path")"
done

for name in regulatory.db regulatory.db.p7s; do
    path=$(remote "readlink -f '/etc/firmware/$name'")
    [ -f "$out/firmware/wifi/$name" ] || copy "$path" "$out/firmware/wifi/$name"
done

bt_path=$(remote "readlink -f '/etc/firmware/bcm43438a1.hcd'")
copy "$bt_path" "$out/firmware/bluetooth/bcm43438a1.hcd"

remote 'printf "kernel_release\t%s\n" "$(uname -r)"; printf "sdio_id\t%s\n" "$(cat /sys/bus/sdio/devices/*/uevent 2>/dev/null | sed -n "s/^SDIO_ID=//p" | sort -u | tr "\n" ",")"; for d in /sys/bus/sdio/devices/*; do printf "sdio_driver\t%s\n" "$(basename "$(readlink -f "$d/driver")")"; break; done; modinfo bcmdhd | sed -n "/^\(filename\|srcversion\|alias\|vermagic\):/p"' >"$out/wifi-live.tsv"

remote 'find /usr/lib/kernel-overlays/base/lib/modules -type f -print0 | sort -z | xargs -0 sha256sum | while read -r hash path; do size=$(stat -c %s "$path"); printf "%s\t%s\t%s\n" "$hash" "$size" "$path"; done' >"$out/modules-all.tsv"
remote 'find /usr/lib/kernel-overlays/base/lib/firmware -type f -print0 | sort -z | xargs -0 sha256sum | while read -r hash path; do size=$(stat -c %s "$path"); printf "%s\t%s\t%s\n" "$hash" "$size" "$path"; done' >"$out/firmware-all.tsv"

while read -r expected relative; do
    case "$expected" in ''|'#'*) continue ;; esac
    [ -f "$out/$relative" ] || continue
    actual=$(sha256sum "$out/$relative" | awk '{print $1}')
    [ "$actual" = "$expected" ] || {
        printf 'error: live capture hash mismatch: %s\n' "$relative" >&2
        exit 1
    }
done < "$root_dir/configs/mini-plus-stock-runtime.expected.sha256"
printf 'miniplus_vendor_capture=result-ok target=%s output=%s\n' "$target" "$out"
