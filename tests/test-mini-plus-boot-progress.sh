#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ "${1:-}" != --inside ]; then
    exec docker run --rm --platform linux/arm64 -v "$repo:/work:ro" -w /work \
        "${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}" \
        sh ./tests/test-mini-plus-boot-progress.sh --inside
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
export PLUMOS_PROGRESS_ROOT=$work PLUMOS_PROGRESS_FB=/dev/null
helper=/work/rootfs/mini-plus-external-initramfs/usr/sbin/plumos-mini-plus-boot-progress
dd if=/dev/zero of="$work/provision-start.raw" bs=1228800 count=1 status=none
sh "$helper" provision-start | grep -qx 'plumos-boot-progress=phase=provision-start result=written'
expect_failure() {
    expected=$1
    shift
    if sh "$helper" "$@" >"$work/log" 2>/dev/null; then
        echo 'progress unexpectedly succeeded' >&2
        exit 1
    fi
    grep -q "result=$expected" "$work/log"
}
PLUMOS_PROGRESS_FB=/dev/full expect_failure write-failed provision-start
PLUMOS_PROGRESS_FB="$work/missing" expect_failure framebuffer-unavailable provision-start
expect_failure invalid-frame provision-complete
# A footer from the old format must never be accepted as a complete frame.
truncate -s 368640 "$work/provision-start.raw"
expect_failure invalid-frame provision-start
if sh "$helper" ../provision-start >/dev/null 2>&1; then exit 1; fi
echo 'miniplus_boot_progress_test=result-ok'
