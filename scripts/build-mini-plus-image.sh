#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tools_image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}

if [ "${1:-}" != "--inside" ]; then
    "$repo_root/scripts/build-mini-plus-minimal-system.sh"
    "$repo_root/scripts/build-mini-plus-boot-initramfs.sh"
    exec docker run --rm --platform linux/arm64 \
        -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}" \
        -e PLUMOS_MINI_PLUS_VERSION="${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}" \
        -v "$repo_root:/work" -w /work "$tools_image" \
        ./scripts/build-mini-plus-image.sh --inside
fi

repo_root=/work
stock=$repo_root/artifacts/vendor/mini-plus-stock-source
boot=$stock/boot
prefix=$stock/rockchip-boot-prefix.bin
system_dir=$repo_root/output/system-rootfs/mini-plus-minimal/payload
initramfs_dir=$repo_root/output/initramfs/mini-plus-boot/payload
out_dir=$repo_root/output/image/mini-plus
work=$repo_root/work/mini-plus-image
version=${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}
source_ref=$(git -c safe.directory="$repo_root" -C "$repo_root" rev-parse --short HEAD 2>/dev/null || printf unknown)
source_epoch=${SOURCE_DATE_EPOCH:-}
[ -n "$source_epoch" ] || source_epoch=$(git -c safe.directory="$repo_root" -C "$repo_root" show -s --format=%ct HEAD)
case "$source_epoch" in ''|*[!0-9]*) echo 'invalid SOURCE_DATE_EPOCH' >&2; exit 2;; esac

kernel_version=4.19.193-51-rockchip-gb2c01b3d79f2
kernel_release=4.19.193-g5a07852a55cf-dirty
initramfs_name=initramfs-plumos-mini-plus.cpio.gz
initramfs=$initramfs_dir/$initramfs_name
expected_prefix=aa8bd95d5d75aaab1977c5e58732d67545221649a08e6b7afda36aee208e26e9
test "$(stat -c '%s' "$prefix")" -eq 16777216
test "$(sha256sum "$prefix" | cut -d' ' -f1)" = "$expected_prefix"
(cd "$system_dir" && sha256sum -c checksums.sha256)
(cd "$initramfs_dir" && sha256sum -c checksums.sha256)

verify_registered() {
    registered_name=$1
    artifact=$2
    expected=$(awk -v name="$registered_name" '$2 == name {print $1}' \
        "$repo_root/configs/mini-plus-stock-active-boot.expected.sha256")
    actual=$(sha256sum "$artifact" | cut -d' ' -f1)
    test -n "$expected"
    test "$actual" = "$expected"
}
verify_registered Image "$boot/Image"
verify_registered boot.cmd "$boot/boot.cmd"
verify_registered boot.scr "$boot/boot.scr"
verify_registered uEnv.txt "$boot/uEnv.txt"
verify_registered rk3566-gkdmini-pro.dtb \
    "$boot/dtbs/$kernel_version/rockchip/rk3566-gkdmini-pro.dtb"
verify_registered rk3566-gkdmini-pro-not-gsensor.dtb \
    "$boot/dtbs/$kernel_version/rockchip/not_gsensor/rk3566-gkdmini-pro.dtb"
verify_registered rk3566-gkdmini-pro-gsensor-hat.dtb \
    "$boot/dtbs/$kernel_version/rockchip/with_gsensorHAT/rk3566-gkdmini-pro.dtb"
verify_registered rk3566-gkdmini-pro-gsensor-js.dtb \
    "$boot/dtbs/$kernel_version/rockchip/with_gsensorJS/rk3566-gkdmini-pro.dtb"
verify_registered rk3568-fiq-debugger-uart2m0.dtbo \
    "$boot/dtbs/$kernel_version/rockchip/overlay/rk3568-fiq-debugger-uart2m0.dtbo"
verify_registered rk3568-disable-npu.dtbo \
    "$boot/dtbs/$kernel_version/rockchip/overlay/rk3568-disable-npu.dtbo"
