# BIOS, saves and screenshots

[日本語](save-data.ja.md) | [Manual](README.md)

Supply BIOS files you are entitled to use in the active card's BIOS directory: SD2 `bios/` when present, otherwise SD1 `BIOS/`. Disc/computer/arcade systems may need specific BIOS and content versions. A recognized extension does not guarantee compatibility.

| Data | Device path |
| --- | --- |
| RetroArch saves / states | /storage/plumos/saves/ · /storage/plumos/states/ |
| Settings / logs | /storage/plumos/config/ · /storage/plumos/logs/ |
| RetroArch screenshots | /storage/Images/ |
| Frontend screenshots | /storage/Screenshots/ |
| Standalone settings | /storage/plumos/config/standalone/ |
| PPSSPP state directory | /storage/plumos/state/standalone/ppsspp/ |

The screenshot folders are on the FAT user volume. Saves/settings are on SD1's managed partition; back up over [SFTP/Samba](network.md), preserving directory structure. Other standalone emulators and ports use their own locations: include the relevant runtime and downloaded-port directories in backups.

Save normally in-game and quit cleanly before copying files. Save states are often core/version-specific: keep the same core and version when restoring, and retain normal in-game saves too. A successful Gambatte test does not establish state compatibility for every core.

The Game Gear shader is `/storage/plumos/config/shaders/gamegear-lcd.glslp`. Back up custom changes. For menu-based screenshots, state shortcuts and exit methods, use the [emulator reference](emulators.md).
