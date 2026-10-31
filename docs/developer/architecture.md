# Architecture

[日本語](architecture.ja.md) | [Developer guide](README.md)

Boot uses the mini PLUS stock-derived prefix/kernel/DTB and an external initramfs. System is read-only SquashFS; the writable managed Runtime lives at /storage/plumos. Never substitute Bubble boot files merely because the SoC matches.

| Partition | Role |
| --- | --- |
| p1, FAT32 512 MiB | /flash; System A/B and boot payload; normally read-only |
| p2, raw 64 MiB | Matching boot bundle |
| p3, ext4 measured seed | /storage; expands to 8 GiB on first boot |
| p4, remaining FAT32 | /storage/user; created on first boot |

[Storage and updates](storage-and-updates.md) explains the ownership boundary. [Implementation checklist](../plumos-implementation-checklist.md) defines acceptance independently of build success.
