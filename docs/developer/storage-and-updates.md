# Storage and update boundaries

[日本語](storage-and-updates.ja.md) | [Developer guide](README.md)

The [architecture](architecture.md) separates boot/System, managed Runtime and FAT user media. SD2 is resolved by identity rather than a fixed disk number. Missing/dirty/unsupported SD2 must not prevent SD1 boot.

SD2 root roms/<system> and bios override the active ROM/BIOS aliases; settings and saves stay on SD1. See [user storage paths](../user/storage.md) and [network roots](../user/network.md). First boot records intent before resize/user-partition creation so interrupted provisioning can resume.

Runtime updates use signed manifests, staging, journal and renderer health; System updates use inactive-slot readback, pending/healthy state and trial rollback. Kernel, DTB, initramfs and p2 stay a matching full-image boundary. See [update contract](../plumos-mini-plus-runtime-update.md).

Before power-off, stop writers and unmount or remount writable areas read-only. Never run a filesystem repair on a mounted filesystem. A failed writer-stop/read-only transition must not be followed by a forced normal reboot.
