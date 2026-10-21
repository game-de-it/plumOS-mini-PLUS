#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mode=${1:-}
mount_point=${2:-/Volumes/PLUMBOOT}
kernel_version=4.19.193-51-rockchip-gb2c01b3d79f2
base_dtb_rel=dtbs/$kernel_version/rockchip/rk3566-gkdmini-pro.dtb
base_dtb=$mount_point/$base_dtb_rel
uenv=$mount_point/uEnv.txt
overlay_name=mini-plus-sd1-sdr104
overlay_rel=overlay-user/$overlay_name.dtbo
overlay=$mount_point/$overlay_rel
card_backup=$mount_point/plumos-probe/sd1-sdr104-backup
expected_base_dtb=8e864607d2188d98fdcbc4f3ee961628585c7f7d5c2b10d77a45fee795407781
backup_root=${PLUMOS_MINI_PLUS_SDR104_BACKUP_ROOT:-$repo_root/artifacts/hardware}

usage() {
    echo "usage: $0 --inspect|--apply|--rollback [PLUMBOOT mount point]" >&2
    exit 2
}

sha256_file() {
    shasum -a 256 "$1" | awk '{print $1}'
}

require_card() {
    [ -d "$mount_point" ] || { echo "missing mount point: $mount_point" >&2; exit 2; }
    [ -f "$uenv" ] || { echo "missing uEnv.txt: $uenv" >&2; exit 2; }
    [ -f "$base_dtb" ] || { echo "missing active DTB: $base_dtb" >&2; exit 2; }
    [ "$(sha256_file "$base_dtb")" = "$expected_base_dtb" ] || {
        echo "refusing unrecognized active mini PLUS DTB" >&2
        exit 2
    }
    grep -qx 'fdtfile=rockchip/rk3566-gkdmini-pro.dtb' "$uenv" || {
        echo "refusing unexpected fdtfile in $uenv" >&2
        exit 2
    }
    grep -qx "kernelversion=$kernel_version" "$uenv" || {
        echo "refusing unexpected kernelversion in $uenv" >&2
        exit 2
    }
}

compile_overlay() {
    command -v dtc >/dev/null 2>&1 || {
        echo 'missing dtc; install with: brew install dtc' >&2
        exit 2
    }
    dtc -@ -I dts -O dtb \
        -o "$work/$overlay_name.dtbo" \
        "$repo_root/configs/device-tree/$overlay_name-overlay.dts"
    test "$(fdtget -t s "$work/$overlay_name.dtbo" /fragment@0 target-path)" = \
        /dwmmc@fe2b0000
    fdtget -p "$work/$overlay_name.dtbo" /fragment@0/__overlay__ | \
        grep -qx sd-uhs-sdr104
}

inspect() {
    require_card
    echo "mount_point=$mount_point"
    echo "base_dtb_sha256=$(sha256_file "$base_dtb")"
    if grep -qx "user_overlays=$overlay_name" "$uenv" && [ -f "$overlay" ]; then
        echo 'sd1_sdr104_test=enabled'
        echo "overlay_sha256=$(sha256_file "$overlay")"
    else
        echo 'sd1_sdr104_test=disabled'
    fi
}

apply_test() {
    require_card
    if grep -q '^user_overlays=' "$uenv" && \
        ! grep -qx "user_overlays=$overlay_name" "$uenv"; then
        echo 'refusing to replace an existing user_overlays setting' >&2
        exit 2
    fi
    if [ -e "$card_backup/uEnv.txt" ]; then
        echo "refusing to overwrite existing rollback backup: $card_backup" >&2
        exit 2
    fi

    work=$(mktemp -d "${TMPDIR:-/tmp}/plumos-mini-plus-sdr104.XXXXXX")
    trap 'find "$work" -depth -delete 2>/dev/null || true' EXIT HUP INT TERM
    compile_overlay

    host_backup=$backup_root/mini-plus-sd1-sdr104-$(date -u +%Y%m%dT%H%M%SZ)
    mkdir -p "$host_backup" "$card_backup" "$mount_point/overlay-user"
    cp "$uenv" "$host_backup/uEnv.txt"
    cp "$base_dtb" "$host_backup/rk3566-gkdmini-pro.dtb"
    cp "$uenv" "$card_backup/uEnv.txt"
    cp "$base_dtb" "$card_backup/rk3566-gkdmini-pro.dtb"
    {
        printf '%s  %s\n' "$(sha256_file "$uenv")" uEnv.txt
        printf '%s  %s\n' "$(sha256_file "$base_dtb")" rk3566-gkdmini-pro.dtb
    } > "$host_backup/checksums.sha256"
    cp "$host_backup/checksums.sha256" "$card_backup/checksums.sha256"

    cp "$work/$overlay_name.dtbo" "$overlay.tmp"
    mv "$overlay.tmp" "$overlay"
    awk -v value="user_overlays=$overlay_name" '
        !/^user_overlays=/ { print }
        END { print value }
    ' "$uenv" > "$work/uEnv.txt"
    cp "$work/uEnv.txt" "$uenv.tmp"
    mv "$uenv.tmp" "$uenv"
    sync

    grep -qx "user_overlays=$overlay_name" "$uenv"
    cmp "$work/$overlay_name.dtbo" "$overlay"
    echo "sd1_sdr104_test=applied"
    echo "mount_point=$mount_point"
    echo "host_backup=$host_backup"
    echo "card_backup=$card_backup"
    echo "overlay_sha256=$(sha256_file "$overlay")"
    echo 'next=unmount the card, cold boot, then verify SDR104 and filesystem integrity over SSH'
}

rollback() {
    require_card
    [ -f "$card_backup/uEnv.txt" ] || {
        echo "missing rollback backup: $card_backup/uEnv.txt" >&2
        exit 2
    }
    (cd "$card_backup" && shasum -a 256 -c checksums.sha256)
    [ "$(sha256_file "$card_backup/rk3566-gkdmini-pro.dtb")" = "$expected_base_dtb" ]
    cp "$card_backup/uEnv.txt" "$uenv.tmp"
    mv "$uenv.tmp" "$uenv"
    [ ! -e "$overlay" ] || mv "$overlay" "$card_backup/$overlay_name.dtbo.disabled"
    sync
    ! grep -q '^user_overlays=' "$uenv"
    echo 'sd1_sdr104_test=rolled-back'
    echo "mount_point=$mount_point"
}

case "$mode" in
    --inspect) inspect ;;
    --apply) apply_test ;;
    --rollback) rollback ;;
    *) usage ;;
esac
