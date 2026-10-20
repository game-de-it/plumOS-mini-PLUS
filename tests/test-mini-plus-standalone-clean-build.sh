#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script=$repo_root/scripts/build-standalone-mini-plus.sh
pcsx_script=$repo_root/scripts/build-pcsx-rearmed-mini-plus.sh
yabasanshiro_script=$repo_root/scripts/build-yabasanshiro-mini-plus.sh
drastic_script=$repo_root/scripts/build-drastic-mini-plus.sh

grep -Fq 'if [[ ${1:-} != --inside ]]; then' "$script"
grep -Fq 'plumos-mini-plus-core-tools:dev' "$script"
grep -Fq 'source_epoch="${SOURCE_DATE_EPOCH:-$(' "$script"
grep -Fq -- '-e SOURCE_DATE_EPOCH="$source_epoch"' "$script"
grep -Fq -- '-v "$ROOT_DIR:/work" -w /work "$TOOLS_IMAGE"' "$script"
grep -Fq -- '-e PLUMOS_MINI_PLUS_INCLUDE_CAPTURED_VENDOR_GPU=' "$script"
grep -Fq 'inside_args=(--inside)' "$script"
grep -Fq 'inside_args+=(--assemble-only)' "$script"
grep -Fq './scripts/build-standalone-mini-plus.sh "${inside_args[@]}"' "$script"
! grep -Fq 'mode=()' "$script"
grep -Fq -- '--assemble-only) ;;' "$script"

assembly_line=$(grep -nF 'OUT_ROOT="$ROOT_DIR/${PLUMOS_MINI_PLUS_STANDALONE_OUT:-output/standalone/mini-plus}"' "$script" | cut -d: -f1)
for builder in \
    build-pcsx-rearmed-mini-plus.sh \
    build-yabasanshiro-mini-plus.sh \
    build-drastic-mini-plus.sh \
    build-ppsspp-mini-plus.sh \
    build-openbor-mini-plus.sh; do
    line=$(grep -nF '"$ROOT_DIR/scripts/'"$builder"'"' "$script" | cut -d: -f1)
    test -n "$line"
    test "$line" -lt "$assembly_line"
done

grep -Fq 'PREFIX="$SDL12_ROOT/install-mini-plus/"' "$pcsx_script"
grep -Fq -- '-DCMAKE_C_COMPILER=clang' "$yabasanshiro_script"
grep -Fq -- '-DCMAKE_CXX_COMPILER=clang++' "$yabasanshiro_script"
! grep -Fq -- '-DCMAKE_C_COMPILER=gcc' "$yabasanshiro_script"
grep -Fq 'COMMON_SHA256="$(sha256sum "$SOURCE_LIB_ROOT/libcommon.so"' "$drastic_script"
grep -Fq 'DETOUR_SHA256="$(sha256sum "$SOURCE_LIB_ROOT/libdtr.so"' "$drastic_script"
grep -Fq 'SDL2_SHA256="$(sha256sum "$SOURCE_LIB_ROOT/libSDL2-2.0.so.0"' "$drastic_script"
grep -Fq -- '-path "$OVERLAY_DIR/usr/work" -prune' "$drastic_script"

printf '%s\n' 'miniplus_standalone_clean_build=result-ok builders=5 containerized=1'
