# plumOS mini PLUS Developer Guide

This guide covers builds, changes, validation and release preparation for the
GKD mini PLUS port. End-user operation is kept in the [user manual](../user/README.md).

## Repository boundaries

- `rootfs/mini-plus-frontend/`: read-only System rootfs overlay
- `package/frontend-mini-plus/`: frontend, launchers, services and factory defaults
- `configs/mini-plus-controller-map.json`: canonical physical input map
- `configs/mini-plus-runtime-coverage.tsv`: runtime coverage and publication state
- `scripts/build-mini-plus-frontend-system.sh`: System build
- `scripts/build-mini-plus-external-initramfs.sh`: external initramfs build
- `scripts/build-mini-plus-app-layer.sh`: managed app-layer build
- `scripts/build-mini-plus-frontend-probe-image.sh`: full raw image and integration gates
- `tests/`: contract, content, runtime and image verification
- `docs/validation/`: host/device evidence; never rewrite inference as observation
- `docs/decisions/`: product and release-boundary decisions

`package/frontend-mini-plus/plumos/config/frontend/systems.json` is the source of
truth for visible systems, ROM aliases, extensions and launch profiles. Regenerate
the user tables with:

```sh
python3 scripts/generate-mini-plus-supported-systems-doc.py
python3 scripts/generate-mini-plus-supported-systems-doc.py --check
```

Do not hide incomplete ports by deleting catalog entries. Provide a route or a
machine-readable, device-specific unsupported state in coverage and the FE.

## Ownership

| Area | Ownership |
| --- | --- |
| Boot, vendor kernel, approved firmware | Vendor-derived; pinned by hash and NOTICE |
| System | Read-only matching set and A/B update target |
| `/mnt/plumos` app layer | Managed by manifests and `checksums.sha256` |
| `/storage` | User-owned ROMs, BIOS, saves and settings |
| SD2 | Optional ROM/BIOS source; no powered hot-plug support |

Never overwrite user settings or PortMaster downloads merely to make them match
host app-layer metadata.

## Build

With the tool image and approved vendor inputs available, run:

```sh
PLUMOS_MINI_PLUS_VERSION=<version> \
PLUMOS_MINI_PLUS_INCLUDE_CAPTURED_VENDOR_GPU=1 \
./scripts/build-mini-plus-frontend-probe-image.sh
```

The top-level path rebuilds System, initramfs and app layer before creating the
raw image under `output/image/mini-plus-frontend-probe/`. Output is not tracked.
For reproducible builds, record the clean-clone commit, `SOURCE_DATE_EPOCH` and
artifact SHA-256.

## Frontend and emulator lifecycle

Launch games through the normal frontend route. Launchers make the FE release
display, input and audio, supervise the child process group, and restore exactly
one FE after exit.

Never let an FE and emulator or diagnostic renderer draw to `/dev/fb0` or
`/dev/dri/card*` concurrently. `SIGSTOP` is not display release. This is a hard
boundary against flicker and LCD image retention.

For live `/mnt/plumos` deployment, update a whole component with its binary,
manifest and checksum, then verify the on-device SHA-256 and app-layer checksum
before rebooting.

## Input contract

- Function 1: evdev 704 / js17, front face, emulator menu
- Function 2: evdev 316 / js10, top edge, RetroArch screenshot
- SELECT: js8
- START: js9
- RetroArch exit: SELECT + START

After input changes, at minimum run:

```sh
sh tests/test-mini-plus-physical-input-contract.sh
sh tests/test-mini-plus-start-menu-contract.sh
```

## Main validation

```sh
python3 tests/test-mini-plus-supported-systems-doc.py
python3 tests/test-mini-plus-documentation.py
sh tests/test-mini-plus-runtime-coverage.sh
sh tests/test-mini-plus-release-content-audit.sh
python3 scripts/verify-mini-plus-frontend-probe-image.py \
  output/image/mini-plus-frontend-probe/<image>.img
```

A passing component test is not release acceptance. Tie a new-card write/readback,
cold boots, warm reboot, Wi-Fi, shutdown, sleep, audio, SD2, representative
runtimes and rollback to the exact commit and image hash.

## Updates

See the [runtime update design](../plumos-mini-plus-runtime-update.md). Signature,
device, base version and payload checks fail closed; same-version installs and
downgrades are rejected. Never force reboot/shutdown after writer-stop or
read-only conversion fails.

## Licensing and publication

plumOS-owned work is MIT. StockOS-derived material remains GKD property, while
vendor runtimes and DraStic follow the repository NOTICE and allowlist policy.
Keep legal notices, provenance, binary inventory and ROM/BIOS/credential/private
key scans with every release artifact.

Artifact generation and publication are separate. Do not create a GitHub release
until the user has accepted the candidate and explicitly approved publication.
After publishing, anonymously download the assets and verify the public hashes.

## Bubble reference evidence (not mini-PLUS acceptance)

The Bubble RC passed a fresh write, readback, first-boot provisioning, Saturn,
Wi-Fi, managed checksums and three cold boots. None of that physical evidence
is inherited by the mini-PLUS port.

See the preserved [Bubble final device check](../reference/bubble/validation/2026-09-11-bubble-release-final-device-check.md)
and [Bubble release-candidate verification](../reference/bubble/validation/2026-09-11-bubble-release-candidate-image.md).
