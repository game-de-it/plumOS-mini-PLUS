# plumOS mini PLUS

[日本語](README.ja.md) | English

Formal version: **0.1.0**. [Bilingual release notes](docs/releases/0.1.0.md).
Distribution names: `plumos-mini-plus-v0.1.0-sd-image.img` / `.7z`, following Bubble. Final-image acceptance/publication is pending.

plumOS for **GKD mini PLUS (RK3566 / ARM64, 640×480)**, based on plumOS-Bubble. The handheld has four function keys and no analog sticks.

<p align="center"><img src="docs/images/gkd-mini-plus.jpg" alt="GKD mini PLUS running plumOS" width="640"></p>

## Three frontend views

| Text | Graphic | Gallery |
| --- | --- | --- |
| [![Text view](docs/images/frontend-text.png)](docs/images/frontend-text.png) | [![Graphic view](docs/images/frontend-graphics-list.png)](docs/images/frontend-graphics-list.png) | [![Gallery view](docs/images/frontend-gallery.png)](docs/images/frontend-gallery.png) |

These are mini PLUS device captures. The supplied body photo has had EXIF, XMP and camera metadata removed; its decoded primary-image pixels are unchanged. Artwork shown in screenshots is an example and is not supplied with the OS.

Choose `START → UI Settings → UI Mode → Text / Graphic`. On a game list, press `X` to open Gallery and `X` again to return. See [basic controls](docs/user/operation.md).

## Start here

1. [Install to SD1 and boot](docs/user/install.md).
2. [Connect Wi-Fi and enable file-transfer services](docs/user/network.md). SSH and SFTP have separate switches.
3. [Add ROMs and BIOS files](docs/user/storage.md), then choose a game and press `A`.
4. Keep the [emulator exit/menu/hotkey reference](docs/user/emulators.md) handy.

| Essential control | Action |
| --- | --- |
| `A` / `B` | Confirm or launch / go back in the frontend |
| `START` | Frontend main menu |
| Round key **above-right of START** | Emulator menu (driver alias F1); frontend screenshot while in the FE |
| `SELECT` + `START` in RetroArch | Exit to the frontend; repeat if the quit confirmation asks |
| Hold `SELECT` + volume − / + | Screen brightness down / up |
| Short power press | Power menu: Sleep, Reboot or Shutdown |

PicoArch and standalone emulators exit through their own menus. Ports and Pyxel games have title-specific exit controls; RetroArch shortcuts are not universal.

## Included features

- Text, Graphic and Gallery views, artwork scraping and the Game Gear frontend (GGFE).
- RetroArch, PicoArch, standalone emulators and 114 tracked libretro cores.
- PortMaster, Pyxel, File Manager, Music Player and SD2 repair.
- Wi-Fi; SSH, SFTP, FTP and Samba; optional SD2 ROM/BIOS storage with SD1 fallback.
- Volume and brightness keys, speaker/headphone routing, safe power actions and sleep with or without USB charging.
- Signed Runtime updates and System A/B trial/rollback on compatible boot images.

ROMs, user-supplied BIOS files and commercial games are not included. USB is currently used for charging; ADB and HDMI output are unavailable on this port.

## Current status

This is **pre-release development**, not a newly published release. New-SD boot, SD1/SD2 gameplay and the hardware gates have user acceptance; Runtime/System recovery has machine/device evidence. Of 196 launch routes, 170 have machine-launch evidence and 26 retain explicit validation limits. This does not claim every game is compatible.

The working SD includes later boot/app deployments. Earlier development `.img` files do not contain all of them. Final-image regeneration, exact-image acceptance and publication remain separate: [current work record](docs/validation/2026-10-31-mini-plus-pre-release-work.md), [known validation limits](docs/validation/2026-10-31-mini-plus-runtime-limitations.md), [TODO](TODO.md).

## Documentation

- [User manual](docs/user/README.md): installation, controls, storage, emulators, apps, saves, scraping, network, updates and troubleshooting.
- [Developer guide](docs/developer/README.md): architecture, builds, runtime, rendering, hardware, networking, updates and validation.
- [Documentation index](docs/README.md) / [Japanese documentation](docs/README.ja.md).

## Build

With the documented toolchain and approved vendor inputs:

```sh
./scripts/build-mini-plus-full-image.sh
```

The default raw image is `output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-full-stack-validation.img`. The seed is about 2.90 GB; first boot grows managed storage to 8 GiB and creates the user partition. Use a 16 GB or larger card. See the [build guide](docs/developer/build.md) for versioning, verification and prerequisites. Compression is a separate release step.

## License

plumOS-authored code is [MIT licensed](LICENSE). Vendor boot/runtime inputs and bundled third-party software retain their own terms: [third-party notices](THIRD_PARTY_NOTICES.md).
