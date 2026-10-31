#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tools_image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}

if [ "${1:-}" != "--inside" ]; then
    "$repo_root/scripts/build-mini-plus-frontend-system.sh"
    "$repo_root/scripts/build-mini-plus-external-initramfs.sh"
    if [ "${PLUMOS_MINI_PLUS_APP_ASSEMBLE_ONLY:-0}" = 1 ]; then
        PLUMOS_MINI_PLUS_INCLUDE_CAPTURED_VENDOR_GPU=1 \
            "$repo_root/scripts/build-mini-plus-app-layer.sh" --assemble-only
    else
        PLUMOS_MINI_PLUS_INCLUDE_CAPTURED_VENDOR_GPU=1 \
            "$repo_root/scripts/build-mini-plus-app-layer.sh"
    fi
    exec docker run --rm --platform linux/arm64 \
        -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}" \
        -e PLUMOS_MINI_PLUS_VERSION="${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}" \
        -v "$repo_root:/work" -w /work "$tools_image" \
        ./scripts/build-mini-plus-frontend-probe-image.sh --inside
fi

repo_root=/work
stock=$repo_root/artifacts/vendor/mini-plus-stock-source
boot=$stock/boot
prefix=$stock/rockchip-boot-prefix.bin
system_dir=$repo_root/output/system-rootfs/mini-plus-frontend/payload
initramfs_dir=$repo_root/output/initramfs/mini-plus-external-probe/payload
app_dir=$repo_root/output/app-layer/mini-plus/plumos
out_dir=$repo_root/output/image/mini-plus-frontend-probe
work=$repo_root/work/mini-plus-frontend-probe-image
version=${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}
source_ref=$(git -c safe.directory="$repo_root" -C "$repo_root" rev-parse --short HEAD 2>/dev/null || printf unknown)
source_epoch=${SOURCE_DATE_EPOCH:-}
[ -n "$source_epoch" ] || source_epoch=$(git -c safe.directory="$repo_root" -C "$repo_root" show -s --format=%ct HEAD)
case "$source_epoch" in ''|*[!0-9]*) echo 'invalid SOURCE_DATE_EPOCH' >&2; exit 2;; esac

kernel_version=4.19.193-51-rockchip-gb2c01b3d79f2
initramfs_name=initramfs-plumos-mini-plus-external-probe.cpio.gz
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

case "$work" in /work/work/mini-plus-frontend-probe-image) ;; *) exit 2;; esac
find "$work" -depth -delete 2>/dev/null || true
mkdir -p "$work/flash/System" "$work/flash/plumos-probe/original" \
    "$work/runtime/plumos/logs" "$work/runtime/plumos/config" \
    "$work/runtime/plumos/ssh" "$work/runtime/update-state" \
    "$work/matching" "$out_dir"
cp -a "$app_dir/." "$work/runtime/plumos/"

dtb_source=$boot/dtbs/$kernel_version
for tree in "$work/flash" "$work/matching"; do
    dtb_root=$tree/dtbs/$kernel_version/rockchip
    mkdir -p "$dtb_root/overlay" "$dtb_root/not_gsensor" \
        "$dtb_root/with_gsensorHAT" "$dtb_root/with_gsensorJS"
    install -m 0644 "$boot/Image" "$tree/Image"
    python3 "$repo_root/scripts/patch-mini-plus-usb-sleep-kernel.py" \
        "$boot/Image" "$tree/Image-usb-sleep"
    mkdir -p "$tree/overlay-user"
    dtc -@ -I dts -O dtb \
        -o "$tree/overlay-user/mini-plus-sd1-sdr104.dtbo" \
        "$repo_root/configs/device-tree/mini-plus-sd1-sdr104-overlay.dts"
    install -m 0644 "$dtb_source/rockchip/rk3566-gkdmini-pro.dtb" "$dtb_root/"
    install -m 0644 "$dtb_source/rockchip/not_gsensor/rk3566-gkdmini-pro.dtb" \
        "$dtb_root/not_gsensor/"
    install -m 0644 "$dtb_source/rockchip/with_gsensorHAT/rk3566-gkdmini-pro.dtb" \
        "$dtb_root/with_gsensorHAT/"
    install -m 0644 "$dtb_source/rockchip/with_gsensorJS/rk3566-gkdmini-pro.dtb" \
        "$dtb_root/with_gsensorJS/"
    for file in rk3568-fiq-debugger-uart2m0.dtbo rk3568-disable-npu.dtbo rockchip-fixup.scr; do
        install -m 0644 "$dtb_source/rockchip/overlay/$file" "$dtb_root/overlay/"
    done
    install -m 0644 "$initramfs" "$tree/$initramfs_name"
