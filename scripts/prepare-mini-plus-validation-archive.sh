#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
image=${1:-$repo_root/output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.img}
seven_zip=${SEVEN_ZIP:-$(command -v 7zz || command -v 7z || true)}

[ -f "$image" ] || { echo "missing image: $image" >&2; exit 2; }
[ -n "$seven_zip" ] || { echo '7z or 7zz is required' >&2; exit 2; }
case "$image" in "$repo_root"/output/image/*) ;; *) echo 'image must be under output/image' >&2; exit 2;; esac

manifest=${image%/*}/image.manifest
[ -f "$manifest" ] || { echo "missing image manifest: $manifest" >&2; exit 2; }
expected_sha=$(awk -F= '$1 == "image_sha256" {print $2}' "$manifest")
actual_sha=$(shasum -a 256 "$image" | awk '{print $1}')
[ -n "$expected_sha" ] && [ "$actual_sha" = "$expected_sha" ] || {
    echo 'image checksum does not match its manifest' >&2
    exit 1
}
grep -q '^publishable=no$' "$manifest"

archive=${image%.img}.7z
archive_tmp=$archive.incoming
checksum=$archive.sha256
rm -f "$archive_tmp"
cleanup() { rm -f "$archive_tmp"; }
trap cleanup EXIT INT TERM
(cd "${image%/*}" && "$seven_zip" a -t7z -mx=9 -mmt=on \
    "${archive_tmp##*/}" "${image##*/}")
"$seven_zip" t "$archive_tmp" >/dev/null
roundtrip_sha=$("$seven_zip" x -so "$archive_tmp" "${image##*/}" 2>/dev/null | \
    shasum -a 256 | awk '{print $1}')
[ "$roundtrip_sha" = "$actual_sha" ] || {
    echo 'archive round-trip checksum mismatch' >&2
    exit 1
}
mv "$archive_tmp" "$archive"
archive_sha=$(shasum -a 256 "$archive" | awk '{print $1}')
printf '%s  %s\n' "$archive_sha" "${archive##*/}" >"$checksum"
trap - EXIT INT TERM
archive_bytes=$(stat -f '%z' "$archive" 2>/dev/null || stat -c '%s' "$archive")
printf 'miniplus_validation_archive=result-ok archive=%s archive_bytes=%s archive_sha256=%s raw_sha256=%s publishable=no\n' \
    "$archive" "$archive_bytes" "$archive_sha" "$actual_sha"
