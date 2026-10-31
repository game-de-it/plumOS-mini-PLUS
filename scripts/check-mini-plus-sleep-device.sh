#!/bin/sh
# Run only after the supervisor hold is installed and the FE has fully exited.
# All launchers use a save/config sandbox supplied by the host harness.
set -eu
R=/storage/plumos
BASE=/storage/plumos/state/device-matrix/maintenance-20261031
profile=$1
content=$2
log=$BASE/$profile.log
export PLUMOS_ROOT=$R PLUMOS_ROM_ROOT=/storage
export PLUMOS_BIOS_ROOT=/storage/user/BIOS
export PLUMOS_SDCARD_ROOT=/run/media/sd2
export PLUMOS_PICOARCH_SYSTEM=gb PLUMOS_PICOARCH_CPU_POLICY=ondemand
mkdir -p "$BASE"
for p in /proc/[0-9]*; do
    for f in "$p"/fd/*; do
        target=$(readlink "$f" 2>/dev/null || true)
        case "$target" in /dev/fb0|/dev/dri/card*|/dev/mali*)
            echo "refuse_busy_display pid=${p##*/} device=$target" >&2
            exit 1 ;;
        esac
    done
done
case "$profile" in
    ra) set -- /bin/busybox sh "$R/bin/plumos-retroarch-launch" --system gb \
        --core "$R/cores/gambatte_libretro.so" --rom "$content" --safe-exit false ;;
    pico) set -- /bin/busybox sh "$R/bin/plumos-picoarch-launch" gambatte "$content" ;;
    gles) set -- /bin/busybox sh "$R/bin/plumos-retroarch-launch" --system n64 \
        --core "$R/cores/mupen64plus_next_libretro.so" --rom "$content" --safe-exit false ;;
    standalone) set -- /bin/busybox sh "$R/bin/plumos-standalone-launch" ppsspp "$content" ;;
    *) exit 2 ;;
esac
LD_LIBRARY_PATH="$R/frontend/lib" /bin/busybox setsid "$R/bin/plumos-drm-broker-run" \
    --library "$R/frontend/lib/libplumos-drm-share.so" -- "$@" >"$log" 2>&1 &
group=$!
cleanup() {
    /bin/busybox kill -TERM "-$group" 2>/dev/null || true
    /bin/busybox kill -CONT "-$group" 2>/dev/null || true
    attempt=0
    while kill -0 "$group" 2>/dev/null && [ "$attempt" -lt 30 ]; do
        /bin/busybox usleep 100000
        attempt=$((attempt + 1))
    done
    /bin/busybox kill -KILL "-$group" 2>/dev/null || true
    wait "$group" 2>/dev/null || true
}
trap cleanup EXIT
sleep 8
kill -0 "$group"
probe() {
    phase=$1
    LD_LIBRARY_PATH="$R/frontend/lib" /tmp/probe-mini-plus-drm-properties \
        >"$BASE/$profile.$phase.drm"
    cat /proc/asound/card0/pcm0p/sub0/status >"$BASE/$profile.$phase.audio1" 2>&1 || true
    sleep 1
    cat /proc/asound/card0/pcm0p/sub0/status >"$BASE/$profile.$phase.audio2" 2>&1 || true
}
probe before
PLUMOS_POWER_MENU_OVERLAY_UI=/tmp/mini-plus-sleep-auto-ui \
PLUMOS_POWER_MENU_SAFE_SHUTDOWN=/tmp/mini-plus-sleep-auto-safe \
    /bin/busybox sh "$R/bin/plumos-power-menu-overlay" >>"$log" 2>&1
sleep 3
kill -0 "$group"
probe after
printf 'sleep_device_case=complete profile=%s group=%s\n' "$profile" "$group"
