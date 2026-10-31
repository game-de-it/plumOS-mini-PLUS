#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version=${1:-$(cat "$repo_root/VERSION")}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    echo 'formal release version must be MAJOR.MINOR.PATCH' >&2; exit 2;
}
image=${2:-$repo_root/output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-$version-full-stack-validation.img}
source_notes=$repo_root/docs/releases/$version.md
source_manifest=${image%/*}/image.manifest
acceptance_manifest=${3:-$repo_root/docs/validation/$version-mini-plus-device-acceptance.env}
seven_zip=${SEVEN_ZIP:-$(command -v 7zz || command -v 7z || true)}
release_name=plumos-mini-plus-release-v$version
release_dir=$repo_root/dist/$release_name
stage_dir=$repo_root/dist/.$release_name.incoming
raw_name=plumos-mini-plus-v$version-sd-image.img
archive_name=plumos-mini-plus-v$version-sd-image.7z

[ -f "$image" ] || { echo "missing image: $image" >&2; exit 2; }
[ -f "$source_manifest" ] || { echo "missing image manifest: $source_manifest" >&2; exit 2; }
[ -f "$source_notes" ] || { echo "missing release notes: $source_notes" >&2; exit 2; }
[ -f "$acceptance_manifest" ] || {
    echo "missing explicit device acceptance manifest: $acceptance_manifest" >&2
    exit 2
}
[ -n "$seven_zip" ] || { echo "7z or 7zz is required" >&2; exit 2; }
[ -z "$(git -C "$repo_root" status --short)" ] || {
    echo "refusing release preparation from a dirty worktree" >&2
    exit 2
}
[ ! -e "$release_dir" ] || {
    echo "release directory already exists: $release_dir" >&2
    exit 2
}
[ ! -e "$stage_dir" ] || {
    echo "staging directory already exists: $stage_dir" >&2
    exit 2
}

expected_image_sha=$(awk -F= '$1 == "image_sha256" {print $2}' "$source_manifest")
actual_image_sha=$(shasum -a 256 "$image" | awk '{print $1}')
[ "$actual_image_sha" = "$expected_image_sha" ] || {
    echo "image checksum mismatch" >&2
    exit 1
}
image_source_ref=$(awk -F= '$1 == "source_ref" {print $2}' "$source_manifest")
[ -n "$image_source_ref" ] || { echo 'image manifest has no source_ref' >&2; exit 1; }
grep -q '^publishable=no$' "$source_manifest"
grep -Fxq "version=$version" "$source_manifest"
grep -q '^format=plumos-mini-plus-device-acceptance-v1$' "$acceptance_manifest"
grep -q "^image_sha256=$actual_image_sha$" "$acceptance_manifest"
grep -q '^full_image_boot=yes$' "$acceptance_manifest"
grep -q '^block_readback=yes$' "$acceptance_manifest"
grep -q '^physical_cold_boots=3$' "$acceptance_manifest"
grep -q '^maintainer_accepted=yes$' "$acceptance_manifest"
grep -q '^release_approved=yes$' "$acceptance_manifest"

mkdir -p "$repo_root/dist" "$stage_dir"
cleanup() {
    rm -f "$stage_dir/$raw_name"
    if [ -d "$stage_dir" ] && [ ! -e "$release_dir" ]; then
        rm -rf "$stage_dir"
    fi
}
trap cleanup EXIT INT TERM

cp "$source_notes" "$stage_dir/RELEASE_NOTES.md"
cp "$source_manifest" "$stage_dir/plumos-mini-plus-v$version-image-build-manifest.txt"
ln "$image" "$stage_dir/$raw_name"

"$repo_root/scripts/verify-mini-plus-frontend-probe-image.sh" "$image" \
    >"$stage_dir/plumos-mini-plus-v$version-image-verify.txt" 2>&1

# Export originals from the verifier's image readback, not a possibly newer
# host Runtime cache. These directories were checked against the exact image.
verified=$repo_root/work/mini-plus-frontend-probe-verify
grep -Fxq "$version" "$verified/app-layer/plumos/VERSION"
grep -Fxq "VERSION_ID=\"$version\"" "$verified/system-root/etc/os-release"
python3 "$repo_root/scripts/export-mini-plus-release-licenses.py" \
    --runtime-licenses "$verified/app-layer/plumos/licenses" \
    --system-licenses "$verified/system-root/usr/share/licenses" \
    --output "$stage_dir/licenses"
cp "$repo_root/LICENSE" "$stage_dir/LICENSE"
cp "$repo_root/THIRD_PARTY_NOTICES.md" "$stage_dir/THIRD_PARTY_NOTICES.md"

(cd "$stage_dir" && "$seven_zip" a -t7z -mx=9 -mmt=on "$archive_name" "$raw_name")
rm -f "$stage_dir/$raw_name"
"$seven_zip" t "$stage_dir/$archive_name" >/dev/null
archive_raw_sha=$("$seven_zip" x -so "$stage_dir/$archive_name" "$raw_name" 2>/dev/null | \
    shasum -a 256 | awk '{print $1}')
[ "$archive_raw_sha" = "$actual_image_sha" ] || {
    echo "archive round-trip checksum mismatch" >&2
    exit 1
}

archive_sha=$(shasum -a 256 "$stage_dir/$archive_name" | awk '{print $1}')
release_source_ref=$(git -C "$repo_root" rev-parse HEAD)
{
    printf '%s\n' 'format=plumos-mini-plus-release-bundle-v1'
    printf 'version=%s\n' "$version"
    printf 'prerelease=no\n'
    printf 'release_source_ref=%s\n' "$release_source_ref"
    printf 'image_source_ref=%s\n' "$image_source_ref"
    printf 'image_file=%s\n' "$raw_name"
    printf 'image_sha256=%s\n' "$actual_image_sha"
    printf 'archive_file=%s\n' "$archive_name"
    printf 'archive_sha256=%s\n' "$archive_sha"
    printf 'image_internal_publishable=no\n'
    printf 'promotion=maintainer-accepted-exact-byte-image\n'
    printf 'physical_cold_boots=3\n'
    printf 'acceptance_manifest_sha256=%s\n' \
        "$(shasum -a 256 "$acceptance_manifest" | awk '{print $1}')"
    printf 'user_media_included=no\n'
    printf 'publication_complete=no\n'
} >"$stage_dir/manifest.txt"

printf '%s  %s\n' "$archive_sha" "$archive_name" \
    >"$stage_dir/$archive_name.sha256"
(cd "$stage_dir" && shasum -a 256 \
    RELEASE_NOTES.md \
    LICENSE \
    THIRD_PARTY_NOTICES.md \
    manifest.txt \
    "plumos-mini-plus-v$version-image-build-manifest.txt" \
    "plumos-mini-plus-v$version-image-verify.txt" \
    "$archive_name" \
    "$archive_name.sha256" >SHA256SUMS)
(cd "$stage_dir" && find licenses -type f -print | LC_ALL=C sort | \
    while IFS= read -r notice; do shasum -a 256 "$notice"; done >>SHA256SUMS)
(cd "$stage_dir" && shasum -a 256 -c SHA256SUMS >/dev/null)

mv "$stage_dir" "$release_dir"
trap - EXIT INT TERM
printf 'miniplus_release_prepare=result-ok version=%s dir=%s image_sha256=%s archive_sha256=%s\n' \
    "$version" "$release_dir" "$actual_image_sha" "$archive_sha"
