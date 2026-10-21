#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
audio=$repo_root/package/frontend-mini-plus/plumos/bin/plumos-audio-output
volume=$repo_root/package/frontend-mini-plus/plumos/bin/plumos-volume-control
service=$repo_root/package/frontend-mini-plus/plumos/bin/plumos-volume-keys-service
frontend=$repo_root/package/frontend-mini-plus/plumos/bin/plumos-frontend-launch
shutdown=$repo_root/package/frontend-mini-plus/plumos/bin/plumos-safe-shutdown

sh -n "$audio" "$volume" "$service" "$frontend" "$shutdown"
grep -q '^pcm\.plumos_softvol {' "$audio"
grep -q '^ctl\.hw {' "$audio"
grep -q 'card \$CARD' "$audio"
grep -q '^pcm\.plumos_output {' "$audio"
grep -q '^pcm\.plumos_pyxel {' "$audio"
grep -q 'name "Soft Volume Master"' "$audio"
grep -q 'min_dB -90.0' "$audio"
grep -q "name=Playback Path" "$audio"
grep -q 'cset.*SPK_HP' "$audio"
grep -q 'HARDWARE_ROUTE=spk-hp-from-' "$audio"
grep -q 'plumos-aplay' "$volume"
grep -q 'curve=pixel2-linear-amplitude-v1' "$volume"
grep -q 'apply "$next" || return 1' "$volume"
grep -q 'plumos-volume-keys-service.*start' "$frontend"
grep -q 'plumos-volume-keys-service' "$shutdown"
grep -q 'gpio-keys' "$repo_root/src/services/plumos_miniplus_volume_keys.c"
grep -q 'KEY_VOLUMEUP' "$repo_root/src/services/plumos_miniplus_volume_keys.c"
grep -q 'KEY_VOLUMEDOWN' "$repo_root/src/services/plumos_miniplus_volume_keys.c"
grep -q 'BTN_SELECT' "$repo_root/src/services/plumos_miniplus_volume_keys.c"
grep -q 'plumos-display-control' "$repo_root/src/services/plumos_miniplus_volume_keys.c"
grep -q 'persist=display-brightness' "$repo_root/src/services/plumos_miniplus_volume_keys.c"

for launcher in \
    "$repo_root/package/frontend-mini-plus/plumos/bin/plumos-retroarch-launch" \
    "$repo_root/package/frontend-mini-plus/plumos/bin/plumos-retroarch-menu-launch" \
    "$repo_root/package/picoarch-mini-plus/plumos/bin/plumos-picoarch-launch" \
    "$repo_root/package/standalone-mini-plus/plumos/bin/plumos-standalone-launch"; do
    grep -q 'plumos-audio-output' "$launcher"
    grep -q 'plumos-volume-control' "$launcher"
done

test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM
mkdir -p "$test_root/root/bin" "$test_root/run"
fake_amixer=$test_root/root/bin/plumos-amixer
state=$test_root/amixer-state
log=$test_root/amixer.log
cat >"$fake_amixer" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$PLUMOS_FAKE_AMIXER_LOG"
case " $* " in
    *' cget '*)
        value=$(cat "$PLUMOS_FAKE_AMIXER_STATE")
        cat <<OUT
numid=1,iface=MIXER,name='Playback Path'
  ; type=ENUMERATED,access=rw------,values=1,items=4
  ; Item #0 'OFF'
  ; Item #1 'SPK'
  ; Item #2 'HP'
  ; Item #3 'SPK_HP'
  : values=$value
OUT
        ;;
    *' cset '*' SPK_HP '*)
        printf '3\n' >"$PLUMOS_FAKE_AMIXER_STATE"
        ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$fake_amixer"

run_route_case() {
    initial=$1
    expected=$2
    expect_cset=$3
    printf '%s\n' "$initial" >"$state"
    : >"$log"
    PLUMOS_ROOT=$test_root/root \
    PLUMOS_RUNTIME_ROOT=$test_root/run \
    PLUMOS_PLAYBACK_PCM=/dev/null \
    PLUMOS_AMIXER=$fake_amixer \
    PLUMOS_FAKE_AMIXER_STATE=$state \
    PLUMOS_FAKE_AMIXER_LOG=$log \
        "$audio" prepare >/dev/null
    grep -qx "hardware_route=$expected" "$test_root/run/audio/output.status"
    csets=$(grep -c ' cset ' "$log" || true)
    [ "$csets" -eq "$expect_cset" ]
}

run_route_case 0 spk-hp-from-off 1
run_route_case 1 spk-hp-from-spk 1
run_route_case 2 preserved-non-speaker 0
run_route_case 3 preserved-spk-hp 0

grep -q 'managed_audio_device=plumos_output' \
    "$repo_root/package/frontend-mini-plus/plumos/bin/plumos-retroarch-launch"
grep -q 'audio_device = "plumos_output"' \
    "$repo_root/package/frontend-mini-plus/plumos/bin/plumos-retroarch-menu-launch"

printf 'miniplus_managed_volume=result-ok range=0..20 backend=alsa-softvol\n'
