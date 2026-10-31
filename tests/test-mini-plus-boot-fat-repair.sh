#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ "${1:-}" != --inside ]; then
    exec docker run --rm --platform linux/arm64 -v "$repo:/work:ro" -w /work \
        "${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}" \
        sh tests/test-mini-plus-boot-fat-repair.sh --inside
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
image=$work/boot.fat
truncate -s 64M "$image"
mkfs.fat -F 32 "$image" >/dev/null
python3 - "$image" <<'PY'
import struct,sys
with open(sys.argv[1],'r+b') as f:
    boot=f.read(512)
    sector=struct.unpack_from('<H',boot,11)[0]
    reserved=struct.unpack_from('<H',boot,14)[0]
    fats=boot[16]
    size=struct.unpack_from('<I',boot,36)[0]
    for index in range(fats):
        f.seek((reserved+index*size)*sector+42*4)
        f.write(struct.pack('<I',0x0fffffff))
PY
helper=/work/rootfs/mini-plus-external-initramfs/usr/sbin/plumos-mini-plus-check-boot-fat
if sh "$helper" "$image" >/dev/null 2>&1; then exit 1; fi
status=0
PLUMOS_BOOT_FAT_REPAIR_AUTHORIZED=yes sh "$helper" proc >"$work/mounted.log" 2>&1 || status=$?
[ "$status" -eq 2 ]
grep -q 'reason=mounted' "$work/mounted.log"
PLUMOS_BOOT_FAT_REPAIR_AUTHORIZED=yes sh "$helper" "$image" >"$work/repair.log"
grep -q 'plumos-boot-fat=result-ok' "$work/repair.log"
fsck.fat -n "$image" >/dev/null
echo 'miniplus_boot_fat_repair=result-ok explicit_authorization=yes orphan_repaired=yes'
