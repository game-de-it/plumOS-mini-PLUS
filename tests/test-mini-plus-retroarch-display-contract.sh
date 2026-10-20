#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
rotation_patch=$repo_root/patches/retroarch/019-mini-plus-drm-core-rotation-contract.patch
viewport_patch=$repo_root/patches/retroarch/020-mini-plus-drm-runtime-viewport-menu.patch
verifier=$repo_root/scripts/verify-mini-plus-display-contracts.py

grep -q 'drm_set_rotation,' "$rotation_patch"
grep -q 'retroarch_get_core_requested_rotation' "$rotation_patch"
grep -q 'core_rotation = rotation & 3' "$rotation_patch"
grep -q 'layer == 2' "$rotation_patch"
grep -q 'mini PLUS display-contract' "$rotation_patch"
grep -q 'logical_width' "$rotation_patch"
grep -q 'logical_height' "$rotation_patch"
grep -q 'logical_width  = surface->viewport.height' "$rotation_patch"
grep -q 'surface->src_width   = surface->viewport.width' "$rotation_patch"
grep -q 'aspectratio_lut\[ASPECT_RATIO_CORE\] is already post-rotation' "$rotation_patch"
! grep -q 'new_aspect = 1.0f / new_aspect' "$rotation_patch"
! grep -q 'current_aspect = 1.0f / _drmvars->current_aspect' "$rotation_patch"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
cat >"$tmp/vertical-ok.json" <<'EOF'
{"records":[{"system":"arcade","profile":"retroarch:fbneo","status":"started","display_contract_lines":["[DRM] mini PLUS display-contract layer=0 frame=256x224 aspect=0.750000 rotation=1 viewport=360x480+140+0 scanout=360x480."]}]}
EOF
cat >"$tmp/vertical-stretched.json" <<'EOF'
{"records":[{"system":"arcade","profile":"retroarch:fbneo","status":"started","display_contract_lines":["[DRM] mini PLUS display-contract layer=0 frame=256x224 aspect=0.750000 rotation=1 viewport=640x480+0+0 scanout=640x480."]}]}
EOF
python3 "$verifier" "$tmp/vertical-ok.json" >/dev/null
if python3 "$verifier" "$tmp/vertical-stretched.json" >/dev/null 2>&1; then
    printf 'vertical stretched viewport was accepted\n' >&2
    exit 1
fi

grep -q 'video_viewport_get_scaled_integer' "$viewport_patch"
grep -q 'surface->aspect, keep_aspect' "$viewport_patch"
grep -q 'surface->layer != 2' "$viewport_patch"
grep -q 'surface->aspect   = 4.0f / 3.0f' "$viewport_patch"
grep -q 'menu_view.layer    = 2' "$viewport_patch"
grep -q 'mini PLUS recreating RGUI surface' "$viewport_patch"
grep -q 'drm_invalidate_surfaces(_drmvars, "runtime video state change")' \
    "$viewport_patch"
grep -q 'drm_invalidate_surfaces(_drmvars, "runtime aspect change")' \
    "$viewport_patch"

if [ -f "$repo_root/output/retroarch/mini-plus/plumos/bin/retroarch" ]; then
    strings "$repo_root/output/retroarch/mini-plus/plumos/bin/retroarch" |
        grep -q 'mini PLUS display-contract'
    strings "$repo_root/output/retroarch/mini-plus/plumos/bin/retroarch" |
        grep -q 'mini PLUS rotations panel='
    strings "$repo_root/output/retroarch/mini-plus/plumos/bin/retroarch" |
        grep -q 'mini PLUS surfaces invalidated for'
    strings "$repo_root/output/retroarch/mini-plus/plumos/bin/retroarch" |
        grep -q 'mini PLUS recreating RGUI surface'
fi

printf 'miniplus_retroarch_display_contract=result-ok panel=landscape core_rotation=software aspect=core-provided integer=content-only menu=fixed-4:3\n'
