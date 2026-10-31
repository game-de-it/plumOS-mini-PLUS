# plumOS mini PLUS Developer Guide

[日本語](README.ja.md) | [User manual](../user/README.md)

v0.1.0 is published after a fresh build and host verification. Exact-image device retesting remains open and is recorded in the publication manifest and developer validation records. Check [validation](validation.md) and [TODO](../../TODO.md).

## Topics

- [Architecture](architecture.md)
- [Build and reproducibility](build.md)
- [Runtime and live deployment](runtime.md)
- [Frontend and emulator lifecycle](frontend-emulators.md)
- [Audio routing](audio-routing.md)
- [Hardware services](hardware-services.md)
- [Storage and update boundaries](storage-and-updates.md)
- [Validation and implementation status](validation.md)
- [Application integration](apps.md)
- [Libretro cores and catalog](libretro-cores.md)
- [Network services](network-services.md)
- [Manual deployment and recovery](manual-updates.md)
- [Release process](release-process.md)

## Sources and ownership

- rootfs/mini-plus-frontend/: read-only System overlay
- package/frontend-mini-plus/: FE, launchers, services and factory defaults
- configs/input/mini-plus-controller-map.json: input map
- package/frontend-mini-plus/plumos/config/frontend/runtime-coverage.json: route coverage
- configs/mini-plus-runtime-validation.json: device-validation ledger
- scripts/: build/verification; tests/: contracts
- docs/validation/: original evidence; docs/decisions/: recorded decisions

Managed Runtime is /storage/plumos; user media is /storage/user. User settings and saves also live within the managed partition: directory membership alone does not make a file managed. The menu key is the round key above-right of START; the screenshot FN's location is unconfirmed.

Keep common FE/catalog entries and explicit unsupported reasons. Never render an FE and another renderer concurrently; SIGSTOP alone is not display release.

Bubble reference evidence is not mini PLUS acceptance. Keep [the Bubble original](../reference/bubble/validation/2026-09-11-bubble-release-final-device-check.md) distinct from mini PLUS evidence.

Before implementation/troubleshooting, read the [series port/problem guide (Japanese original)](../../plumOS_gitlog_problem_solution_guide.ja.md). Respect the [third-party notices](../../THIRD_PARTY_NOTICES.md).
