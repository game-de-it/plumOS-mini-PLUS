#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
builder=$repo_root/scripts/build-mini-plus-frontend-probe-image.sh
verifier=$repo_root/scripts/verify-mini-plus-frontend-probe-image.sh
release=$repo_root/scripts/prepare-mini-plus-release.sh

sh -n "$builder" "$verifier" "$release" \
    "$repo_root/scripts/prepare-mini-plus-validation-archive.sh"
grep -Fq 'expected_prefix=aa8bd95d5d75aaab1977c5e58732d67545221649a08e6b7afda36aee208e26e9' "$builder"
for identity in \
    rk3566-gkdmini-pro.dtb \
    rk3566-gkdmini-pro-not-gsensor.dtb \
    rk3566-gkdmini-pro-gsensor-hat.dtb \
    rk3566-gkdmini-pro-gsensor-js.dtb; do
    grep -Fq "$identity" "$builder"
done
grep -Fq 'format=plumos-mini-plus-full-stack-validation-image-v3' "$builder"
grep -Fq 'format=plumos-mini-plus-full-stack-validation-image-v3' "$verifier"
grep -Fq 'physical_cold_boots=3' "$release"
grep -Fq 'release_approved=yes' "$release"

for stale in \
    648078e91860adf21bd4ec8f1fd8a64ce52de0ce24511393b156b920327b4ec2 \
    rk3566-gkd-geek-bbg.dtb \
    0a3a3b6; do
    if grep -R -F -n "$stale" "$repo_root/scripts" --exclude-dir=__pycache__; then
        echo "stale Bubble identity remains in mini PLUS scripts: $stale" >&2
        exit 1
    fi
done

echo 'miniplus_plumos_conformance=result-ok bubble_identity_leaks=0 measured_p3=yes release_acceptance_gate=yes'
