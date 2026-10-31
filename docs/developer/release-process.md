# Release process

[日本語](release-process.ja.md) | [Developer guide](README.md)

v0.1.0 is published through the recorded-limits path below; exact-image physical acceptance remains pending. Documentation updates do not promote the live development SD or an older image to release status.

PLUMOS_MINI_PLUS_RELEASE_DRAFT=1 scripts/prepare-mini-plus-release.sh prepares a host-verified bundle ending in -draft without a physical acceptance manifest. Its manifest explicitly records unaccepted device status; this mode is for GitHub drafts only and must not be published as an accepted release. Normal mode still requires the exact image hash, write/readback, three cold boots and maintainer approval. Image manifests do not contain a version key: version checks use the Runtime VERSION and System os-release read back by the verifier.

1. Freeze the intended source revision and approved external inputs; regenerate the full raw image.
2. Run image verifier, content/license/secret audit and component/global checksum checks.
3. Record filename, byte size and SHA-256; write/read back that exact image on a new card.
4. Record first-boot progress, three cold boots, warm reboot, Wi-Fi/services, SD1/SD2, input, audible speaker/headphones, representative runtimes, save/load, power and USB/no-USB Sleep.
5. Keep update/rollback and recovery evidence tied to the tested boot contract.
6. Only after exact-image acceptance, prepare release checksums/notices. If compression is requested, verify extraction reproduces the accepted raw hash.
7. Obtain explicit publication approval, publish unchanged assets, then download anonymously and verify public hashes.

Development images may remain uncompressed at the user's request. A writer's completed status, passing host checks or success on another image does not replace physical acceptance. See [the checklist](../plumos-implementation-checklist.md) and [validation](validation.md).

The formal version is 0.1.0 (VERSION); [release notes](../releases/0.1.0.md) contain Japanese and English. scripts/prepare-mini-plus-release.sh uses that default and Bubble-style distribution names. It requires exact-image acceptance and matching image/Runtime versions. License originals are exported from verified image readback to licenses/ with a bilingual index. LICENSE (plumOS MIT), THIRD_PARTY_NOTICES.md and individual notices are included in bundle checksums.

Publication with recorded limits is a separate maintainer path: PLUMOS_MINI_PLUS_RELEASE_RECORDED_LIMITS=1 requires a hash-bound publication-with-recorded-limits manifest documenting the user's publication request and explicitly setting new_image_device_acceptance=no and physical_cold_boots=not-recorded. It does not create physical acceptance or close those checklist gates. Keep detailed validation status in the publication manifest and developer validation records. User-facing release notes focus on downloading, writing and booting the SD image. Without this explicit path, the strict acceptance gate remains in force.
