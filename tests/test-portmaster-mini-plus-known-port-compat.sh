#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HELPER="$ROOT_DIR/package/portmaster-mini-plus/plumos/bin/plumos-portmaster-known-port-compat"
work="$(mktemp -d /tmp/plumos-known-port-compat-test.XXXXXX)"
trap 'rm -rf "$work"' EXIT
port_root="$work/ports"
state_root="$work/state"
mkdir -p "$port_root/apotris" "$state_root/compat/apotris"
printf '#!/bin/sh\n' >"$port_root/Apotris.sh"
printf 'bad-version\n' >"$port_root/apotris/Apotris.aarch64"
printf 'good-version\n' >"$state_root/compat/apotris/Apotris-v4.1.0.aarch64"
bad_sha="$(sha256sum "$port_root/apotris/Apotris.aarch64" | awk '{print $1}')"
good_sha="$(sha256sum "$state_root/compat/apotris/Apotris-v4.1.0.aarch64" | awk '{print $1}')"

cat >"$work/mount" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FAKE_MOUNT_LOG"
EOF
chmod 0755 "$work/mount"

FAKE_MOUNT_LOG="$work/mount.log" \
PLUMOS_PORTMASTER_STATE_ROOT="$state_root" \
PLUMOS_PORTMASTER_MOUNT_BIN="$work/mount" \
PLUMOS_PORTMASTER_APOTRIS_BAD_SHA256="$bad_sha" \
PLUMOS_PORTMASTER_APOTRIS_FALLBACK_SHA256="$good_sha" \
    "$HELPER" "$port_root/Apotris.sh" "$work/mounts" >"$work/result.log"
grep -q 'action=bind-fallback from=4.2.0 to=4.1.0' "$work/result.log"
grep -Fqx -- "--bind $state_root/compat/apotris/Apotris-v4.1.0.aarch64 $port_root/apotris/Apotris.aarch64" "$work/mount.log"
grep -Fqx "$port_root/apotris/Apotris.aarch64" "$work/mounts"

cp "$state_root/compat/apotris/Apotris-v4.1.0.aarch64" \
    "$port_root/apotris/Apotris.aarch64"
FAKE_MOUNT_LOG="$work/direct-mount.log" \
PLUMOS_PORTMASTER_STATE_ROOT="$state_root" \
PLUMOS_PORTMASTER_MOUNT_BIN="$work/mount" \
PLUMOS_PORTMASTER_APOTRIS_BAD_SHA256="$bad_sha" \
PLUMOS_PORTMASTER_APOTRIS_FALLBACK_SHA256="$good_sha" \
    "$HELPER" "$port_root/Apotris.sh" "$work/direct-mounts" >"$work/direct.log"
grep -q 'action=direct version=4.1.0' "$work/direct.log"
[ ! -e "$work/direct-mount.log" ]
[ ! -e "$work/direct-mounts" ]

printf 'bad-version\n' >"$port_root/apotris/Apotris.aarch64"
mv "$state_root/compat/apotris/Apotris-v4.1.0.aarch64" "$work/fallback-away"
if PLUMOS_PORTMASTER_STATE_ROOT="$state_root" \
   PLUMOS_PORTMASTER_MOUNT_BIN="$work/mount" \
   PLUMOS_PORTMASTER_APOTRIS_BAD_SHA256="$bad_sha" \
   PLUMOS_PORTMASTER_APOTRIS_FALLBACK_SHA256="$good_sha" \
      "$HELPER" "$port_root/Apotris.sh" "$work/missing-mounts" \
      >"$work/missing.log" 2>&1; then
    printf 'known-port compatibility accepted a missing Apotris fallback\n' >&2
    exit 1
fi
grep -q 'verified fallback is missing' "$work/missing.log"

printf 'future-version\n' >"$port_root/apotris/Apotris.aarch64"
PLUMOS_PORTMASTER_STATE_ROOT="$state_root" \
PLUMOS_PORTMASTER_MOUNT_BIN="$work/mount" \
PLUMOS_PORTMASTER_APOTRIS_BAD_SHA256="$bad_sha" \
PLUMOS_PORTMASTER_APOTRIS_FALLBACK_SHA256="$good_sha" \
    "$HELPER" "$port_root/Apotris.sh" "$work/unknown-mounts" >"$work/unknown.log"
grep -q 'action=unmanaged' "$work/unknown.log"
[ ! -e "$work/unknown-mounts" ]

printf 'portmaster_miniplus_known_port_compat=result-ok bad_v42=blocked v41=direct fallback=verified-bind unknown=unmodified\n'
