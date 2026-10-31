# Manual deployment and recovery

[日本語](manual-updates.ja.md) | [Developer guide](README.md)

Prefer [signed Runtime/System updates](../plumos-mini-plus-runtime-update.md). Copying files manually is a developer recovery/deployment operation, not a user update method.

Before changing media, identify the exact card/device and back up boot state, active/inactive System, settings and saves. Never overwrite an in-use active System file or repair a mounted FAT filesystem. Device-test destructive fixtures require bounded authorization.

For a managed app-layer delta, follow [Runtime deployment](runtime.md): retain live user state and update corresponding metadata atomically. Do not use a blanket rsync of host metadata over downloaded ports or settings.

For boot/kernel/DTB/initramfs changes, use a verified matching full-image build and spare card. Recovery success and a final released image are separate gates; log hashes and the route actually exercised.
