#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build=$repo_root/scripts/build-mini-plus-retroarch.sh
game_launcher=$repo_root/package/frontend-mini-plus/plumos/bin/plumos-retroarch-launch
menu_launcher=$repo_root/package/frontend-mini-plus/plumos/bin/plumos-retroarch-menu-launch
factory=$repo_root/configs/retroarch/mini-plus-software-drm.cfg

for option in --enable-rgui --enable-xmb --enable-ozone; do
    grep -q -- "$option" "$build"
done
grep -Eq '^assets_ref=[0-9a-f]{40}$' "$build"
for tree in fonts glui ozone pkg rgui sounds xmb; do
    grep -q 'for asset_tree in fonts glui ozone pkg rgui sounds xmb' "$build"
done
grep -q 'menu_ctx_ozone menu_ctx_xmb' "$build"
grep -q '"menu_drivers": \["rgui", "xmb", "ozone"\]' "$build"
grep -qx 'assets_directory = "/storage/plumos/retroarch/assets"' "$factory"
grep -qx 'menu_driver = "rgui"' "$factory"
grep -q '\*:\*:xmb|\*:\*:ozone' "$game_launcher"
grep -q 'xmb|ozone)' "$menu_launcher"
grep -q 'video_driver = "gl"' "$menu_launcher"

if [ -f "$repo_root/output/retroarch/mini-plus/plumos/bin/retroarch" ]; then
    jq -e '.menu_drivers == ["rgui", "xmb", "ozone"]' \
        "$repo_root/output/retroarch/mini-plus/plumos/components/retroarch/manifest.json" \
        >/dev/null
    for tree in fonts glui ozone pkg rgui sounds xmb; do
        test -d "$repo_root/output/retroarch/mini-plus/plumos/retroarch/assets/$tree"
    done
fi

printf 'miniplus_retroarch_menu_assets=result-ok default=rgui optional=xmb,ozone backend=gl\n'
