# Runtime and live deployment

[日本語](runtime.ja.md) | [Developer guide](README.md)

package/frontend-mini-plus/ supplies the app-layer overlay and factory defaults; scripts/build-mini-plus-app-layer.sh owns Runtime assembly and VERSION. Active settings, saves and downloaded ports remain user-owned.

A live change under /storage/plumos must include the changed managed files, corresponding component metadata, manifest.json and checksums.sha256 entries in one consistent deployment. Preserve the device's baseline and update only affected managed entries. Do not copy host-wide metadata over user-modified settings or PortMaster content.

Use cp, chmod and atomic mv on BusyBox. Verify deployed SHA-256 plus app-layer checksums before reboot; a checksum failure can prevent bootstrap. Keep a recoverable backup. For structural changes prefer a signed [package update](../plumos-mini-plus-runtime-update.md).

Never deploy to an active component while it is writing. Use the normal FE lifecycle and power/update quiesce path.