verify_registered rockchip-fixup.scr \
    "$boot/dtbs/$kernel_version/rockchip/overlay/rockchip-fixup.scr"

case "$work" in /work/work/mini-plus-image) ;; *) exit 2;; esac
find "$work" -depth -delete 2>/dev/null || true
mkdir -p "$work/boot/plumos-probe/original" "$work/storage/plumos/logs" \
    "$work/storage/plumos/config" "$work/storage/plumos/ssh" \
    "$work/storage/update-state" "$out_dir"

dtb_source=$boot/dtbs/$kernel_version/rockchip
dtb_target=$work/boot/dtbs/$kernel_version/rockchip
mkdir -p "$dtb_target/overlay" "$dtb_target/not_gsensor" \
    "$dtb_target/with_gsensorHAT" "$dtb_target/with_gsensorJS"
install -m 0644 "$boot/Image" "$work/boot/Image"
install -m 0644 "$dtb_source/rk3566-gkdmini-pro.dtb" "$dtb_target/"
install -m 0644 "$dtb_source/not_gsensor/rk3566-gkdmini-pro.dtb" "$dtb_target/not_gsensor/"
install -m 0644 "$dtb_source/with_gsensorHAT/rk3566-gkdmini-pro.dtb" "$dtb_target/with_gsensorHAT/"
install -m 0644 "$dtb_source/with_gsensorJS/rk3566-gkdmini-pro.dtb" "$dtb_target/with_gsensorJS/"
for file in rk3568-fiq-debugger-uart2m0.dtbo rk3568-disable-npu.dtbo rockchip-fixup.scr; do
    install -m 0644 "$dtb_source/overlay/$file" "$dtb_target/overlay/"
done
install -m 0644 "$initramfs" "$work/boot/$initramfs_name"
install -m 0644 "$system_dir/SYSTEM" "$work/boot/SYSTEM"
system_sha=$(sha256sum "$system_dir/SYSTEM" | cut -d' ' -f1)
printf '%s  SYSTEM\n' "$system_sha" > "$work/boot/SYSTEM.sha256"
install -m 0644 "$system_dir/SYSTEM.manifest" "$work/boot/SYSTEM.manifest"
install -m 0644 "$boot/boot.cmd" "$work/boot/plumos-probe/original/boot.cmd"
install -m 0644 "$boot/boot.scr" "$work/boot/plumos-probe/original/boot.scr"
python3 "$repo_root/scripts/instrument-mini-plus-boot-script.py" \
    --external-initramfs "$boot/boot.cmd" "$work/instrumented"
install -m 0644 "$work/instrumented/boot.cmd" "$work/boot/boot.cmd"
install -m 0644 "$work/instrumented/boot.scr" "$work/boot/boot.scr"

root_uuid=42554242-4c45-5359-5300-000000000002
initramfs_size=$(stat -c '%s' "$initramfs")
initramfs_size_hex=$(printf '0x%x' "$initramfs_size")
sed -e "s/^rootuuid=.*/rootuuid=$root_uuid/" "$boot/uEnv.txt" > "$work/boot/uEnv.txt"
cat >> "$work/boot/uEnv.txt" <<EOF
initrdimg=$initramfs_name
initrdsize=$initramfs_size_hex
extraboardargs=plumos_mini_plus=1
EOF

cat > "$work/boot/plumos-image.manifest" <<EOF
format=plumos-mini-plus-host-candidate-v1
device=gkd-mini-plus
architecture=aarch64
version=$version
source_ref=$source_ref
source_date_epoch=$source_epoch
boot_prefix_sha256=$expected_prefix
stock_kernel_sha256=$(sha256sum "$boot/Image" | cut -d' ' -f1)
stock_dtb_sha256=$(sha256sum "$dtb_source/rk3566-gkdmini-pro.dtb" | cut -d' ' -f1)
initramfs_sha256=$(sha256sum "$initramfs" | cut -d' ' -f1)
system_sha256=$system_sha
kernel_release=$kernel_release
layout=raw-prefix-16MiB,p1-fat32-512MiB,p2-ext4-2048MiB
boot_source=p1-external-initramfs
stock_root_partition_required=no
wifi=disabled-pending-matching-rtl8821cs-module
physical_boot_status=unverified
publishable=no
EOF