done

install -m 0644 "$system_dir/SYSTEM" "$work/flash/System/system-a.squashfs"
install -m 0644 "$system_dir/SYSTEM" "$work/flash/System/system-b.squashfs"
system_sha=$(sha256sum "$system_dir/SYSTEM" | cut -d' ' -f1)
printf '%s  system-a.squashfs\n' "$system_sha" > "$work/flash/System/system-a.sha256"
printf '%s  system-b.squashfs\n' "$system_sha" > "$work/flash/System/system-b.sha256"
printf 'a\n' > "$work/flash/System/active-slot"
install -m 0644 "$system_dir/SYSTEM.manifest" "$work/flash/System/SYSTEM.manifest"
install -m 0644 "$boot/boot.cmd" "$work/flash/plumos-probe/original/boot.cmd"
install -m 0644 "$boot/boot.scr" "$work/flash/plumos-probe/original/boot.scr"
printf '%s\n' PLUMOS_MINI_PLUS_EXTERNAL_INITRAMFS_PROBE_V1 \
    > "$work/flash/plumos-probe/external-initramfs-authorized.txt"

cat > "$work/matching/matching-bundle.manifest" <<EOF
format=plumos-mini-plus-raw-matching-bundle-v2
device=mini-plus
version=$version
source_ref=$source_ref
source_date_epoch=$source_epoch
container=newc-padded-to-partition
boot_source_in_this_gate=p1-file
p2_boot_source=p1-file
p2_integrity_role=full-matching-set-readback
active_kernel=Image-usb-sleep
active_kernel_sha256=$(sha256sum "$work/matching/Image-usb-sleep" | cut -d' ' -f1)
sd1_overlay=overlay-user/mini-plus-sd1-sdr104.dtbo
final_p2_format=raw-newc-padded-to-64MiB
publishable=no
EOF
(cd "$work/matching" && find . -type f ! -name checksums.sha256 -print | \
    LC_ALL=C sort | sed 's#^./##' | xargs sha256sum > checksums.sha256)
find "$work/matching" -exec touch -h -d "@$source_epoch" {} +
python3 "$repo_root/scripts/pack-mini-plus-initramfs.py" --uncompressed \
    --mtime "$source_epoch" "$work/matching" "$work/matching-bundle.cpio"

boot_start=32768
boot_sectors=1048576
matching_start=1081344
matching_sectors=131072
runtime_start=1212416
matching_bytes=$((matching_sectors * 512))
app_bytes=$(du -sb "$app_dir" | awk '{print $1}')
runtime_headroom_bytes=268435456
runtime_alignment_bytes=134217728
runtime_required_bytes=$((app_bytes + runtime_headroom_bytes))
runtime_bytes=$(( \
    (runtime_required_bytes + runtime_alignment_bytes - 1) / runtime_alignment_bytes * runtime_alignment_bytes \
))
runtime_sectors=$((runtime_bytes / 512))
runtime_seed_mib=$((runtime_bytes / 1048576))
# Early userspace deliberately admits only the geometry that has interruption
# and resume fixtures. App growth must update that contract and its tests rather
# than silently producing a different partition map.
test "$runtime_seed_mib" -eq 2176 || {
    echo "calculated p3 seed is ${runtime_seed_mib} MiB; update the validated storage contract" >&2
    exit 1
}
total_sectors=$((runtime_start + runtime_sectors))
test "$(stat -c '%s' "$work/matching-bundle.cpio")" -lt "$matching_bytes"
truncate -s "$matching_bytes" "$work/matching.raw"
dd if="$work/matching-bundle.cpio" of="$work/matching.raw" \
    bs=1M conv=notrunc status=none
matching_sha=$(sha256sum "$work/matching.raw" | cut -d' ' -f1)

