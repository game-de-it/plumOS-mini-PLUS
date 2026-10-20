#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}

if [ "${1:-}" != "--inside" ]; then
    docker image inspect "$image" >/dev/null 2>&1 ||
        "$repo_root/scripts/build-mini-plus-tools-image.sh"
    exec docker run --rm --platform linux/arm64 \
        -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}" \
        -e PLUMOS_MINI_PLUS_VERSION="${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}" \
        -v "$repo_root:/work" -w /work "$image" \
        ./scripts/build-mini-plus-boot-initramfs.sh --inside
fi

repo_root=/work
out_dir=$repo_root/output/initramfs/mini-plus-boot
rootfs=$out_dir/rootfs
payload=$out_dir/payload
version=${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}
source_ref=$(git -c safe.directory="$repo_root" -C "$repo_root" rev-parse --short HEAD 2>/dev/null || printf unknown)
source_epoch=${SOURCE_DATE_EPOCH:-}
[ -n "$source_epoch" ] || source_epoch=$(git -c safe.directory="$repo_root" -C "$repo_root" show -s --format=%ct HEAD)
case "$source_epoch" in ''|*[!0-9]*) echo 'invalid SOURCE_DATE_EPOCH' >&2; exit 2;; esac

case "$out_dir" in /work/output/initramfs/mini-plus-boot) ;; *) exit 2;; esac
find "$out_dir" -depth -delete 2>/dev/null || true
mkdir -p "$rootfs/bin" "$rootfs/dev/pts" "$rootfs/proc" "$rootfs/sys" \
    "$rootfs/run" "$rootfs/tmp" "$rootfs/root" "$rootfs/flash" \
    "$rootfs/newroot" "$payload"
install -m 0755 "$repo_root/rootfs/mini-plus-boot-initramfs/init" "$rootfs/init"
install -m 0755 /bin/busybox "$rootfs/bin/busybox"
for applet in awk grep hostname losetup mkdir mknod mount sha256sum sh sleep \
    sync switch_root umount; do
    /bin/busybox --list | grep -qx "$applet"
    ln -s /bin/busybox "$rootfs/bin/$applet"
done

find "$rootfs" -exec touch -h -d "@$source_epoch" {} +
archive=$payload/initramfs-plumos-mini-plus.cpio.gz
python3 "$repo_root/scripts/pack-mini-plus-initramfs.py" \
    --mtime "$source_epoch" "$rootfs" "$archive"
archive_size=$(stat -c '%s' "$archive")
archive_sha=$(sha256sum "$archive" | awk '{print $1}')
cat > "$payload/initramfs.manifest" <<EOF
format=plumos-mini-plus-boot-initramfs-v1
device=gkd-mini-plus
architecture=aarch64
version=$version
source_ref=$source_ref
source_date_epoch=$source_epoch
kernel_release=4.19.193-g5a07852a55cf-dirty
boot_source=p1-fat32-system-squashfs
storage=p2-ext4
stock_root_partition_required=no
image_size=$archive_size
image_sha256=$archive_sha
physical_boot_status=unverified
EOF
printf '%s  %s\n' "$archive_sha" "$(basename "$archive")" > "$payload/checksums.sha256"
gzip -t "$archive"
(cd "$payload" && sha256sum -c checksums.sha256)
echo "miniplus_boot_initramfs=result-ok image=$archive sha256=$archive_sha"
