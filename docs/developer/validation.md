# Validation and implementation status

[日本語](validation.ja.md) | [Developer guide](README.md)

Read TODO.md and [the implementation checklist](../plumos-implementation-checklist.md) before judging completion. New-SD normal boot, first-boot progress, controls/audio, SD1/SD2 play, brightness, USB/no-USB Sleep and network reconnection have user acceptance. Runtime and System A/B recovery have device-test evidence.

The [pre-release work record](../validation/2026-10-31-mini-plus-pre-release-work.md) is Japanese original evidence. The [English runtime limits](../validation/2026-10-31-mini-plus-runtime-limitations.md) describe the 26 routes without launch acceptance. 170 machine launches and 166 advancing PCM routes are not all-game visual/audible acceptance.

```sh
python3 tests/test-mini-plus-documentation.py
python3 tests/test-mini-plus-supported-systems-doc.py
sh tests/test-mini-plus-runtime-coverage.sh
sh tests/test-mini-plus-release-content-audit.sh
```

Use [frontend lifecycle](frontend-emulators.md) for safe device tests. Record image hash, route/core, content identity, video, audible audio, input, save/load and exit separately. Bubble reference records under docs/reference/bubble/ are reference only, not mini PLUS acceptance. Final-image acceptance remains open; see [release process](release-process.md).
