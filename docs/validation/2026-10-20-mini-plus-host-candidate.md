# plumOS mini PLUS host candidate — 2026-10-20

## Result

`scripts/build-mini-plus-image.sh` completed successfully and produced:

```text
output/image/mini-plus/plumOS-mini-PLUS-0.1.0-dev-host-candidate.img
```

- image size: `2701131776` bytes
- image SHA-256: `57d636f93e9899858a6e640bd2c6271be2d6c183762ec96c826c3dafe3b4d923`
- minimal SYSTEM SHA-256: `05a1378a31d3697dc94523d0a7a81bd97c59d12648f0ea2f7b9cab6a0def3453`
- external initramfs SHA-256: `48df50207f8be3fbb3c07080e44fbd5150422325404e6a4c79d915e9b4589ace`
- source commit: `b4e9f0e`

`scripts/build-mini-plus-frontend-image.sh` also completed successfully and produced the separate frontend-only bring-up candidate:

```text
output/image/mini-plus-frontend/plumOS-mini-PLUS-0.1.0-dev-frontend-host-candidate.img
```

- image size: `2701131776` bytes
- image SHA-256: `8bd66efa21e60a020419020c5b78929c069e88833d21452b25c0e7f3070c7e5f`
- frontend SYSTEM SHA-256: `419b45cb65d7d54f3497b62ef7fd6eb84a54fe084d70f708c5bb4d3251b5cfff`
- p1 filesystem SHA-256: `d92ab5e15c4ab0500f35b8e2691e7cea757cb2563088c2a799a7d14a238279be`
- p2 filesystem SHA-256: `9aa823128a9123dd920b7c0f4925d2c1c6441c2a27f9718c4183b6461e95e018`
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