python3 "$repo_root/scripts/instrument-mini-plus-boot-script.py" \
    --external-initramfs "$boot/boot.cmd" "$work/instrumented"
install -m 0644 "$work/instrumented/boot.cmd" "$work/flash/boot.cmd"
install -m 0644 "$work/instrumented/boot.scr" "$work/flash/boot.scr"
initramfs_size=$(stat -c '%s' "$initramfs")
initramfs_size_hex=$(printf '0x%x' "$initramfs_size")
sed \
    -e 's/^rootuuid=.*/rootuuid=42554242-4c45-5359-5300-000000000003/' \
    -e 's/^kernelimg=.*/kernelimg=Image-usb-sleep/' \
    -e '/^user_overlays=/d' \
    "$boot/uEnv.txt" > "$work/flash/uEnv.txt"
cat >> "$work/flash/uEnv.txt" <<EOF
initrdimg=$initramfs_name
initrdsize=$initramfs_size_hex
extraboardargs=plumos_external_initramfs_probe=1 plumos_probe_p2_sha256=$matching_sha
user_overlays=mini-plus-sd1-sdr104
EOF

cat > "$work/runtime/plumos/external-initramfs-probe.manifest" <<EOF
format=plumos-mini-plus-full-stack-runtime-validation-v3
authorized=yes
device=mini-plus
version=$version
source_ref=$source_ref
source_date_epoch=$source_epoch
runtime_policy=managed-runtime-log-device-config-and-separate-userdata
app_layer=frontend,nextcommander,music-player,network-services,retroarch,libretro-cores,picoarch,standalone,pyxel,portmaster
frontend_boot=automatic
partition_expansion=p3-seed-${runtime_seed_mib}MiB-to-8192MiB
p4_creation=first-boot-fat32-PLUMOS
publishable=no
EOF

cat > "$work/flash/plumos-image.manifest" <<EOF
format=plumos-mini-plus-full-stack-validation-image-v3
device=mini-plus
architecture=aarch64
version=$version
source_ref=$source_ref
source_date_epoch=$source_epoch
boot_prefix_sha256=$expected_prefix
stock_image_sha256=$(sha256sum "$boot/Image" | cut -d' ' -f1)
active_kernel=Image-usb-sleep
active_kernel_sha256=$(sha256sum "$work/flash/Image-usb-sleep" | cut -d' ' -f1)
kernel_patch=usb-charge-suspend-veto-single-instruction
sd1_overlay_sha256=$(sha256sum "$work/flash/overlay-user/mini-plus-sd1-sdr104.dtbo" | cut -d' ' -f1)
sd1_mode=SDR104
external_initramfs_sha256=$(sha256sum "$initramfs" | cut -d' ' -f1)
system_a_sha256=$system_sha
system_b_sha256=$system_sha
p2_raw_partition_sha256=$matching_sha
layout=validation-seed-v3,raw-prefix-16MiB,p1-fat32-512MiB,p2-raw-64MiB,p3-ext4-${runtime_seed_mib}MiB,no-p4
boot_source=p1-file
matching_bundle=full-kernel-dtb-initramfs-set-verified-before-switch-root
app_layer_sha256=$(sha256sum "$app_dir/checksums.sha256" | cut -d' ' -f1)
app_layer_bytes=$app_bytes
p3_minimum_headroom_bytes=$runtime_headroom_bytes
p3_size_calculation=ceil-app-plus-headroom-to-128MiB
frontend=cpu-drm-dumb-buffer
retroarch=software-plain-drm-and-hardware-kms-egl-gles-rgui
core_baseline=all-114-source-records
catalog_systems=97
catalog_launch_profile_occurrences=196
user_media_included=no
managed_firmware_assets=blueMSX-C-BIOS,DraStic-packaged-BIOS-project-approved-inclusion
p2_direct_boot=not-required-p1-file-boot-with-p2-full-set-verification
partition_expansion=first-boot-p3-to-8192MiB
p4_creation=first-boot-fat32-PLUMOS-to-card-end
minimum_card_size_mib=14336
final_partition_contract=host-candidate
physical_boot_status=unverified-full-image
publishable=no
EOF

