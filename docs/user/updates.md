# Runtime and System updates

[日本語](updates.ja.md) | [Manual](README.md)

1. Obtain a signed **mini PLUS** Runtime or System package and its checksum.
2. Verify the checksum and back up important saves/settings.
3. Copy the package to `updates/` on SD1's computer-visible PLUMOS volume; over the network this is `/storage/user/updates/` (share-relative `user/updates/`).
4. Choose `START → System Settings → System Update`. The updater selects a compatible package, verifies it and requests the normal safe reboot.
5. Keep power connected; do not remove cards or interrupt writing.
6. After reboot, check the version, frontend, Wi-Fi, games and saves.

Signature, device, source version and ABI must match. Equal/older target versions are rejected.

Runtime updates replace managed apps/cores using a journal and startup-health check; failed transactions restore the previous Runtime. System updates write and read back the inactive System A/B slot. A successful frontend startup commits the trial; a failed trial returns to the healthy slot on a following boot.

System updates require compatible `p1-slot-policy-trial-v1` boot support. They **do not** replace kernel, DTB, initramfs or the p2 matching bundle. Older boot layouts require a compatible full SD image.

Both package types preserve user ROMs, BIOS, saves, states, settings and downloaded PortMaster content. Rewriting an SD image erases the card and is a fresh install. See [developer update contract](../plumos-mini-plus-runtime-update.md) for package details.
