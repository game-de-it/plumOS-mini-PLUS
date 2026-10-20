#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}
if [[ ${1:-} != --inside ]]; then
    if [[ ${1:-} != --assemble-only ]]; then
        "$repo_root/scripts/build-mini-plus-frontend.sh"
        "$repo_root/scripts/build-nextcommander-mini-plus.sh"
        "$repo_root/scripts/build-music-player-mini-plus.sh"
        "$repo_root/scripts/build-network-services-mini-plus.sh"
        "$repo_root/scripts/build-mini-plus-retroarch.sh"
        "$repo_root/scripts/build-libretro-core-catalog-mini-plus.sh" \
            --filter all --concurrency "${PLUMOS_MINI_PLUS_CORE_CONCURRENCY:-2}"
        "$repo_root/scripts/build-picoarch-mini-plus.sh"
        "$repo_root/scripts/build-pyxel-mini-plus.sh"
        "$repo_root/scripts/build-standalone-mini-plus.sh"
        "$repo_root/scripts/build-portmaster-mini-plus.sh"
    fi
    for required in \
        output/libretro-cores/mini-plus-all/plumos \
        output/picoarch/mini-plus/plumos \
        output/standalone/mini-plus/plumos \
        output/pyxel/mini-plus/plumos \
        output/portmaster/mini-plus/plumos; do
        [[ -d "$repo_root/$required" ]] || {
            printf 'error: full emulator-stack input is missing: %s\n' "$required" >&2
            exit 1
        }
    done
    for required in \
        output/nextcommander/mini-plus/plumos \
        output/music-player/mini-plus/plumos; do
        [[ -d "$repo_root/$required" ]] || {
            printf 'error: common app input is missing: %s\n' "$required" >&2
            exit 1
        }
    done
    [[ -d "$repo_root/output/network-services/mini-plus/plumos" ]] || {
        printf 'error: network-services input is missing\n' >&2
        exit 1
    }
    exec docker run --rm --platform linux/arm64 \
        -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}" \
        -e PLUMOS_MINI_PLUS_VERSION="${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}" \
        -v "$repo_root:/work" -w /work "$image" \
        ./scripts/build-mini-plus-app-layer.sh --inside
fi

repo_root=/work
out=$repo_root/output/app-layer/mini-plus
root=$out/plumos
version=${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}
source_ref=$(git -c safe.directory="$repo_root" -C "$repo_root" rev-parse --short HEAD 2>/dev/null || printf unknown)
epoch=${SOURCE_DATE_EPOCH:-}
[[ -n $epoch ]] || epoch=$(git -c safe.directory="$repo_root" -C "$repo_root" show -s --format=%ct HEAD)

rm -rf "$out"
mkdir -p "$root"
cp -a "$repo_root/output/frontend/mini-plus/plumos/." "$root/"
cp -a "$repo_root/output/nextcommander/mini-plus/plumos/." "$root/"
cp -a "$repo_root/output/music-player/mini-plus/plumos/." "$root/"
cp -a "$repo_root/output/network-services/mini-plus/plumos/." "$root/"
cp -a "$repo_root/output/retroarch/mini-plus/plumos/." "$root/"
cp -a "$repo_root/output/libretro-cores/mini-plus-all/plumos/." "$root/"
cp -a "$repo_root/output/picoarch/mini-plus/plumos/." "$root/"
cp -a "$repo_root/output/standalone/mini-plus/plumos/." "$root/"
cp -a "$repo_root/output/pyxel/mini-plus/plumos/." "$root/"
cp -a "$repo_root/output/portmaster/mini-plus/plumos/." "$root/"
find "$root" -name .DS_Store -type f -delete
mkdir -p "$root/config/frontend" "$root/config/system" "$root/config/retroarch" \
    "$root/state/frontend" "$root/logs" "$root/saves" "$root/states" "$root/licenses"
install -m 0644 "$repo_root/LICENSE" "$root/licenses/plumOS-MIT.txt"
install -m 0644 "$repo_root/THIRD_PARTY_NOTICES.md" \
    "$root/licenses/THIRD_PARTY_NOTICES.md"
install -m 0644 "$repo_root/docs/licenses/GKD-stockOS-PERMISSION-NOTICE.txt" \
    "$root/licenses/GKD-stockOS-PERMISSION-NOTICE.txt"
install -m 0644 "$repo_root/docs/licenses/drastic-upstream-NOTICE.txt" \
    "$root/licenses/drastic-upstream-NOTICE.txt"
install -m 0644 "$repo_root/docs/licenses/mini-plus-runtime-license-inventory.tsv" \
    "$root/licenses/RUNTIME_LICENSE_INDEX.tsv"
printf 'mini-plus-stockos-r1\n' >"$root/COMPAT_VENDOR"
printf '1\n' >"$root/RUNTIME_ABI"
cat >"$root/config/system/allow-rtl8821cs-force-load" <<'EOF'
format=plumos-mini-plus-wifi-force-load-authorization-v1
authorized=yes
scope=full-host-candidate-only
risk=stock-module-vermagic-4.19.172-vs-running-kernel-4.19.193-modversions
EOF

