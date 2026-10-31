# plumOS mini PLUS User Manual

[日本語](README.ja.md) | [Project home](../../README.md)

This guide covers the pre-release development port. Device-verified operation and final-image acceptance are separate; check the [current status](../../README.md#current-status).

## Locations to learn first

| Name | Location and purpose |
| --- | --- |
| SYS slot (SD1) | Top edge; boot card |
| SD2 slot | Bottom edge; optional ROM/BIOS card |
| Menu key (driver alias F1) | **Round key above-right of START**. RA/Pico/supported standalone menus; frontend screenshot in the FE |

There are four function keys. F1/F2 are driver aliases, not a left-to-right numbering or shoulder-button names. The location of the separate screenshot FN is unconfirmed; use RetroArch's menu to take screenshots.

> Power off before inserting/removing SD2. Hot-plugging SD2 is unsupported.

## Guides

1. [Writing SD1 and first boot](install.md)
2. [Basic controls, three views, power and sleep](operation.md)
3. [SD1 and SD2](storage.md)
4. [Supported systems, ROM folders, extensions and cores](supported-systems.md)
5. **[Emulator exit, menu and hotkey reference](emulators.md)**
6. [Applications and how to exit them](apps.md)
7. [BIOS, saves, states and screenshots](save-data.md)
8. [Artwork scraping](scraping.md)
9. [Wi-Fi, file-transfer switches and destinations](network.md)
10. [Runtime / System updates](updates.md)
11. [Troubleshooting](troubleshooting.md)

## First game

Write the OS to SD1 and wait for first-boot storage setup. Add ROMs to `Roms/<system>/`, then choose a system and game in the FE and press `A`. With SD2 inserted, its root `roms/<system>/` and `bios/` take priority. Refresh the list or re-enter the system after adding content.

Use `SELECT` to choose RA/PICO/other available routes. On the system list it changes the system default; on a game list it selects a route for that game. Check the [exit reference](emulators.md) before playing.

## Language and limits

The factory UI language is English. Select Japanese under `START → System Settings → Language`. There are no analog sticks. USB data transfer, ADB and HDMI output are unavailable. Check the [system table](supported-systems.md) for 3DS/Java ME and other unsupported entries.

ROMs, user BIOS files and commercial games are not included. See the [known validation limits](../validation/2026-10-31-mini-plus-runtime-limitations.md).
