#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tools_image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}

if [ "${1:-}" != "--inside" ]; then
    "$repo_root/scripts/build-mini-plus-image.sh"
    "$repo_root/scripts/build-mini-plus-frontend.sh"
    "$repo_root/scripts/build-mini-plus-frontend-system.sh"
    exec docker run --rm --platform linux/arm64 \
        -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}" \
        -e PLUMOS_MINI_PLUS_VERSION="${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}" \
        -v "$repo_root:/work" -w /work "$tools_image" \
        ./scripts/build-mini-plus-frontend-image.sh --inside
fi

repo_root=/work
base_dir=$repo_root/output/image/mini-plus
base_image=$base_dir/plumOS-mini-PLUS-${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}-host-candidate.img
frontend=$repo_root/output/frontend/mini-plus/plumos
system_dir=$repo_root/output/system-rootfs/mini-plus-frontend/payload
initramfs=$repo_root/output/initramfs/mini-plus-boot/payload/initramfs-plumos-mini-plus.cpio.gz
out_dir=$repo_root/output/image/mini-plus-frontend
work=$repo_root/work/mini-plus-frontend-image
version=${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}
source_ref=$(git -c safe.directory="$repo_root" -C "$repo_root" rev-parse --short HEAD 2>/dev/null || printf unknown)
source_epoch=${SOURCE_DATE_EPOCH:-}
[ -n "$source_epoch" ] || source_epoch=$(git -c safe.directory="$repo_root" -C "$repo_root" show -s --format=%ct HEAD)
case "$source_epoch" in ''|*[!0-9]*) echo 'invalid SOURCE_DATE_EPOCH' >&2; exit 2;; esac

(cd "$base_dir" && sha256sum -c checksums.sha256)
(cd "$system_dir" && sha256sum -c checksums.sha256)
(cd "${initramfs%/*}" && sha256sum -c checksums.sha256)
(cd "$frontend" && sha256sum -c components/frontend/checksums.sha256)

case "$work" in /work/work/mini-plus-frontend-image) ;; *) exit 2;; esac
find "$work" -depth -delete 2>/dev/null || true
mkdir -p "$work/boot" "$work/storage" "$out_dir"
cp -a "$repo_root/work/mini-plus-image/boot/." "$work/boot/"
cp -a "$frontend/." "$work/storage/plumos/"

install -m 0644 "$system_dir/SYSTEM" "$work/boot/SYSTEM"
install -m 0644 "$system_dir/SYSTEM.manifest" "$work/boot/SYSTEM.manifest"
system_sha=$(sha256sum "$system_dir/SYSTEM" | cut -d' ' -f1)
printf '%s  SYSTEM\n' "$system_sha" > "$work/boot/SYSTEM.sha256"
kernel_sha=$(sha256sum "$work/boot/Image" | cut -d' ' -f1)
dtb=$work/boot/dtbs/4.19.193-51-rockchip-gb2c01b3d79f2/rockchip/rk3566-gkdmini-pro.dtb
dtb_sha=$(sha256sum "$dtb" | cut -d' ' -f1)
initramfs_sha=$(sha256sum "$initramfs" | cut -d' ' -f1)
cat > "$work/boot/plumos-image.manifest" <<EOF
format=plumos-mini-plus-frontend-host-candidate-v1
device=gkd-mini-plus
architecture=aarch64
version=$version
source_ref=$source_ref
source_date_epoch=$source_epoch
boot_prefix_sha256=aa8bd95d5d75aaab1977c5e58732d67545221649a08e6b7afda36aee208e26e9
stock_kernel_sha256=$kernel_sha
stock_dtb_sha256=$dtb_sha
initramfs_sha256=$initramfs_sha
system_sha256=$system_sha
layout=raw-prefix-16MiB,p1-fat32-512MiB,p2-ext4-2048MiB
app_layer=frontend-only
emulator_runtime=incomplete
wifi=disabled-pending-matching-rtl8821cs-module
physical_boot_status=unverified
publishable=no
EOF

