# Wi-Fi and file transfer

[日本語](network.ja.md) | [Manual](README.md)

Enable Wi-Fi under `START → Network Settings`, then select an SSID with Connect Wi-Fi and enter its password. Read the IP under INFORMATION after connection. Saved networks reconnect automatically.

**SSH and SFTP have separate service switches.** Open `START → Network Settings → NW Service` and enable the desired service. SSH being reachable does not prove SFTP is enabled. SFTP, FTP and Samba must be enabled before using them.

| Service | Address / port | User / password |
| --- | --- | --- |
| SSH | Device IP, 22 | root / plumos |
| SFTP | Device IP, 22 | root / plumos |
| FTP | Device IP, 21 | anonymous / no password |
| Samba | `\\\\<IP>\\SDCARD` | plumos / plumos |

Change factory passwords before using an untrusted network. USB is charge-only; use Wi-Fi for transfers.

## Destinations

SFTP starts at `/storage`; FTP and the SDCARD share also expose `/storage`. This includes both the user area and device-managed directories.

- `Roms/nes/`, for example, is the **active** ROM source: SD2 when present, otherwise SD1.
- `BIOS/` likewise follows the active card.
- `user/Roms/` and `user/BIOS/` explicitly address SD1.
- `plumos/saves/`, `plumos/states/`, `plumos/config/` and `plumos/logs/` are on SD1's managed partition.
- Update packages go to `user/updates/`.

No SD2 is required for SFTP or SD1 games. After transfers, refresh the list. Verify large files by size/hash if interrupted. If connection fails, check the service switch, current IP, same LAN and client firewall first. See [storage](storage.md) before removing SD2.
