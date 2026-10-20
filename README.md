# plumOS mini PLUS

This tree ports the plumOS-Bubble userspace assets to the GKD mini PLUS (RK3566 / ARM64).

The current output is a **host-verified, non-release bring-up candidate**. It combines the mini-PLUS-specific Rockchip boot prefix, kernel, DTB and overlays read from the stockOS card with a dedicated external initramfs and plumOS SYSTEM. The source stockOS card is never written. The frontend-only image has reached the frontend on a physical mini PLUS and accepted basic controller operation, as reported by the user.

Alongside the minimal and UI bring-up candidates, the full candidate packages the Bubble-derived frontend, all 114 tracked libretro cores, RetroArch, PicoArch, standalone emulators, Pyxel, PortMaster, NextCommander, Music Player and network services. It is intentionally still `publishable=no` until the full runtime, hardware and Wi-Fi paths pass device acceptance.

## Current layout

- p1: 512 MiB FAT32 with the stock kernel, `rk3566-gkdmini-pro.dtb`, overlays, plumOS initramfs and SquashFS SYSTEM
- p2: 2 GiB ext4 in minimal/UI images; 4 GiB ext4 in the full image
- existing data from stock p2 is not copied into the plumOS candidate
- the full image carries an experimental, explicitly authorized RTL8821CS force-load path; the stock module has `vermagic=4.19.172` while the running kernel is `4.19.193` with module versioning, so a failed load or kernel instability remains possible

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

Build the full application and experimental Wi-Fi/SSH candidate with:

```sh
./scripts/build-mini-plus-full-image.sh
```

Output:

```text
output/image/mini-plus-full/plumOS-mini-PLUS-0.1.0-dev-full-host-candidate.img
```

Use `Settings` → `Network` → `Connect Wi-Fi` for the first association. SSH starts by default before association and becomes reachable as soon as DHCP assigns an address. The address is shown in Network Information; after a boot with saved credentials it is also written to `plumos-probe/network-address.txt` on the FAT partition. SSH/SFTP use port 22 with the initial login `root` / `plumos`. Use this only on a trusted test network and change the password before broader use.

The host builds verify the complete image checksums, partition filesystems, raw boot prefix, kernel, DTB and overlays. The full build additionally verifies component checksums, the 114-core load smoke test and catalog coverage. Audio, every control, emulator/GPU runtime, power management, Wi-Fi/SSH and SD readback still require physical-device validation.

- [Bring-up status](TODO.md)
- [Read-only stock inventory](docs/validation/2026-10-20-mini-plus-read-only-inventory.md)
- [Host candidate build record](docs/validation/2026-10-20-mini-plus-host-candidate.md)
- [Frontend physical acceptance reported by the user](docs/validation/2026-10-20-mini-plus-frontend-user-acceptance.md)
- [Full host candidate build and verification record](docs/validation/2026-10-20-mini-plus-full-host-candidate.md)
- [Preserved Bubble reference evidence](docs/reference/bubble/validation/)

plumOS-authored material is covered by the [MIT License](LICENSE). StockOS-derived boot/runtime inputs and third-party components retain their own terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
