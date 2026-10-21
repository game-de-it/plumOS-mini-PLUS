#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}
if [ "${1:-}" != --inside ]; then
    exec docker run --rm --platform linux/arm64 \
        -v "$repo_root:/work" -w /work "$image" \
        ./tests/test-mini-plus-volume-keys.sh --inside
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
root=$tmp/plumos
runtime=$tmp/run
mkdir -p "$root/bin" "$runtime/volume-keys"
gcc -std=gnu99 -Os -Wall -Wextra src/services/plumos_miniplus_volume_keys.c \
    -o "$root/bin/plumos-volume-keys"
cat >"$root/bin/plumos-volume-control" <<'EOF'
#!/bin/sh
printf '%s\n' "$1" >>"${TEST_VOLUME_TRACE:?}"
EOF
chmod 0755 "$root/bin/plumos-volume-control"
cat >"$root/bin/plumos-display-control" <<'EOF'
#!/bin/sh
printf '%s\n' "$1" >>"${TEST_DISPLAY_TRACE:?}"
EOF
chmod 0755 "$root/bin/plumos-display-control"
cat >"$root/bin/plumos-power-menu-overlay" <<'EOF'
#!/bin/sh
printf '%s\n' "${1:-}" >>"${TEST_POWER_TRACE:?}"
EOF
chmod 0755 "$root/bin/plumos-power-menu-overlay"

python3 - "$tmp/up.events" <<'PY'
import struct
import sys
with open(sys.argv[1], "wb") as stream:
    stream.write(struct.pack("llHHi", 0, 0, 1, 115, 1))
    stream.write(struct.pack("llHHi", 0, 0, 1, 115, 0))
PY
TEST_VOLUME_TRACE=$tmp/up.trace TEST_DISPLAY_TRACE=$tmp/up-display.trace \
PLUMOS_ROOT=$root \
PLUMOS_RUNTIME_ROOT=$runtime "$root/bin/plumos-volume-keys" \
    --event "$tmp/up.events" --once 2>"$tmp/up.log"
test "$(sed -n '1p' "$tmp/up.trace")" = apply
test "$(sed -n '2p' "$tmp/up.trace")" = runtime-up
test "$(sed -n '3p' "$tmp/up.trace")" = persist-runtime
grep -q 'action=volume direction=up rc=0' "$tmp/up.log"

python3 - "$tmp/down.events" <<'PY'
import struct
import sys
with open(sys.argv[1], "wb") as stream:
    stream.write(struct.pack("llHHi", 0, 0, 1, 114, 1))
    stream.write(struct.pack("llHHi", 0, 0, 1, 114, 0))
PY
TEST_VOLUME_TRACE=$tmp/down.trace TEST_DISPLAY_TRACE=$tmp/down-display.trace \
PLUMOS_ROOT=$root \
PLUMOS_RUNTIME_ROOT=$runtime "$root/bin/plumos-volume-keys" \
    --event "$tmp/down.events" --once 2>"$tmp/down.log"
test "$(sed -n '2p' "$tmp/down.trace")" = runtime-down
grep -q 'action=volume direction=down rc=0' "$tmp/down.log"

python3 - "$root/bin/plumos-volume-keys" "$root" "$runtime" "$tmp" <<'PY'
import os
import struct
import subprocess
import sys
import time

daemon, root, runtime, tmp = sys.argv[1:]
gamepad = os.path.join(tmp, "brightness-gamepad.fifo")
volume = os.path.join(tmp, "brightness-volume.fifo")
os.mkfifo(gamepad)
os.mkfifo(volume)
gamepad_keeper = os.open(gamepad, os.O_RDWR | os.O_NONBLOCK)
volume_keeper = os.open(volume, os.O_RDWR | os.O_NONBLOCK)
volume_trace = os.path.join(tmp, "brightness-volume.trace")
display_trace = os.path.join(tmp, "brightness-display.trace")
log_path = os.path.join(tmp, "brightness.log")
env = os.environ.copy()
env.update({
    "PLUMOS_ROOT": root,
    "PLUMOS_RUNTIME_ROOT": runtime,
    "TEST_VOLUME_TRACE": volume_trace,
    "TEST_DISPLAY_TRACE": display_trace,
})
with open(log_path, "wb") as log:
    process = subprocess.Popen(
        [daemon, "--gamepad-event", gamepad, "--event", volume, "--once"],
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=log,
    )
    time.sleep(0.1)
    event = lambda code, value: struct.pack("llHHi", 0, 0, 1, code, value)
    os.write(gamepad_keeper, event(314, 1))
    time.sleep(0.05)
    os.write(volume_keeper, event(115, 1))
    time.sleep(0.05)
    # Releasing SELECT must not change an already-held action into volume.
    os.write(gamepad_keeper, event(314, 0))
    time.sleep(0.55)
    os.write(volume_keeper, event(115, 0))
    time.sleep(0.85)
    os.close(gamepad_keeper)
    os.close(volume_keeper)
    if process.wait(timeout=3) != 0:
        raise SystemExit("brightness fixture daemon failed")
PY
test "$(sed -n '1p' "$tmp/brightness-volume.trace")" = apply
test "$(wc -l <"$tmp/brightness-volume.trace" | tr -d ' ')" -eq 1
test "$(sed -n '1p' "$tmp/brightness-display.trace")" = apply
test "$(grep -c '^runtime-up$' "$tmp/brightness-display.trace")" -ge 2
test "$(tail -n 1 "$tmp/brightness-display.trace")" = persist-runtime
grep -q 'action=display-brightness direction=up rc=0' "$tmp/brightness.log"
grep -q 'persist=display-brightness rc=0' "$tmp/brightness.log"

python3 - "$tmp/power.events" <<'PY'
import struct
import sys
with open(sys.argv[1], "wb") as stream:
    stream.write(struct.pack("llHHi", 0, 0, 1, 116, 1))
    stream.write(struct.pack("llHHi", 0, 0, 1, 116, 0))
PY
TEST_VOLUME_TRACE=$tmp/power-volume.trace \
TEST_DISPLAY_TRACE=$tmp/power-display.trace TEST_POWER_TRACE=$tmp/power.trace \
PLUMOS_ROOT=$root PLUMOS_RUNTIME_ROOT=$runtime \
    "$root/bin/plumos-volume-keys" --power-event "$tmp/power.events" --once \
    2>"$tmp/power.log"
attempt=0
while [ ! -s "$tmp/power.trace" ] && [ "$attempt" -lt 50 ]; do
    sleep 0.02
    attempt=$((attempt + 1))
done
test "$(sed -n '1p' "$tmp/power.trace")" = open
grep -q 'action=power-menu overlay=1 rc=0' "$tmp/power.log"
grep -q 'process_owns_display(frontend_pid)' \
    src/services/plumos_miniplus_volume_keys.c

printf 'miniplus_hardware_keys=result-ok volume=114,115 brightness=select+volume power=116\n'
