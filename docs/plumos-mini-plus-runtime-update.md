# plumOS mini PLUS Runtime / System update contract

[日本語](plumos-mini-plus-runtime-update.ja.md) | [Developer guide](developer/README.md)

The START → System Settings → System Update route supports signed Runtime and System packages. Both verify Ed25519 signatures over canonical META/manifest.json, payload hashes, device, architecture, vendor-runtime and ABI. Comparable SemVer is required; equal/older targets are rejected. Inbox: /storage/user/updates. Target: gkd-mini-plus, aarch64, mini-plus-stockos-r1.

## Building packages

Runtime input is an assembled plumos directory whose VERSION matches the target. Use the previous Runtime directory for a delta; omit --base-dir for a full Runtime payload.

```sh
python3 scripts/build-mini-plus-update-package.py \
  --type runtime --input /path/to/new/plumos \
  --base-dir /path/to/previous/plumos \
  --version <new-version> --base-version <installed-version> \
  --signing-key /secure/path/private-key.pem
```

System input is a SquashFS file:

```sh
python3 scripts/build-mini-plus-update-package.py \
  --type system --input /path/to/SYSTEM \
  --version <new-version> --base-version <installed-version> \
  --signing-key /secure/path/private-key.pem
```

Output is dist/plumos-mini-plus-{runtime|system}-<version>.tar.gz plus a SHA-256 sidecar. Keep the signing key outside source, images and archives. The normal FE route rejects unsigned development packages.

## Runtime transaction

Before ordinary frontend startup, reverify the request/package, stage and hash all payload files, journal the complete operation, retain previous managed files under /storage/plumos/backups/update-previous, and atomically install replacements with metadata last. Renderer-ready proof marks startup healthy. An interrupted/unhealthy transaction restores changed/deleted files and removes newly added files on recovery.

Managed payloads include executables, cores, themes, fonts, static catalogs and factory defaults. Active settings, saves, states, logs, ROMs, BIOS, Wi-Fi credentials, keys, downloaded ports and PortMaster installed-state data remain user-owned.

## System A/B transaction

The compatible boot contract is p1-slot-policy-trial-v1. The updater writes the inactive p1 System slot, verifies complete readback, then records a pending trial. The next boot tries it; frontend health commits it. Failed trials roll back on a following boot; a known healthy slot can also recover from active-slot failure.

System packages replace the read-only SquashFS only. They do not replace bootloader/prefix, kernel, DTB, overlays, external initramfs or p2 matching bundle. Changes to those require a matching full SD image. Older incompatible boot implementations reject System updates.

## Power and evidence

The FE verifies/selects a compatible package and invokes the normal safe-reboot path. Never force reboot after writer-stop or read-only conversion fails. Never overwrite an in-use active System file.

Runtime and System recovery device evidence is recorded in [pre-release work](validation/2026-10-31-mini-plus-pre-release-work.md) (Japanese original). Passing recovery on a development card does not accept a newly generated release image. See [release gates](developer/release-process.md) and [user update steps](user/updates.md).
