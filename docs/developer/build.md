# Build and reproducibility

[日本語](build.ja.md) | [Developer guide](README.md)

Run from the repository root with the configured container toolchain and hash-approved stock boot/GPU/firmware inputs. The build scripts validate required inputs; do not replace missing inputs with another device's binaries.

```sh
./scripts/build-mini-plus-full-image.sh
sh scripts/verify-mini-plus-frontend-probe-image.sh output/image/mini-plus-frontend-probe/<image>.img
```

The full-image wrapper delegates to the frontend-probe builder, which assembles System, initramfs, Runtime and the measured seed. --assemble-only reuses cached components and is not evidence of a fresh source build. The default seed is about 2.90 GB, including the managed payload and headroom; it is not a fixed 4 GB root partition.

Record commit, dirty state, version, toolchain, external-input hashes and output SHA-256. Inspect scripts/build-mini-plus-{frontend-system,external-initramfs,app-layer,frontend-probe-image}.sh for component prerequisites. Compression and promotion are separate [release steps](release-process.md).

The full-image wrapper exports the default from VERSION (0.1.0) to child builds. An explicit PLUMOS_MINI_PLUS_VERSION override takes priority; direct component scripts retain development defaults. Formal distribution names are plumos-mini-plus-v0.1.0-sd-image.img / .7z, matching Bubble. Do not rename an older dev image to claim 0.1.0.