image_path=$out_dir/plumOS-mini-PLUS-$version-full-stack-validation.img
boot_fat=$work/flash.fat
runtime_ext4=$work/runtime.ext4
truncate -s "$((total_sectors * 512))" "$image_path"
dd if="$prefix" of="$image_path" bs=1M count=16 conv=notrunc status=none
parted -s "$image_path" unit s mklabel msdos \
    mkpart primary fat32 "${boot_start}s" "$((boot_start + boot_sectors - 1))s" \
    mkpart primary ext2 "${matching_start}s" "$((matching_start + matching_sectors - 1))s" \
    mkpart primary ext4 "${runtime_start}s" "$((runtime_start + runtime_sectors - 1))s" \
    set 1 boot on 2> "$work/parted.stderr"
grep -v 'udevadm: not found' "$work/parted.stderr" >&2 || true
printf '\102\125\102\114' | dd of="$image_path" bs=1 seek=440 conv=notrunc status=none

truncate -s "$((boot_sectors * 512))" "$boot_fat"
truncate -s "$((runtime_sectors * 512))" "$runtime_ext4"
SOURCE_DATE_EPOCH="$source_epoch" mkfs.vfat --invariant -F 32 -n PLUMBOOT \
    -i 42554242 "$boot_fat" >/dev/null
find "$work/flash" "$work/runtime" -exec touch -h -d "@$source_epoch" {} +
E2FSPROGS_FAKE_TIME="$source_epoch" mkfs.ext4 -q -F -L PLUMOS_SYS \
    -U 42554242-4c45-5359-5300-000000000003 \
    -E lazy_itable_init=0,lazy_journal_init=0,hash_seed=42554242-4c45-5359-5300-000000000003 \
    -d "$work/runtime" "$runtime_ext4"
for ext4_path in /plumos /plumos/logs /plumos/config /plumos/ssh \
    /plumos/external-initramfs-probe.manifest /update-state; do
    debugfs -w -R "set_inode_field $ext4_path ctime @$source_epoch" \
        "$runtime_ext4" >/dev/null 2>&1
done
MTOOLS_SKIP_CHECK=1 mcopy -m -o -s -i "$boot_fat" "$work/flash/"* ::/

dd if="$boot_fat" of="$image_path" bs=512 seek="$boot_start" conv=notrunc status=none
dd if="$work/matching.raw" of="$image_path" bs=512 seek="$matching_start" conv=notrunc status=none
dd if="$runtime_ext4" of="$image_path" bs=512 seek="$runtime_start" conv=notrunc status=none
cmp -i 512:512 -n 16776704 "$prefix" "$image_path"
fsck.fat -vn "$boot_fat" >/dev/null
e2fsck -fn "$runtime_ext4" >/dev/null

image_size=$(stat -c '%s' "$image_path")
image_sha=$(sha256sum "$image_path" | cut -d' ' -f1)
cat > "$out_dir/image.manifest" <<EOF
format=plumos-mini-plus-full-stack-validation-image-v3
file=$(basename "$image_path")
image_size=$image_size
image_sha256=$image_sha
source_ref=$source_ref
source_date_epoch=$source_epoch
boot_prefix_sha256=$expected_prefix
p1_filesystem_sha256=$(sha256sum "$boot_fat" | cut -d' ' -f1)
active_kernel=Image-usb-sleep
active_kernel_sha256=$(sha256sum "$work/flash/Image-usb-sleep" | cut -d' ' -f1)
sd1_overlay_sha256=$(sha256sum "$work/flash/overlay-user/mini-plus-sd1-sdr104.dtbo" | cut -d' ' -f1)
p2_raw_partition_sha256=$matching_sha
p3_filesystem_sha256=$(sha256sum "$runtime_ext4" | cut -d' ' -f1)
app_layer_bytes=$app_bytes
p3_seed_mib=$runtime_seed_mib
p3_minimum_headroom_bytes=$runtime_headroom_bytes
first_boot_p3_target_mib=8192
first_boot_p4_label=PLUMOS
minimum_card_size_mib=14336
final_partition_contract=host-candidate
physical_boot_status=unverified-full-image
publishable=no
EOF
(cd "$out_dir" && sha256sum "$(basename "$image_path")" image.manifest > checksums.sha256)
echo "miniplus_frontend_probe_image=result-ok image=$image_path sha256=$image_sha"
