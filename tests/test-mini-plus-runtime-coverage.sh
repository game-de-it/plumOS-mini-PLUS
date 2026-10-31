#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app_root=${PLUMOS_MINI_PLUS_APP_ROOT:-$repo_root/output/app-layer/mini-plus/plumos}
coverage=$repo_root/package/frontend-mini-plus/plumos/config/frontend/runtime-coverage.json

test -f "$app_root/components/libretro-cores/manifest.json"
generated=$(mktemp "${TMPDIR:-/tmp}/mini-plus-runtime-coverage-test.XXXXXX")
trap 'rm -f "$generated"' EXIT HUP INT TERM

"$repo_root/scripts/generate-mini-plus-runtime-coverage.py" \
    --app-root "$app_root" --output "$generated"
cmp "$coverage" "$generated"

PLUMOS_MINI_PLUS_APP_ROOT=$app_root \
    "$repo_root/scripts/verify-mini-plus-emulator-catalog.sh"
python3 "$repo_root/scripts/summarize-mini-plus-runtime-validation.py" --verify

printf '%s\n' 'miniplus_runtime_coverage=result-ok systems=97 profiles=196 core_records=114'
