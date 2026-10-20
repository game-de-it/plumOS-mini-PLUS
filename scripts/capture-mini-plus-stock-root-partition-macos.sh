#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DISK="${1:-}"
OUT="${2:-$ROOT_DIR/artifacts/vendor/mini-plus-stock-source/stock-root-p2.ext4}"
EXPECTED_DISK_SIZE=124383133696
EXPECTED_P2_SIZE=2999975936

case "$DISK" in
    /dev/disk[0-9]*) ;;
    *)
        printf 'usage: %s /dev/diskN [output.ext4]\n' "$0" >&2
        exit 2
        ;;
esac

[ ! -e "$OUT" ] || {
    printf 'error: refusing to overwrite existing file: %s\n' "$OUT" >&2
    exit 1
}

INFO="$(diskutil info "$DISK")"
printf '%s\n' "$INFO" | grep -q 'Whole:.*Yes' || {
    printf 'error: target is not a whole disk: %s\n' "$DISK" >&2
    exit 1
}
printf '%s\n' "$INFO" | grep -q 'Removable Media:.*Removable' || {
    printf 'error: target is not removable media: %s\n' "$DISK" >&2
    exit 1
}
printf '%s\n' "$INFO" | grep -q 'Protocol:.*Secure Digital' || {
    printf 'error: target is not Secure Digital media: %s\n' "$DISK" >&2
    exit 1
}
printf '%s\n' "$INFO" | grep -q "Disk Size:.*($EXPECTED_DISK_SIZE Bytes)" || {
    printf 'error: target size does not match the observed mini PLUS OS SD\n' >&2
    exit 1
}

P2_INFO="$(diskutil info "${DISK}s2")"
printf '%s\n' "$P2_INFO" | grep -q 'Partition Type:.*Linux' || {
    printf 'error: p2 is not the observed Linux partition\n' >&2
    exit 1
}
printf '%s\n' "$P2_INFO" | grep -q "Disk Size:.*($EXPECTED_P2_SIZE Bytes)" || {
    printf 'error: p2 size does not match the observed mini PLUS root partition\n' >&2
    exit 1
}

mkdir -p "$(dirname -- "$OUT")"
TMP_OUT="$(mktemp "${OUT}.tmp.XXXXXX")"
RAW_PARTITION="/dev/r${DISK#/dev/}s2"
cleanup() {
    unlink "$TMP_OUT" 2>/dev/null || true
    diskutil mount readOnly "${DISK}s1" >/dev/null 2>&1 || true
}
trap cleanup EXIT

diskutil unmountDisk "$DISK" >/dev/null
printf 'Reading %s into a local analysis image; no SD-card write is performed.\n' \
    "$RAW_PARTITION"
sudo dd if="$RAW_PARTITION" of="$TMP_OUT" bs=4194304
sudo chown "$(id -u):$(id -g)" "$TMP_OUT"
[ "$(stat -f '%z' "$TMP_OUT")" -eq "$EXPECTED_P2_SIZE" ]
mv "$TMP_OUT" "$OUT"
shasum -a 256 "$OUT"
printf 'created: %s\n' "$OUT"
