#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE="$ROOT_DIR/package/portmaster-mini-plus/src/plumos_portmaster_hw_compat.c"

if [[ "$(uname -s)" == Darwin ]]; then
    command -v docker >/dev/null 2>&1 || {
        echo 'Docker is required to exercise the Linux hardware shim on macOS' >&2
        exit 1
    }
    exec docker run --rm --platform linux/arm64 \
        -v "$ROOT_DIR:/repo:ro" \
        plumos-mini-plus-tools:dev \
        /repo/tests/test-portmaster-mini-plus-hw-compat.sh
fi

work="$(mktemp -d /tmp/plumos-hw-compat-test.XXXXXX)"
trap 'rm -rf "$work"' EXIT
compat_root="$work/compat"
sysfs_root="$work/sysfs"
mkdir -p "$compat_root" "$sysfs_root/pwmchip0/pwm0"
printf '0\n' >"$compat_root/pwmchip0-duty_cycle"
printf '0\n' >"$compat_root/pwmchip1-duty_cycle"
printf 'real\n' >"$sysfs_root/pwmchip0/pwm0/duty_cycle"

cc -O2 -fPIC -Wall -Wextra -Werror -shared -Wl,-z,defs \
    -Wl,-soname,libplumos-portmaster-hw-compat.so \
    -o "$work/libplumos-portmaster-hw-compat.so" "$SOURCE" -ldl
cat >"$work/write-path.c" <<'EOF'
#include <stdio.h>

int main(int argc, char **argv) {
    FILE *output;
    if (argc != 3)
        return 64;
    output = fopen(argv[1], "w");
    if (!output)
        return 2;
    if (fputs(argv[2], output) < 0 || fclose(output) != 0)
        return 3;
    return 0;
}
EOF
cc -O2 -Wall -Wextra -Werror -o "$work/write-path" "$work/write-path.c"

PLUMOS_PORTMASTER_PWM_COMPAT_ROOT="$compat_root" \
PLUMOS_PORTMASTER_PWM_SYSFS_ROOT="$sysfs_root" \
LD_PRELOAD="$work/libplumos-portmaster-hw-compat.so" \
    "$work/write-path" "$sysfs_root/pwmchip1/pwm0/duty_cycle" virtual \
    2>"$work/redirect.log"
grep -qx virtual "$compat_root/pwmchip1-duty_cycle"
grep -q 'unavailable raw PWM redirected' "$work/redirect.log"

PLUMOS_PORTMASTER_PWM_COMPAT_ROOT="$compat_root" \
PLUMOS_PORTMASTER_PWM_SYSFS_ROOT="$sysfs_root" \
LD_PRELOAD="$work/libplumos-portmaster-hw-compat.so" \
    "$work/write-path" "$sysfs_root/pwmchip0/pwm0/duty_cycle" hardware
grep -qx hardware "$sysfs_root/pwmchip0/pwm0/duty_cycle"

if PLUMOS_PORTMASTER_PWM_COMPAT_ROOT="$compat_root" \
   PLUMOS_PORTMASTER_PWM_SYSFS_ROOT="$sysfs_root" \
   LD_PRELOAD="$work/libplumos-portmaster-hw-compat.so" \
      "$work/write-path" "$work/unrelated/missing" invalid 2>/dev/null; then
    printf 'hardware compatibility shim redirected an unrelated path\n' >&2
    exit 1
fi

printf 'portmaster_miniplus_hw_compat=result-ok real_pwm=preserved missing_pwm=no-op unrelated=preserved\n'