for json in "$root"/config/frontend/*.json "$root"/factory-defaults/*/*.json \
    "$root"/components/*/manifest.json; do jq -e . "$json" >/dev/null; done
PLUMOS_MINI_PLUS_APP_ROOT="$root" \
    "$repo_root/scripts/verify-mini-plus-emulator-catalog.sh"
# Validate each component in its own immutable staging tree.  Several runtime
# components intentionally contribute the same shared-library pathname (for
# example RetroArch and EasyRPG both package libpng 1.6.39 with different build
# IDs), so applying every component checksum to the final last-writer-wins
# overlay would report a false corruption.  The merged tree receives its own
# checksum below and is smoke-loaded after assembly.
for component_source in \
    "frontend:$repo_root/output/frontend/mini-plus/plumos" \
    "nextcommander:$repo_root/output/nextcommander/mini-plus/plumos" \
    "music-player:$repo_root/output/music-player/mini-plus/plumos" \
    "network-services:$repo_root/output/network-services/mini-plus/plumos" \
    "retroarch:$repo_root/output/retroarch/mini-plus/plumos" \
    "libretro-cores:$repo_root/output/libretro-cores/mini-plus-all/plumos" \
    "picoarch:$repo_root/output/picoarch/mini-plus/plumos" \
    "standalone:$repo_root/output/standalone/mini-plus/plumos" \
    "pyxel:$repo_root/output/pyxel/mini-plus/plumos" \
    "portmaster:$repo_root/output/portmaster/mini-plus/plumos"; do
    component=${component_source%%:*}
    component_root=${component_source#*:}
    (cd "$component_root" && sha256sum --quiet -c "components/$component/checksums.sha256")
done
# Older cached standalone builds own the prior vendor notice in their component
# checksum. Verify the component first, then replace that policy document with
# the repository-current release notice before generating the global checksum.
install -m 0644 "$repo_root/docs/licenses/mini-plus-vendor-runtime-NOTICE.txt" \
    "$root/licenses/mini-plus-vendor-runtime-NOTICE.txt"
LD_LIBRARY_PATH="$root/emulator/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    python3 "$repo_root/scripts/smoke-load-libretro-cores-mini-plus.py" \
    --root "$root" >"$out/libretro-core-load-smoke.log"
grep -Fqx 'miniplus_libretro_load_smoke=result-ok pass=114 fail=0' \
    "$out/libretro-core-load-smoke.log"

cat >"$root/manifest.json" <<EOF
{
  "name": "plumOS mini PLUS bring-up app layer",
  "device": "mini-plus",
  "version": "$version",
  "source_ref": "$source_ref",
  "source_date_epoch": $epoch,
  "managed_components": ["frontend", "nextcommander", "music-player", "network-services", "retroarch", "libretro-cores", "picoarch", "standalone", "pyxel", "portmaster"],
  "frontend": "cpu-drm-dumb-buffer",
  "retroarch": "software-plain-drm-rgui-and-hardware-kms-egl-gles-xmb-ozone",
  "core_baseline": "all-114-source-records",
  "catalog_complete": true,
  "release_complete": false,
  "physical_frontend_acceptance": "user-reported-boot-and-basic-controller-operation",
  "wifi": "experimental-stock-rtl8821cs-normal-then-explicit-force-load",
  "wifi_force_gate": "config/system/allow-rtl8821cs-force-load",
  "catalog_systems": 97,
  "catalog_launch_profile_occurrences": 196,
  "coverage_manifest": "config/frontend/runtime-coverage.json",
  "mutable_paths": ["config/frontend/settings.json", "config/system/settings.json", "config/retroarch", "logs", "state", "saves", "states"],
  "user_media_included": false,
  "managed_firmware_assets": ["blueMSX C-BIOS", "DraStic packaged BIOS (project-approved inclusion)"],
  "license_policy": "MIT for plumOS-authored material; GKD/vendor/upstream terms for stockOS-derived material; DraStic project-approved inclusion matching plumOS-MF",
  "publishable": false,
  "non_publishable_reasons": ["mini-PLUS emulator/GPU/audio/power physical acceptance incomplete", "experimental forced Wi-Fi module ABI validation pending"]
}
EOF
(
    cd "$root"
    find . -type f ! -name '.DS_Store' ! -path './checksums.sha256' \
        ! -path './config/frontend/settings.json' \
        ! -path './config/system/settings.json' \
        ! -path './config/retroarch/*' \
        ! -path './config/standalone/*' \
        ! -path './logs/*' ! -path './state/*' ! -path './saves/*' ! -path './states/*' \
        -print | sed 's#^./##' | LC_ALL=C sort |
        while IFS= read -r path; do sha256sum "$path"; done
) >"$root/checksums.sha256"
(cd "$root" && sha256sum --quiet -c checksums.sha256)

PLUMOS_ROOT="$root" PLUMOS_SDCARD_ROOT="$out" \
    "$root/bin/plumos-library-scan" --defer-thumbnails >"$out/library-scan.log" 2>&1
PLUMOS_ROOT="$root" PLUMOS_SDCARD_ROOT="$out" PLUMOS_RENDERER=text \
    "$root/bin/plumos-controller-ui-fbdev" --renderer text \
    --script start,b,q --no-clear >"$out/frontend-script.log" 2>&1
grep -q 'START' "$out/frontend-script.log"
! find "$out" -type f \( -iname '*.nes' -o -iname '*.unf' -o -iname '*.unif' \) -print -quit | grep -q .
echo "miniplus_app_layer=result-ok root=$root"
