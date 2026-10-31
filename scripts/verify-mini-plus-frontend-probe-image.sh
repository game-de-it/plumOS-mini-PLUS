#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tools_image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}

if [ "${1:-}" != "--inside" ]; then
    image=${1:-$repo_root/output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.img}
    case "$image" in "$repo_root"/*) ;; *) echo 'image must be under repository' >&2; exit 2;; esac
    relative=${image#"$repo_root"/}
    "$repo_root/tests/test-mini-plus-first-boot-storage.sh"
    sh "$repo_root/tests/test-mini-plus-boot-progress.sh"
    exec docker run --rm --platform linux/arm64 \
        -e PLUMOS_MINI_PLUS_VERIFY_IMAGE="/work/$relative" \
        -v "$repo_root:/work" -w /work "$tools_image" \
        ./scripts/verify-mini-plus-frontend-probe-image.sh --inside
fi

repo_root=/work
image=${PLUMOS_MINI_PLUS_VERIFY_IMAGE:?}
prefix=$repo_root/artifacts/vendor/mini-plus-stock-source/rockchip-boot-prefix.bin
boot_source=$repo_root/artifacts/vendor/mini-plus-stock-source/boot
system=$repo_root/output/system-rootfs/mini-plus-frontend/payload/SYSTEM
initramfs=$repo_root/output/initramfs/mini-plus-external-probe/payload/initramfs-plumos-mini-plus-external-probe.cpio.gz
base_manifest=${image%/*}/image.manifest
personalized_manifest=$image.manifest
manifest=$base_manifest
personalized=no
if [ -f "$personalized_manifest" ] && \
    grep -q '^format=plumos-mini-plus-personalized-full-stack-validation-v3$' \
        "$personalized_manifest"; then
    manifest=$personalized_manifest
    personalized=yes
    base_image_sha=$(awk -F= '$1 == "base_image_sha256" {print $2}' "$manifest")
    test "$base_image_sha" = \
        "$(awk -F= '$1 == "image_sha256" {print $2}' "$base_manifest")"
    grep -q '^credential_hash_recorded=no$' "$manifest"
    grep -q '^publishable=no$' "$manifest"
fi
verify=$repo_root/work/mini-plus-frontend-probe-verify
find "$verify" -depth -delete 2>/dev/null || true
mkdir -p "$verify/matching" "$verify/initramfs"

expected_size=$(awk -F= '$1 == "image_size" {print $2}' "$manifest")
expected_sha=$(awk -F= '$1 == "image_sha256" {print $2}' "$manifest")
expected_p2_sha=$(awk -F= '$1 == "p2_raw_partition_sha256" {print $2}' "$base_manifest")
grep -q '^format=plumos-mini-plus-full-stack-validation-image-v3$' "$base_manifest"
test "$expected_size" -eq 2902458368
test "$(stat -c '%s' "$image")" = "$expected_size"
test "$(sha256sum "$image" | cut -d' ' -f1)" = "$expected_sha"

parted -ms "$image" unit s print > "$verify/partitions.txt"
grep -q '^1:32768s:1081343s:1048576s:fat32::boot, lba;$' "$verify/partitions.txt"
grep -q '^2:1081344s:1212415s:131072s:::;$' "$verify/partitions.txt"
grep -q '^3:1212416s:5668863s:4456448s:ext4::;$' "$verify/partitions.txt"
! grep -q '^4:' "$verify/partitions.txt"
cmp -i 512:512 -n 16776704 "$prefix" "$image"

# Same sector ranges as the partition assertions above, with MiB-sized I/O.
dd if="$image" of="$verify/flash.fat" bs=1M skip=16 count=512 status=none
dd if="$image" of="$verify/matching.raw" bs=1M skip=528 count=64 status=none
dd if="$image" of="$verify/runtime.ext4" bs=1M skip=592 count=2176 status=none
test "$(sha256sum "$verify/matching.raw" | cut -d' ' -f1)" = "$expected_p2_sha"
test "$(dd if="$verify/matching.raw" bs=1 count=6 status=none)" = 070701
test -z "$(blkid -p -s TYPE -o value "$verify/matching.raw" 2>/dev/null || true)"
test "$(blkid -s LABEL -o value "$verify/flash.fat")" = PLUMBOOT
test "$(blkid -s LABEL -o value "$verify/runtime.ext4")" = PLUMOS_SYS
fsck.fat -vn "$verify/flash.fat" >/dev/null
e2fsck -fn "$verify/runtime.ext4" >/dev/null

(cd "$verify/matching" && /bin/busybox cpio -idm < "$verify/matching.raw" 2>/dev/null)
(cd "$verify/matching" && sha256sum -c checksums.sha256)
cmp "$boot_source/Image" "$verify/matching/Image"
python3 "$repo_root/scripts/patch-mini-plus-usb-sleep-kernel.py" \
    "$boot_source/Image" "$verify/expected-Image-usb-sleep"
cmp "$verify/expected-Image-usb-sleep" "$verify/matching/Image-usb-sleep"
MTOOLS_SKIP_CHECK=1 mcopy -i "$verify/flash.fat" ::/Image "$verify/stock-Image"
MTOOLS_SKIP_CHECK=1 mcopy -i "$verify/flash.fat" \
    ::/Image-usb-sleep "$verify/active-Image"
cmp "$boot_source/Image" "$verify/stock-Image"
cmp "$verify/expected-Image-usb-sleep" "$verify/active-Image"
MTOOLS_SKIP_CHECK=1 mcopy -i "$verify/flash.fat" \
    ::/overlay-user/mini-plus-sd1-sdr104.dtbo "$verify/sd1-sdr104.dtbo"
dtc -@ -I dts -O dtb -o "$verify/expected-sd1-sdr104.dtbo" \
    "$repo_root/configs/device-tree/mini-plus-sd1-sdr104-overlay.dts"
cmp "$verify/expected-sd1-sdr104.dtbo" "$verify/sd1-sdr104.dtbo"
cmp "$verify/sd1-sdr104.dtbo" \
    "$verify/matching/overlay-user/mini-plus-sd1-sdr104.dtbo"
# The vendor boot DTB is encoded for its U-Boot and is verified byte-for-byte
# above. Apply the overlay to the captured decoded live FDT for semantic checks.
runtime_dtb=$repo_root/artifacts/vendor/mini-plus-stock-source/runtime-live/runtime.dtb
test "$(sha256sum "$runtime_dtb" | cut -d' ' -f1)" = \
    9112f81c3d1d84cff15a1120a834adb66aeb394a9783cc542e6fad318d78f3e0
fdtoverlay -i "$runtime_dtb" \
    -o "$verify/sdr104-merged.dtb" "$verify/sd1-sdr104.dtbo"
fdtget -p "$verify/sdr104-merged.dtb" /dwmmc@fe2b0000 | grep -qx sd-uhs-sdr104
python3 "$repo_root/scripts/compare-fdt.py" "$runtime_dtb" \
    "$verify/sdr104-merged.dtb" >"$verify/sdr104-properties.diff"
test "$(wc -l <"$verify/sdr104-properties.diff")" -eq 2
grep -qx 'ADDED /dwmmc@fe2b0000:sd-uhs-sdr104 = <empty>' \
    "$verify/sdr104-properties.diff"
test "$(sha256sum "$verify/active-Image" | cut -d' ' -f1)" = \
    "$(awk -F= '$1 == "active_kernel_sha256" {print $2}' "$base_manifest")"
test "$(sha256sum "$verify/sd1-sdr104.dtbo" | cut -d' ' -f1)" = \
    "$(awk -F= '$1 == "sd1_overlay_sha256" {print $2}' "$base_manifest")"
cmp "$initramfs" "$verify/matching/initramfs-plumos-mini-plus-external-probe.cpio.gz"
dtb_root=dtbs/4.19.193-51-rockchip-gb2c01b3d79f2/rockchip
for relative in \
    rk3566-gkdmini-pro.dtb \
    not_gsensor/rk3566-gkdmini-pro.dtb \
    with_gsensorHAT/rk3566-gkdmini-pro.dtb \
    with_gsensorJS/rk3566-gkdmini-pro.dtb \
    overlay/rk3568-fiq-debugger-uart2m0.dtbo \
    overlay/rk3568-disable-npu.dtbo \
    overlay/rockchip-fixup.scr; do
    cmp "$boot_source/$dtb_root/$relative" "$verify/matching/$dtb_root/$relative"
done
grep -q '^p2_integrity_role=full-matching-set-readback$' \
    "$verify/matching/matching-bundle.manifest"
grep -q '^final_p2_format=raw-newc-padded-to-64MiB$' \
    "$verify/matching/matching-bundle.manifest"

MTOOLS_SKIP_CHECK=1 mcopy -i "$verify/flash.fat" \
    ::/System/system-a.squashfs "$verify/system-a.squashfs"
MTOOLS_SKIP_CHECK=1 mcopy -i "$verify/flash.fat" \
    ::/System/system-b.squashfs "$verify/system-b.squashfs"
cmp "$system" "$verify/system-a.squashfs"
cmp "$system" "$verify/system-b.squashfs"
unsquashfs -d "$verify/system-root" "$verify/system-a.squashfs" >/dev/null
for stage in S39_APP_LAYER_METADATA_READY S40_FRONTEND_SUPERVISOR_READY \
    S41_FRONTEND_START S43_FRONTEND_INTENTIONAL_HOLD \
    S88_RECOVERY_POWER_WATCH_READY S89_RECOVERY_POWER_REQUEST \
    S90_POWER_FINALIZE_BEGIN S90_POWER_FINALIZE_ALREADY_CLAIMED \
    E39_APP_LAYER_METADATA_MISSING \
    E39_FRONTEND_REQUIRED_FILE_MISSING E39_FRONTEND_LAUNCHER_NOT_EXECUTABLE \
    E80_FRONTEND_EXIT E81_FRONTEND_RESTART_LIMIT_RECOVERY_CONSOLE; do
    grep -q "$stage" "$verify/system-root/init"
done
! grep -q 'sha256sum -c checksums.sha256' "$verify/system-root/init"
MTOOLS_SKIP_CHECK=1 mtype -i "$verify/flash.fat" ::/System/active-slot | grep -qx a
MTOOLS_SKIP_CHECK=1 mtype -i "$verify/flash.fat" ::/uEnv.txt > "$verify/uEnv.txt"
grep -q '^rootuuid=42554242-4c45-5359-5300-000000000003$' "$verify/uEnv.txt"
grep -qx 'kernelimg=Image-usb-sleep' "$verify/uEnv.txt"
grep -qx 'user_overlays=mini-plus-sd1-sdr104' "$verify/uEnv.txt"
grep -q '^initrdimg=initramfs-plumos-mini-plus-external-probe.cpio.gz$' "$verify/uEnv.txt"
grep -q "plumos_probe_p2_sha256=$expected_p2_sha" "$verify/uEnv.txt"
MTOOLS_SKIP_CHECK=1 mcopy -i "$verify/flash.fat" ::/boot.cmd "$verify/boot.cmd"
for stage in S10 S11 S12 E12 S13 E13 S14 E14 S15 S19 E20; do
    grep -q "$stage" "$verify/boot.cmd"
done
! grep -q fatwrite "$verify/boot.cmd"

gzip -dc "$initramfs" | (cd "$verify/initramfs" && /bin/busybox cpio -idm 2>/dev/null)
for stage in S21 S22 S23 S24 S25 S26 S27 S28 S29 \
    E23 E24 E25 E26 E27 E28 E29; do
    grep -q "$stage" "$verify/initramfs/init"
done
test "$(stat -c '%a' "$verify/initramfs/init")" = 755
test "$(stat -c '%a' "$verify/initramfs/usr/sbin/plumos-mini-plus-provision-storage")" = 755
test -x "$verify/initramfs/usr/sbin/plumos-mini-plus-boot-progress"
test -x "$verify/initramfs/usr/sbin/plumos-mini-plus-system-slot"
MTOOLS_SKIP_CHECK=1 mtype -i "$verify/flash.fat" ::/System/slot-policy | grep -qx trial-v1
for phase in provision-start provision-p3-check provision-p3-resize \
    provision-p3-recheck provision-p4-create provision-p4-check provision-complete boot-error; do
    test "$(stat -c '%s' "$verify/initramfs/usr/share/plumos/boot-progress/$phase.raw")" -eq 1228800
done
for stage in S24A S24B S24C S24D E24A E24B E24C E24D; do
    grep -q "$stage" \
        "$verify/initramfs/usr/sbin/plumos-mini-plus-provision-storage"
done
for tool in parted partprobe e2fsck resize2fs mkfs.fat fsck.fat; do
    test -x "$verify/initramfs/usr/sbin/$tool"
done
grep -q 'BLANK_P4_WITHOUT_DURABLE_INTENT' \
    "$verify/initramfs/usr/sbin/plumos-mini-plus-provision-storage"
readelf -h "$verify/initramfs/bin/busybox" | grep -q 'Machine:.*AArch64'

debugfs -R 'cat /plumos/external-initramfs-probe.manifest' \
    "$verify/runtime.ext4" 2>/dev/null > "$verify/runtime.manifest"
grep -q '^format=plumos-mini-plus-full-stack-runtime-validation-v3$' "$verify/runtime.manifest"
grep -q '^authorized=yes$' "$verify/runtime.manifest"
grep -q '^app_layer=frontend,nextcommander,music-player,network-services,retroarch,libretro-cores,picoarch,standalone,pyxel,portmaster$' "$verify/runtime.manifest"
grep -q '^partition_expansion=p3-seed-2176MiB-to-8192MiB$' "$verify/runtime.manifest"
grep -q '^p4_creation=first-boot-fat32-PLUMOS$' "$verify/runtime.manifest"
if [ "$personalized" = yes ]; then
    debugfs -R 'stat /plumos/config/wpa_supplicant.conf' \
        "$verify/runtime.ext4" 2>/dev/null | grep -q 'Mode:  0600'
fi

MTOOLS_SKIP_CHECK=1 mtype -i "$verify/flash.fat" \
    ::/plumos-image.manifest > "$verify/plumos-image.manifest"
grep -q '^layout=validation-seed-v3,raw-prefix-16MiB,p1-fat32-512MiB,p2-raw-64MiB,p3-ext4-2176MiB,no-p4$' \
    "$verify/plumos-image.manifest"
grep -q '^format=plumos-mini-plus-full-stack-validation-image-v3$' "$verify/plumos-image.manifest"
grep -q '^p3_size_calculation=ceil-app-plus-headroom-to-128MiB$' \
    "$verify/plumos-image.manifest"
grep -q '^physical_boot_status=unverified-full-image$' \
    "$verify/plumos-image.manifest"
grep -q '^frontend=cpu-drm-dumb-buffer$' "$verify/plumos-image.manifest"
grep -q '^retroarch=software-plain-drm-and-hardware-kms-egl-gles-rgui$' \
    "$verify/plumos-image.manifest"
grep -q '^core_baseline=all-114-source-records$' "$verify/plumos-image.manifest"
grep -q '^catalog_systems=97$' "$verify/plumos-image.manifest"
grep -q '^catalog_launch_profile_occurrences=196$' "$verify/plumos-image.manifest"
grep -q '^user_media_included=no$' "$verify/plumos-image.manifest"
grep -q '^partition_expansion=first-boot-p3-to-8192MiB$' "$verify/plumos-image.manifest"
grep -q '^p4_creation=first-boot-fat32-PLUMOS-to-card-end$' "$verify/plumos-image.manifest"
grep -q '^final_partition_contract=host-candidate$' "$verify/plumos-image.manifest"
grep -q '^publishable=no$' "$verify/plumos-image.manifest"

mkdir -p "$verify/app-layer"
debugfs -R "rdump /plumos $verify/app-layer" "$verify/runtime.ext4" >/dev/null 2>&1
app=$verify/app-layer/plumos
(cd "$app" && sha256sum -c checksums.sha256)
for component in frontend nextcommander music-player network-services retroarch libretro-cores picoarch standalone pyxel portmaster; do
    test -s "$app/components/$component/manifest.json"
    test -s "$app/components/$component/checksums.sha256"
done
"$repo_root/tests/test-mini-plus-wifi-first-connect.sh" \
    "$app/bin/plumos-network-control"
jq -e '.device == "mini-plus" and .user_media_included == false and
    .catalog_complete == true and .release_complete == false and
    .publishable == false and (.non_publishable_reasons | length) >= 1 and
    .core_baseline == "all-114-source-records"' \
    "$app/manifest.json" >/dev/null
"$repo_root/scripts/audit-mini-plus-release-content.py" \
    --repo-root "$repo_root" --app-root "$app" --allow-non-publishable-candidate
PLUMOS_MINI_PLUS_APP_ROOT="$app" \
    "$repo_root/scripts/verify-mini-plus-emulator-catalog.sh"
LD_LIBRARY_PATH="$app/emulator/lib" \
    python3 "$repo_root/scripts/smoke-load-libretro-cores-mini-plus.py" \
    --root "$app" >"$verify/libretro-load-smoke.log"
grep -Fqx 'miniplus_libretro_load_smoke=result-ok pass=114 fail=0' \
    "$verify/libretro-load-smoke.log"
readelf -h "$app/bin/plumos-controller-ui-fbdev" | grep -q 'Machine:.*AArch64'
readelf -h "$app/bin/retroarch" | grep -q 'Machine:.*AArch64'
readelf -h "$app/cores/quicknes_libretro.so" | grep -q 'Machine:.*AArch64'
for library in libEGL.so.1 libGLESv2.so.2 libgbm.so.1; do
    readelf -d "$app/bin/retroarch" | grep -q "Shared library: \[$library\]"
done
grep -q 'video_driver = "drm"' "$app/factory-defaults/retroarch/retroarch-mini-plus.cfg"
grep -q 'video_context_driver = ""' \
    "$app/factory-defaults/retroarch/retroarch-mini-plus.cfg"
grep -q 'video_driver = "gl"' "$app/bin/plumos-retroarch-launch"
grep -q 'video_context_driver = "kms"' "$app/bin/plumos-retroarch-launch"
# Preserve the user's persistent RetroArch setting. The launcher may select a
# renderer per route, but must not force config_save_on_exit in its append cfg.
! grep -q 'config_save_on_exit' "$app/bin/plumos-retroarch-launch"
grep -q 'menu_driver = "rgui"' "$app/factory-defaults/retroarch/retroarch-mini-plus.cfg"
grep -q 'rgui_show_start_screen = "false"' \
    "$app/factory-defaults/retroarch/retroarch-mini-plus.cfg"
jq -e '.language == "en.lang"' \
    "$app/factory-defaults/system/settings.json" >/dev/null
for entry in ui-settings system-settings network-settings performance-settings apps help reboot shutdown; do
    grep -q "\"id\": \"$entry\"" "$app/config/frontend/menus.json"
done
jq -e '.miniplus_only_start_entries == [] and .miniplus_only_apps_entries == ["sd2_repair", "ggfe"] and
    .apps_reference_match == ["plumOS-MF", "plumOS-V90S_v2-public"]' \
    "$app/config/frontend/start-menu-coverage.json" >/dev/null
for helper in plumos-display-control plumos-network-control \
    plumos-network-services plumos-time-sync plumos-factory-reset \
    plumos-safe-shutdown plumos-thumbnail-scraper \
    plumos-nextcommander-launch plumos-music-player-launch; do
    test -x "$app/bin/$helper"
done
test -x "$app/apps/nextcommander/bin/NextCommander"
test -x "$app/apps/music-player/bin/plumos-music-player.bin"
for packaged_app in nextcommander music-player; do
    test -x "$app/apps/$packaged_app/lib/ld-linux-aarch64.so.1"
    test -f "$app/apps/$packaged_app/lib/libc.so.6"
done
grep -q -- '--library-path' "$app/bin/plumos-nextcommander-launch"
grep -q -- '--library-path' "$app/bin/plumos-music-player-launch"
jq -e 'all(.start_entries[]; .status == "implemented") and
    all(.apps_entries[]; .status == "implemented")' \
    "$app/config/frontend/start-menu-coverage.json" >/dev/null
grep -q 'PLUMOS_ACTION_TRACE_PATH' "$app/bin/plumos-controller-ui-mini-plus"
grep -q 'input_device = "retrogame_joypad"' \
    "$app/factory-defaults/retroarch/autoconfig/udev/gkd-mini-plus-retrogame-joypad.cfg"
grep -q 'input_a_btn = "1"' \
    "$app/factory-defaults/retroarch/autoconfig/udev/gkd-mini-plus-retrogame-joypad.cfg"
grep -q 'input_b_btn = "0"' \
    "$app/factory-defaults/retroarch/autoconfig/udev/gkd-mini-plus-retrogame-joypad.cfg"
for script in "$app"/bin/plumos-*; do
    case "$(head -n 1 "$script" 2>/dev/null || true)" in '#!'*) /bin/sh -n "$script" ;; esac
done
! find "$app" -type f \( -iname '*.nes' -o -iname '*.unf' -o -iname '*.unif' \) \
    -print -quit | grep -q .

echo "miniplus_frontend_probe_verify=result-ok image=$image sha256=$expected_sha personalized=$personalized"
