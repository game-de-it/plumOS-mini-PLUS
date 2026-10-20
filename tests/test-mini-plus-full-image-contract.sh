#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
builder=$repo_root/scripts/build-mini-plus-full-image.sh
verifier=$repo_root/scripts/verify-mini-plus-image.sh

sh -n "$builder" "$verifier"
grep -Fq 'storage_sectors=8388608' "$builder"
grep -Fq 'layout=raw-prefix-16MiB,p1-fat32-512MiB,p2-ext4-4096MiB' "$builder"
grep -Fq 'app_layer=full' "$builder"
grep -Fq 'catalog_complete=true' "$builder"
grep -Fq 'allow-rtl8821cs-force-load' "$builder"
grep -Fq 'publishable=no' "$builder"
grep -Fq 'expected_size=4848615424' "$verifier"
grep -Fq 'p2_bytes=4294967296' "$verifier"

echo 'miniplus_full_image_contract=result-ok p1_mib=512 p2_mib=4096 publishable=no'
