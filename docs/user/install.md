# Writing SD1 and first boot

[日本語](install.ja.md) | [Manual](README.md)

The port is in pre-release development. Use the exact candidate specified for testing; older images may lack later fixes. See [current status](../../README.md#current-status).

1. Prepare a GKD mini PLUS and a 16 GB or larger microSD for the top-edge SYS slot.
2. Obtain the raw `.img` and its SHA-256. If supplied as an archive, extract it first; development images may be uncompressed.
3. Verify the hash and select the correct card by name and capacity in Raspberry Pi Imager, balenaEtcher or another raw-image writer.
4. Write as a disk image, let the writer verify, then safely eject.
5. Insert SD1 while powered off, power on, and wait for first-boot progress to finish and the FE to appear.

The progress screen covers storage preparation: the managed partition expands to 8 GiB and the remaining space becomes the PLUMOS FAT32 user volume. Do not interrupt it. Later boots skip this provisioning screen.

Writing erases the target card, including saves/settings stored there. Back up existing cards first. A writer's success/ejection is not a device boot check.

For optional SD2, format FAT32 and create `roms/<system>/` plus `bios/` at its root. Insert it in the bottom-edge SD2 slot while powered off. Without SD2, use SD1's PLUMOS `Roms/` and `BIOS/`. See [storage](storage.md), [network transfer](network.md) and [first-game controls](emulators.md).
