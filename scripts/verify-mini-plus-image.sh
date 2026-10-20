#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
image=${1:-$repo_root/output/image/mini-plus/plumOS-mini-PLUS-0.1.0-dev-host-candidate.img}
tools_image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}

[ -f "$image" ] || { echo "missing image: $image" >&2; exit 2; }
case "$image" in
    "$repo_root"/*) container_image=/work/${image#"$repo_root"/} ;;
    *) echo 'image must be inside the repository workspace' >&2; exit 2 ;;
esac
case "$(basename -- "$image")" in
    *-full-host-candidate.img)
        container_work=/work/work/mini-plus-full-image
        expected_size=4848615424
        p2_end=9469951
        p2_sectors=8388608
        p2_bytes=4294967296
        expected_physical=frontend-and-basic-controller-user-reported
        expected_app=full
        ;;
    *-frontend-host-candidate.img)
        container_work=/work/work/mini-plus-frontend-image
        expected_size=2701131776
        p2_end=5275647
        p2_sectors=4194304
        p2_bytes=2147483648
        expected_physical=unverified
        expected_app=
        ;;
    *)
        container_work=/work/work/mini-plus-image
        expected_size=2701131776
        p2_end=5275647
        p2_sectors=4194304
        p2_bytes=2147483648
        expected_physical=unverified
        expected_app=
        ;;
esac

(cd "$(dirname -- "$image")" && sha256sum -c checksums.sha256)
docker image inspect "$tools_image" >/dev/null 2>&1 ||
    "$repo_root/scripts/build-mini-plus-tools-image.sh"
docker run --rm --platform linux/arm64 \
    -e IMAGE="$container_image" -e CANDIDATE_WORK="$container_work" \
    -e EXPECTED_SIZE="$expected_size" -e P2_END="$p2_end" \
    -e P2_SECTORS="$p2_sectors" -e P2_BYTES="$p2_bytes" \
    -e EXPECTED_PHYSICAL="$expected_physical" -e EXPECTED_APP="$expected_app" \
    -v "$repo_root:/work" -w /work \
    "$tools_image" sh -eu -c '
        boot_offset=16777216
        expected_prefix=aa8bd95d5d75aaab1977c5e58732d67545221649a08e6b7afda36aee208e26e9
        test "$(stat -c %s "$IMAGE")" -eq "$EXPECTED_SIZE"
        fdisk -l "$IMAGE" > /tmp/fdisk.txt
        grep -Eq "img1[[:space:]]+\*[[:space:]]+32768[[:space:]]+1081343[[:space:]]+1048576" /tmp/fdisk.txt
        grep -Eq "img2[[:space:]]+1081344[[:space:]]+$P2_END[[:space:]]+$P2_SECTORS" /tmp/fdisk.txt
        mcopy -i "$IMAGE@@$boot_offset" ::/uEnv.txt /tmp/uEnv.txt
        mcopy -i "$IMAGE@@$boot_offset" ::/plumos-image.manifest /tmp/image.manifest
        mcopy -i "$IMAGE@@$boot_offset" ::/dtbs/4.19.193-51-rockchip-gb2c01b3d79f2/rockchip/rk3566-gkdmini-pro.dtb /tmp/active.dtb
        grep -qx "fdtfile=rockchip/rk3566-gkdmini-pro.dtb" /tmp/uEnv.txt
        grep -qx "initrdimg=initramfs-plumos-mini-plus.cpio.gz" /tmp/uEnv.txt
        grep -qx "device=gkd-mini-plus" /tmp/image.manifest
        grep -qx "physical_boot_status=$EXPECTED_PHYSICAL" /tmp/image.manifest
        if [ -n "$EXPECTED_APP" ]; then
            grep -qx "app_layer=$EXPECTED_APP" /tmp/image.manifest
            grep -qx "catalog_complete=true" /tmp/image.manifest
        fi
        grep -qx "publishable=no" /tmp/image.manifest
        test "$(sha256sum /tmp/active.dtb | cut -d" " -f1)" = \
            8e864607d2188d98fdcbc4f3ee961628585c7f7d5c2b10d77a45fee795407781
        test "$(sha256sum artifacts/vendor/mini-plus-stock-source/rockchip-boot-prefix.bin | cut -d" " -f1)" = "$expected_prefix"
        cmp -i 512:512 -n 16776704 \
            artifacts/vendor/mini-plus-stock-source/rockchip-boot-prefix.bin "$IMAGE"
        if [ -f "$CANDIDATE_WORK/boot.fat" ] && [ -f "$CANDIDATE_WORK/storage.ext4" ]; then
            cmp -i 0:16777216 -n 536870912 "$CANDIDATE_WORK/boot.fat" "$IMAGE"
            cmp -i 0:553648128 -n "$P2_BYTES" "$CANDIDATE_WORK/storage.ext4" "$IMAGE"
        fi
    '
echo "miniplus_image_verify=result-ok image=$image physical_boot=unverified"
