# mini PLUS documentation topic audit (2026-10-31)

[日本語](2026-10-31-mini-plus-documentation-audit.ja.md)

Compared docs/user and docs/developer in Bubble, MF, Pixel2 and RK2020 read-only. Topics are mapped to mini PLUS operation, ownership, exit and validation rather than copied by filename alone.

Also inventoried user/developer topics in A30, MMF, XU20V32 and V90S. Their shared user topics and architecture/build/runtime/storage/validation topics are covered below. A30 feature-index/porting topics map to the implementation checklist and series port/problem guide; MMF-specific HAL, SDL, Onion and rendering research remains device-specific reference rather than mini PLUS user instructions. RK2020 storage-and-reimaging maps to install/storage/updates.

| Compared topic | mini PLUS coverage (all English/Japanese pairs) |
| --- | --- |
| User installation, controls, storage | user/install · operation · storage |
| Systems, emulators, saves/hotkeys | user/supported-systems · emulators · save-data |
| Scraping, network, updates, troubleshooting | user/scraping · network · updates · troubleshooting |
| Applications and exit methods | user/apps |
| Architecture, build, Runtime | developer/architecture · build · runtime |
| Frontend, cores, audio, hardware | developer/frontend-emulators · libretro-cores · audio-routing · hardware-services |
| Storage/update, network, manual deployment | developer/storage-and-updates · network-services · manual-updates |
| Apps, validation, release, implementation status | developer/apps · validation · release-process; implementation checklist |

The ten shared Bubble/MF user guides are covered, with an additional app/exit guide. MF developer topics are represented; Pixel2 implementation-status/frontend-feature-audit topics map to validation, frontend-emulators and the implementation checklist. Its separate save/hotkey material maps to emulators and save-data.

## Corrected inconsistencies

- Replaced stale device-unverified status and the former unsupported-System-A/B statement.
- Used the user-confirmed menu key above-right of START. Screenshot FN location remains unconfirmed; RA Quick Menu → Take Screenshot is documented.
- Documented RA repeated-quit confirmation, separate Pico/standalone/port exits and GGFE SELECT → Exit.
- Separated SSH/SFTP switches, shared root /storage, SD2 priority and explicit SD1 paths.
- Distinguished FE Screenshots/ from RA Images/ and explained why copying the visible FAT volume alone misses saves.
- Replaced inherited Bubble view images with mini PLUS Text/Graphic/Gallery captures and removed camera metadata from the body photo.
- Corrected old input/coverage paths, nonexistent .py verifier and obsolete /mnt/plumos in the developer index.

## Scope and checks

Other devices' lid-close Sleep/ADB features are not represented as mini PLUS functionality. No common FE item or catalog entry was changed. Raw experiment logs, Bubble references and third-party legal originals retain their source language; current user/developer guidance and scope/limits are bilingual.

See [image provenance/metadata](../images/README.md) and tests/test-mini-plus-documentation.py. This change documents and verifies the port; it does not generate or publish a new release image.

Checks passed: documentation language pairs/local Markdown and HTML links/image dimensions/JPEG metadata; generated supported-system tables; physical input contract; runtime ledger (196 routes, 170 machine-started, 26 not validated); git diff whitespace check. ImageMagick confirmed only the ICC profile remains in the photo and decoded primary pixels match the original SHA-256. These are documentation checks, not new game/hardware acceptance.
