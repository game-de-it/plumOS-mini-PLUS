#!/bin/sh
set -eu
R=/storage/plumos
B=$R/state/device-matrix/maintenance-save-20261031
ROM=$R/state/device-matrix/content/rom2-20260904/gbc/Cross\ Hunter\ -\ X\ Hunter\ Version.gbc
export PLUMOS_ROOT=$R PLUMOS_ROM_ROOT=/storage PLUMOS_BIOS_ROOT=/storage/user/BIOS
mkdir -p "$B"
# This directory is bind-mounted to the fresh test sandbox by the host harness.
grep -Fq " $R/config/retroarch " /proc/mounts
for p in /proc/[0-9]*; do
    for f in "$p"/fd/*; do
        case $(readlink "$f" 2>/dev/null || true) in
            /dev/fb0|/dev/dri/card*|/dev/mali*) exit 1 ;;
        esac
    done
done
cat >"$B/control.cfg" <<'CONFIG'
stdin_cmd_enable = "true"
savestate_auto_load = "false"
savestate_auto_save = "false"
savestate_auto_index = "false"
state_slot = "0"
quit_press_twice = "false"
config_save_on_exit = "false"
audio_device = "plumos_output"
savefiles_in_content_dir = "false"
savestates_in_content_dir = "false"
savefile_directory = "/storage/plumos/saves"
savestate_directory = "/storage/plumos/states"
CONFIG
fifo=/run/plumos/validation/save-test-20261031.fifo
mkfifo "$fifo"
exec 3<>"$fifo"
group=
cleanup() {
    if [ -n "$group" ]; then
        /bin/busybox kill -TERM "-$group" 2>/dev/null || true
        /bin/busybox kill -CONT "-$group" 2>/dev/null || true
    fi
    exec 3>&-
    rm -f "$fifo"
}
trap cleanup EXIT
launch() {
    ALSA_CONFIG_PATH=/run/plumos/audio/asound.conf \
    LD_LIBRARY_PATH="$R/emulator/lib:$R/frontend/lib" /bin/busybox setsid \
        "$R/bin/plumos-drm-broker-run" --library "$R/frontend/lib/libplumos-drm-share.so" \
        -- /bin/busybox env LD_PRELOAD="$R/frontend/lib/libplumos-drm-share.so" \
        /tmp/with-nonblocking-stdin "$R/bin/retroarch" -v \
        -c "$R/config/retroarch/retroarch-mini-plus.cfg" \
        --appendconfig "$B/control.cfg" \
        -L "$R/cores/gambatte_libretro.so" "$ROM" \
        <&3 3>&- >"$B/$1.log" 2>&1 &
    group=$!
    sleep 6
    kill -0 "$group"
}
finish() {
    printf 'QUIT\n' >&3
    n=0
    while kill -0 "$group" 2>/dev/null && [ "$n" -lt 50 ]; do
        /bin/busybox usleep 100000
        n=$((n + 1))
    done
    if kill -0 "$group" 2>/dev/null; then return 1; fi
    wait "$group"
    group=
}
launch save
printf 'SAVE_STATE\n' >&3
sleep 3
find "$R/states" -type f -name '*.state' >"$B/state-paths.txt"
test -s "$B/state-paths.txt"
while IFS= read -r path; do test -s "$path"; sha256sum "$path"; done \
    <"$B/state-paths.txt" >"$B/state-before.sha256"
finish
find "$R/saves" -type f -name '*.srm' >"$B/sram-paths.txt"
test -s "$B/sram-paths.txt"
while IFS= read -r path; do test -s "$path"; sha256sum "$path"; done \
    <"$B/sram-paths.txt" >"$B/sram-before.sha256"
sync
launch load
sha256sum -c "$B/state-before.sha256"
sha256sum -c "$B/sram-before.sha256"
printf 'LOAD_STATE\n' >&3
sleep 3
finish
grep -E 'Loading state|Loaded state|Loaded SRAM' "$B/load.log" \
    >"$B/load-evidence.txt"
grep -q 'Loading state\|Loaded state' "$B/load-evidence.txt"
cat "$B/load-evidence.txt"
printf 'save_device_check=pass state=written-and-loaded sram=written-and-retained restart=new-process sandbox=yes\n'
