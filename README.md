# plumOS mini PLUS

This tree ports the plumOS-Bubble userspace assets to the GKD mini PLUS (RK3566 / ARM64).

The current output is a **device-bring-up, non-publishable full-stack candidate**. It combines the mini-PLUS-specific Rockchip boot prefix, kernel, DTBs and overlays read from the stockOS card with the Bubble storage and update contract. The source stockOS card is never written. The corrected full-stack image now boots the frontend and has live Wi-Fi/SSH, ALSA and representative emulator evidence, but it still requires device acceptance.

The candidate packages the Bubble-derived frontend, all 114 tracked libretro cores, RetroArch, PicoArch, standalone emulators, Pyxel, PortMaster, NextCommander, Music Player and network services. The live audit passed 32 representative SFC/GB/GBA/N64/NDS routes and two Yabasanshiro routes. A flat-root SD2 discovery bug and stale assemble-only runtime metadata remain release blockers, so it stays `publishable=no`.

## Current layout

- 16 MiB: hash-pinned mini PLUS Rockchip boot prefix
- p1: 512 MiB FAT32 with the vendor kernel, mini PLUS DTBs/overlays, plumOS initramfs and read-only SquashFS System A/B
- p2: 64 MiB immutable matching boot bundle
- p3: 2,176 MiB ext4 seed, calculated from the measured app payload plus 256 MiB headroom
- first boot: resume-safe expansion of p3 to 8 GiB, then creation of p4 `PLUMOS` in the remaining space; minimum card size is 14 GiB
- stock p2 data is not copied into the plumOS candidate
- Wi-Fi uses the live-stockOS-verified SDIO `02D0:A9A6` stack: the ABI-matching `bcmdhd` module, BCM43438A1 firmware and AP6212A NVRAM. The incompatible offline `8821cs.ko` and its force-load path are not used.

Build the canonical full-stack image with:

```sh
./scripts/build-mini-plus-full-image.sh
```

Output:

```text
output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.img
```

Create and verify the compressed device-validation asset with:

```sh
./scripts/prepare-mini-plus-validation-archive.sh
```

Output:

```text
output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.7z
```

Use `Settings` → `Network` → `Connect Wi-Fi` for the first association. SSH starts by default before association and becomes reachable as soon as DHCP assigns an address. The address is shown in Network Information; after a boot with saved credentials it is also written to `plumos-probe/network-address.txt` on the FAT partition. SSH/SFTP use port 22 with the initial login `root` / `plumos`. Use this only on a trusted test network and change the password before broader use.

The host build verifies complete image and partition checksums, filesystems, raw boot prefix, kernel, DTBs/overlays, the Wi-Fi ABI and payload hashes, the 114-core load smoke test and catalog coverage. The raw image is 2,902,458,368 bytes; its verified 7z is 485,622,918 bytes (463.13 MiB), below 500 MB. Live tests now cover frontend boot, the current Wi-Fi/DHCP/SSH session, ALSA PCM, 32 representative SFC/GB/GBA/N64/NDS routes and two Saturn Yabasanshiro routes. Flat-root SD2 discovery, all physical controls, speaker/headphones, power management, reconnect, SD readback and PSP/PSX/OpenBOR content remain unaccepted.

- [Bring-up status](TODO.md)
- [Read-only stock inventory](docs/validation/2026-10-20-mini-plus-read-only-inventory.md)
- [Host candidate build record](docs/validation/2026-10-20-mini-plus-host-candidate.md)
- [Frontend physical acceptance reported by the user](docs/validation/2026-10-20-mini-plus-frontend-user-acceptance.md)
- [Full host candidate build and verification record](docs/validation/2026-10-20-mini-plus-full-host-candidate.md)
- [Corrected Bubble-contract host candidate and checklist](docs/validation/2026-10-20-mini-plus-bubble-contract-host-candidate.md)
- [Live-stock Wi-Fi rebuild record](docs/validation/2026-10-20-mini-plus-live-wifi-rebuild.md)
- [Live mini PLUS / Bubble parity and omission audit](docs/validation/2026-10-20-mini-plus-bubble-live-parity-audit.md)
- [Preserved Bubble reference evidence](docs/reference/bubble/validation/)

plumOS-authored material is covered by the [MIT License](LICENSE). StockOS-derived boot/runtime inputs and third-party components retain their own terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