mkdir -p "$work/storage/plumos/logs" "$work/storage/plumos/state" \
    "$work/storage/plumos/saves" "$work/storage/plumos/states" \
    "$work/storage/plumos/config/frontend" "$work/storage/plumos/config/system" \
    "$work/storage/plumos/config/retroarch" "$work/storage/update-state"
cat > "$work/storage/plumos/manifest.json" <<EOF
{
  "name": "plumOS mini PLUS frontend-only bring-up layer",
  "device": "mini-plus",
  "version": "$version",
  "source_ref": "$source_ref",
  "source_date_epoch": $source_epoch,
  "managed_components": ["frontend"],
  "catalog_complete": false,
  "release_complete": false,
  "user_media_included": false,
  "publishable": false,
  "non_publishable_reasons": ["physical frontend acceptance incomplete", "emulator runtime not packaged", "Wi-Fi driver ABI unresolved"]
}
EOF
(
    cd "$work/storage/plumos"
    find . -type f ! -path './checksums.sha256' \
        ! -path './config/frontend/settings.json' \
        ! -path './config/system/settings.json' \
        ! -path './config/retroarch/*' \
        ! -path './logs/*' ! -path './state/*' ! -path './saves/*' ! -path './states/*' \
        -print | sed 's#^./##' | LC_ALL=C sort |
        while IFS= read -r path; do sha256sum "$path"; done
) > "$work/storage/plumos/checksums.sha256"
(cd "$work/storage/plumos" && sha256sum -c checksums.sha256)

image_path=$out_dir/plumOS-mini-PLUS-$version-frontend-host-candidate.img
boot_fat=$work/boot.fat
storage_ext4=$work/storage.ext4
cp "$base_image" "$image_path"
truncate -s 536870912 "$boot_fat"
truncate -s 2147483648 "$storage_ext4"
find "$work/boot" "$work/storage" -exec touch -h -d "@$source_epoch" {} +
SOURCE_DATE_EPOCH="$source_epoch" mkfs.vfat --invariant -F 32 -n PLUMBOOT \
    -i 42554242 "$boot_fat" >/dev/null
MTOOLS_SKIP_CHECK=1 mcopy -m -o -s -i "$boot_fat" "$work/boot/"* ::/
root_uuid=42554242-4c45-5359-5300-000000000002
E2FSPROGS_FAKE_TIME="$source_epoch" mkfs.ext4 -q -F -L PLUMOS_DATA \
    -U "$root_uuid" \
    -E lazy_itable_init=0,lazy_journal_init=0,hash_seed="$root_uuid" \
    -d "$work/storage" "$storage_ext4"
dd if="$boot_fat" of="$image_path" bs=512 seek=32768 conv=notrunc status=none
dd if="$storage_ext4" of="$image_path" bs=512 seek=1081344 conv=notrunc status=none
cmp -i 512:512 -n 16776704 \
    "$repo_root/artifacts/vendor/mini-plus-stock-source/rockchip-boot-prefix.bin" "$image_path"
fsck.fat -vn "$boot_fat" >/dev/null
e2fsck -fn "$storage_ext4" >/dev/null

image_sha=$(sha256sum "$image_path" | cut -d' ' -f1)
cat > "$out_dir/image.manifest" <<EOF
format=plumos-mini-plus-frontend-host-candidate-v1
file=$(basename "$image_path")
image_size=$(stat -c '%s' "$image_path")
image_sha256=$image_sha
source_ref=$source_ref
source_date_epoch=$source_epoch
p1_filesystem_sha256=$(sha256sum "$boot_fat" | cut -d' ' -f1)
p2_filesystem_sha256=$(sha256sum "$storage_ext4" | cut -d' ' -f1)
app_layer=frontend-only
physical_boot_status=unverified
publishable=no
EOF
(cd "$out_dir" && sha256sum "$(basename "$image_path")" image.manifest > checksums.sha256)
echo "miniplus_frontend_image=result-ok image=$image_path sha256=$image_sha"
