# Release process

[日本語](release-process.ja.md) | [Developer guide](README.md)

Final release preparation is still pending. Documentation updates do not promote the live development SD or an older image to release status.

1. Freeze the intended source revision and approved external inputs; regenerate the full raw image.
2. Run image verifier, content/license/secret audit and component/global checksum checks.
3. Record filename, byte size and SHA-256; write/read back that exact image on a new card.
4. Record first-boot progress, three cold boots, warm reboot, Wi-Fi/services, SD1/SD2, input, audible speaker/headphones, representative runtimes, save/load, power and USB/no-USB Sleep.
5. Keep update/rollback and recovery evidence tied to the tested boot contract.
6. Only after exact-image acceptance, prepare release checksums/notices. If compression is requested, verify extraction reproduces the accepted raw hash.
7. Obtain explicit publication approval, publish unchanged assets, then download anonymously and verify public hashes.

Development images may remain uncompressed at the user's request. A writer's completed status, passing host checks or success on another image does not replace physical acceptance. See [the checklist](../plumos-implementation-checklist.md) and [validation](validation.md).