cat > "$work/storage/plumos/candidate.manifest" <<EOF
format=plumos-mini-plus-storage-v1
device=gkd-mini-plus
version=$version
source_ref=$source_ref
source_date_epoch=$source_epoch
purpose=configuration-logs-and-user-data
physical_boot_status=unverified
EOF

boot_start=32768
boot_sectors=1048576
storage_start=$((boot_start + boot_sectors))
storage_sectors=4194304
total_sectors=$((storage_start + storage_sectors))
image_path=$out_dir/plumOS-mini-PLUS-$version-host-candidate.img
boot_fat=$work/boot.fat
storage_ext4=$work/storage.ext4
truncate -s "$((total_sectors * 512))" "$image_path"
dd if="$prefix" of="$image_path" bs=1M count=16 conv=notrunc status=none
parted -s "$image_path" unit s mklabel msdos \
    mkpart primary fat32 "${boot_start}s" "$((storage_start - 1))s" \
    mkpart primary ext4 "${storage_start}s" "$((total_sectors - 1))s" \
    set 1 boot on 2> "$work/parted.stderr"
grep -v 'udevadm: not found' "$work/parted.stderr" >&2 || true
printf '\102\125\102\114' | dd of="$image_path" bs=1 seek=440 conv=notrunc status=none

truncate -s "$((boot_sectors * 512))" "$boot_fat"
truncate -s "$((storage_sectors * 512))" "$storage_ext4"
SOURCE_DATE_EPOCH="$source_epoch" mkfs.vfat --invariant -F 32 -n PLUMBOOT \
    -i 42554242 "$boot_fat" >/dev/null
find "$work/boot" "$work/storage" -exec touch -h -d "@$source_epoch" {} +
E2FSPROGS_FAKE_TIME="$source_epoch" mkfs.ext4 -q -F -L PLUMOS_DATA \
    -U "$root_uuid" \
    -E lazy_itable_init=0,lazy_journal_init=0,hash_seed="$root_uuid" \
    -d "$work/storage" "$storage_ext4"
for ext4_path in /plumos /plumos/logs /plumos/config /plumos/ssh \
    /plumos/candidate.manifest /update-state; do
    debugfs -w -R "set_inode_field $ext4_path ctime @$source_epoch" \
        "$storage_ext4" >/dev/null 2>&1
done
MTOOLS_SKIP_CHECK=1 mcopy -m -o -s -i "$boot_fat" "$work/boot/"* ::/

dd if="$boot_fat" of="$image_path" bs=512 seek="$boot_start" conv=notrunc status=none
dd if="$storage_ext4" of="$image_path" bs=512 seek="$storage_start" conv=notrunc status=none
cmp -i 512:512 -n 16776704 "$prefix" "$image_path"
fsck.fat -vn "$boot_fat" >/dev/null
e2fsck -fn "$storage_ext4" >/dev/null

image_size=$(stat -c '%s' "$image_path")
image_sha=$(sha256sum "$image_path" | cut -d' ' -f1)
cat > "$out_dir/image.manifest" <<EOF
format=plumos-mini-plus-host-candidate-v1
file=$(basename "$image_path")
image_size=$image_size
image_sha256=$image_sha
source_ref=$source_ref
source_date_epoch=$source_epoch
boot_prefix_sha256=$expected_prefix
p1_filesystem_sha256=$(sha256sum "$boot_fat" | cut -d' ' -f1)
p2_filesystem_sha256=$(sha256sum "$storage_ext4" | cut -d' ' -f1)
physical_boot_status=unverified
publishable=no
EOF
(cd "$out_dir" && sha256sum "$(basename "$image_path")" image.manifest > checksums.sha256)
echo "miniplus_image=result-ok image=$image_path sha256=$image_sha"
