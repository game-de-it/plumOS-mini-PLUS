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
    *-frontend-host-candidate.img) container_work=/work/work/mini-plus-frontend-image ;;
    *) container_work=/work/work/mini-plus-image ;;
esac

(cd "$(dirname -- "$image")" && sha256sum -c checksums.sha256)
docker image inspect "$tools_image" >/dev/null 2>&1 ||
    "$repo_root/scripts/build-mini-plus-tools-image.sh"
docker run --rm --platform linux/arm64 \
    -e IMAGE="$container_image" -e CANDIDATE_WORK="$container_work" \
    -v "$repo_root:/work" -w /work \
    "$tools_image" sh -eu -c '
        boot_offset=16777216
        expected_prefix=aa8bd95d5d75aaab1977c5e58732d67545221649a08e6b7afda36aee208e26e9
        test "$(stat -c %s "$IMAGE")" -eq 2701131776
        fdisk -l "$IMAGE" > /tmp/fdisk.txt
        grep -Eq "img1[[:space:]]+\*[[:space:]]+32768[[:space:]]+1081343[[:space:]]+1048576" /tmp/fdisk.txt
        grep -Eq "img2[[:space:]]+1081344[[:space:]]+5275647[[:space:]]+4194304" /tmp/fdisk.txt
        mcopy -i "$IMAGE@@$boot_offset" ::/uEnv.txt /tmp/uEnv.txt
        mcopy -i "$IMAGE@@$boot_offset" ::/plumos-image.manifest /tmp/image.manifest
        mcopy -i "$IMAGE@@$boot_offset" ::/dtbs/4.19.193-51-rockchip-gb2c01b3d79f2/rockchip/rk3566-gkdmini-pro.dtb /tmp/active.dtb
        grep -qx "fdtfile=rockchip/rk3566-gkdmini-pro.dtb" /tmp/uEnv.txt
        grep -qx "initrdimg=initramfs-plumos-mini-plus.cpio.gz" /tmp/uEnv.txt
        grep -qx "device=gkd-mini-plus" /tmp/image.manifest
        grep -qx "physical_boot_status=unverified" /tmp/image.manifest
        grep -qx "publishable=no" /tmp/image.manifest
        test "$(sha256sum /tmp/active.dtb | cut -d" " -f1)" = \
            8e864607d2188d98fdcbc4f3ee961628585c7f7d5c2b10d77a45fee795407781
        test "$(sha256sum artifacts/vendor/mini-plus-stock-source/rockchip-boot-prefix.bin | cut -d" " -f1)" = "$expected_prefix"
        cmp -i 512:512 -n 16776704 \
            artifacts/vendor/mini-plus-stock-source/rockchip-boot-prefix.bin "$IMAGE"
        if [ -f "$CANDIDATE_WORK/boot.fat" ] && [ -f "$CANDIDATE_WORK/storage.ext4" ]; then
            cmp -i 0:16777216 -n 536870912 "$CANDIDATE_WORK/boot.fat" "$IMAGE"
            cmp -i 0:553648128 -n 2147483648 "$CANDIDATE_WORK/storage.ext4" "$IMAGE"
        fi
    '
echo "miniplus_image_verify=result-ok image=$image physical_boot=unverified"
