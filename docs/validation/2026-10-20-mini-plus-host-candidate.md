# plumOS mini PLUS host candidate — 2026-10-20

## Result

`scripts/build-mini-plus-image.sh` completed successfully and produced:

```text
output/image/mini-plus/plumOS-mini-PLUS-0.1.0-dev-host-candidate.img
```

- image size: `2701131776` bytes
- image SHA-256: `1deb953ed67f59c4414c7778c621ece5d19670f4493ac10ec21958b73287ceca`
- minimal SYSTEM SHA-256: `4ca7104a5ae0ddeff2526ba4a3f928d5458ac9a89c0b554c07b1d45554d88a0d`
- external initramfs SHA-256: `d48582d916e694c51f7d763b760171b806bd80483ac947ff0862f48b8ce5092f`

`scripts/build-mini-plus-frontend-image.sh` also completed successfully and produced the separate frontend-only bring-up candidate:

```text
output/image/mini-plus-frontend/plumOS-mini-PLUS-0.1.0-dev-frontend-host-candidate.img
```

- image size: `2701131776` bytes
- image SHA-256: `c45cf9ed2c48c1b3e1aa626e93d7c0b38f13f62a1d6ec680480ef0400c420905`
- frontend SYSTEM SHA-256: `ff32fe13d0d6b2464eb1f7539aaf74baa5e6764c9a036e02ff7102058b5235cb`
- p1 filesystem SHA-256: `82a395d761e33e0bc7d4e7995b159d17d6e66b897bbd66c008104c5dce54e265`
- p2 filesystem SHA-256: `badaa6986580a7e109194a1c80d6d8c9aae94af220be20cb5ab4f4332fff585b`
- app layer: Bubble-derived frontend only; emulator runtime intentionally incomplete

## Layout

```text
raw prefix   sectors 0..32767       16 MiB, mini-PLUS Rockchip substrate
p1 FAT32     sectors 32768..1081343 512 MiB, PLUMBOOT, bootable
p2 ext4      sectors 1081344..5275647 2 GiB, PLUMOS_DATA
```

p1 contains the hash-pinned stock kernel, active mini-PLUS DTB, three sensor variants, two overlays, fixup script, instrumented `boot.scr`, plumOS external initramfs and minimal SquashFS SYSTEM. p2 contains only plumOS-owned configuration/log placeholders.

## Host checks passed

- build-time verification of all captured boot hashes
- `sha256sum -c` for SYSTEM, initramfs and complete image
- MBR partition table inspection
- FAT directory readback from the generated image
- FAT32 `fsck.fat -vn`
- ext4 `e2fsck -fn`
- comparison of generated image bytes 512..16 MiB against the captured mini-PLUS prefix
- complete byte comparison of each built p1/p2 filesystem against its location in both generated images
- `uEnv.txt` readback selecting `rk3566-gkdmini-pro.dtb` and the plumOS external initramfs
- checksum verification of all files in the frontend-only p2 application layer

## Intentional limitations

- `publishable=no`
- `physical_boot_status=unverified`
- Wi-Fi disabled pending a kernel-matching RTL8821CS module
- the minimal image is a boot-path probe; the frontend image adds the Bubble-derived UI but no emulator runtimes
- the original stockOS SD was not modified

The next acceptance step is to write the image to a separate blank SD, cold boot the GKD mini PLUS, collect U-Boot/initramfs/SYSTEM stages and read the test card back. A successful host build alone is not device acceptance.
