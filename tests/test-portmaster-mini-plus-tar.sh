#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SHIM="$ROOT_DIR/package/portmaster-mini-plus/plumos/apps/portmaster/adapter/shims/tar"

run_test() {
    work="$(mktemp -d /tmp/plumos-tar-test.XXXXXX)"
    trap 'rm -rf "$work"' EXIT
    mkdir -p "$work/source" "$work/output"
    printf 'mini PLUS PortMaster xz compatibility\n' >"$work/source/payload.txt"
    tar -C "$work/source" -cf "$work/payload.tar" payload.txt
    xz -z "$work/payload.tar"
    PLUMOS_BUSYBOX=/bin/busybox "$SHIM" -C "$work/output" -xf "$work/payload.tar.xz"
    cmp "$work/source/payload.txt" "$work/output/payload.txt"
}

if [[ "$(uname -s)" == Darwin ]]; then
    docker run --rm -v "$ROOT_DIR:/repo:ro" plumos-mini-plus-tools:dev \
        /repo/tests/test-portmaster-mini-plus-tar.sh
else
    run_test
fi

printf 'portmaster_miniplus_tar=result-ok\n'
