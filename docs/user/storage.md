# SD1 and SD2

[日本語](storage.ja.md) | [Manual](README.md)

SD1 in the **top-edge SYS slot** contains boot/System, a managed Linux partition and a computer-visible FAT32 volume named PLUMOS. Do not format the boot or managed partitions.

| SD1 PLUMOS folder | Purpose |
| --- | --- |
| Roms/<system>/ | ROMs when SD2 is absent |
| BIOS/ | BIOS when SD2 is absent |
| Images/ | RetroArch screenshots and images |
| Screenshots/ | Frontend screenshots |
| updates/ | Signed update packages |

SD2 is optional FAT32 in the **bottom-edge SD2 slot**. Use root `roms/<system>/` and `bios/` to match Bubble. Roms/ROMS and BIOS/Bios are also recognized; avoid competing case variants.

When SD2 is present it supplies the active ROM/BIOS directories. Without SD2 the system falls back to SD1. Saves, settings, logs and screenshots remain on SD1. On-device `/storage/Roms` and `/storage/BIOS` follow the active source; `/storage/user/Roms` and `/storage/user/BIOS` explicitly select SD1.

Managed data such as `/storage/plumos/saves`, `states`, `config` and `logs` is on a different partition from PLUMOS. Back it up with [network transfer](network.md); copying only the computer-visible FAT volume does not back up saves.

Insert/remove SD2 only with power off; hot-plugging is unsupported. Wait for shutdown and display/LED off before removing SYS. For suspect FAT32 SD2, see [Repair SD2](apps.md).
