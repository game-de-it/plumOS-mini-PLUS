#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
builder=$repo_root/scripts/build-mini-plus-full-image.sh
image_builder=$repo_root/scripts/build-mini-plus-frontend-probe-image.sh
verifier=$repo_root/scripts/verify-mini-plus-frontend-probe-image.sh
dispatcher=$repo_root/scripts/verify-mini-plus-image.sh

sh -n "$builder" "$image_builder" "$verifier" "$dispatcher"
grep -Fq 'build-mini-plus-frontend-probe-image.sh' "$builder"
grep -Fq 'runtime_headroom_bytes=268435456' "$image_builder"
grep -Fq 'runtime_alignment_bytes=134217728' "$image_builder"
grep -Fq 'runtime_seed_mib" -eq 2176' "$image_builder"
grep -Fq 'p1-fat32-512MiB,p2-raw-64MiB,p3-ext4-${runtime_seed_mib}MiB,no-p4' "$image_builder"
grep -Fq 'system-a.squashfs' "$image_builder"
grep -Fq 'system-b.squashfs' "$image_builder"
grep -Fq 'physical_boot_status=unverified-full-image' "$image_builder"
grep -Fq 'test "$expected_size" -eq 2902458368' "$verifier"
grep -Fq 'refusing withdrawn fixed-4GiB bring-up artifact' "$dispatcher"
! grep -Fq 'storage_sectors=8388608' "$builder"
! grep -Fq 'p2-ext4-4096MiB' "$builder"
! grep -Fq '4 GiB ext4 in the full image' "$repo_root/README.md"

echo 'miniplus_full_image_contract=result-ok p1_mib=512 p2_mib=64 p3_mib=2176 p4=first-boot system_ab=yes publishable=no'
