# plumOS mini PLUS

This tree ports the plumOS-Bubble userspace assets to the GKD mini PLUS (RK3566 / ARM64).

The current output is a **host-verified, device-unverified bring-up candidate**. It combines the mini-PLUS-specific Rockchip boot prefix, kernel, DTB and overlays read from the stockOS card with a dedicated external initramfs and plumOS SYSTEM. The source stockOS card is never written.

Alongside the minimal boot candidate, a UI bring-up candidate packages the Bubble-derived frontend, Japanese fonts, themes, settings and helper tools on p2. It does not yet contain emulator runtimes and is not a complete release.

## Current layout

- p1: 512 MiB FAT32 with the stock kernel, `rk3566-gkdmini-pro.dtb`, overlays, plumOS initramfs and SquashFS SYSTEM
- p2: 2 GiB ext4 for configuration, logs and user data
- existing data from stock p2 is not copied into the plumOS candidate
- Wi-Fi is disabled in this candidate because the RTL8821CS module found in stock `SYSTEM` has a vermagic mismatch with the running stock kernel

Build the image with:

```sh
./scripts/build-mini-plus-image.sh
```

Output:

```text
output/image/mini-plus/plumOS-mini-PLUS-0.1.0-dev-host-candidate.img
```

Build the UI bring-up candidate with:

```sh
./scripts/build-mini-plus-frontend-image.sh
```

Output:

```text
output/image/mini-plus-frontend/plumOS-mini-PLUS-0.1.0-dev-frontend-host-candidate.img
```

The host builds verify the complete image checksums, partition filesystems, raw boot prefix, kernel, DTB and overlays. The UI candidate also verifies every packaged frontend component. LCD, controls, audio, shutdown, suspend and Wi-Fi still require a blank test SD and physical-device validation.

- [Bring-up status](TODO.md)
- [Read-only stock inventory](docs/validation/2026-10-20-mini-plus-read-only-inventory.md)
- [Host candidate build record](docs/validation/2026-10-20-mini-plus-host-candidate.md)
- [Preserved Bubble reference evidence](docs/reference/bubble/validation/)

plumOS-authored material is covered by the [MIT License](LICENSE). StockOS-derived boot/runtime inputs and third-party components retain their own terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
