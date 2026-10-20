# GKD mini PLUS full host candidate

Date: 2026-10-20

> **2026-10-20 conformance correction:** This file records a useful two-partition
> bring-up artifact, but the artifact is withdrawn as a plumOS-complete candidate.
> It has no matching p2, System A/B, managed p3 or first-boot p4, and its 4 GiB
> p2 was fixed rather than calculated from payload use. See
> `2026-10-20-mini-plus-plumos-conformance-audit.md`. The full image itself has
> not been physically booted; frontend acceptance belongs only to the separate
> frontend-only image. Its generated raw image was removed after withdrawal to
> avoid accidental flashing and reclaim build space. The replacement is recorded
> in `2026-10-20-mini-plus-bubble-contract-host-candidate.md`.

## Result

The full plumOS application stack was assembled into a separate, host-verified SD image. This image is a device-test candidate, not a public release.

- File: `output/image/mini-plus-full/plumOS-mini-PLUS-0.1.0-dev-full-host-candidate.img`
- Logical size: `4848615424` bytes
- SHA-256: `eef955050b36e6a56bd0fbb6acca8b0aebde4dadac33a5affb0c5303782ddca9`
- Implementation source: `c0c0888` (`Build full mini PLUS plumOS candidate`)
- p1: 512 MiB FAT32 boot filesystem
- p2: 4096 MiB ext4 plumOS data filesystem
- Publication state: `publishable=no`, `release_complete=false`
- Conformance state: `bring-up-only`, withdrawn from release-candidate use

## Included stack

- mini PLUS software-DRM frontend and settings UI
- RetroArch plus all 114 tracked libretro source records
- PicoArch and its per-route RGB565 policy
- PCSX-ReARMed, YabaSanshiro, DraStic, PPSSPP, and OpenBOR standalone runtimes
- Pyxel, PortMaster, NextCommander, and Music Player
- Wi-Fi control, Dropbear SSH/SFTP, FTP, and Samba services
- captured mini PLUS Mali userspace runtime covered by the vendor notice

No user ROM collection, saved Wi-Fi credentials, SSH private host key, or other personalized data is included. The SSH host key is generated on the device.

## Wi-Fi and SSH policy

The captured stock `8821cs.ko` reports `vermagic=4.19.172 SMP mod_unload aarch64`; the captured running kernel reports `4.19.193-g5a07852a55cf-dirty SMP mod_unload modversions aarch64`. The module contains no `__versions` symbol CRC table. The full candidate therefore:

1. attempts a normal BusyBox `insmod` first;
2. permits `kmod insmod -f` only when the full-candidate authorization marker is present;
3. records whether the normal or compatibility path was used in the boot stages and Wi-Fi log;
4. leaves the safe minimal and frontend-only candidates without that authorization marker.

SSH is enabled by default and binds port 22 before first-time association. Once the UI obtains a DHCP lease, the initial test login is `root` / `plumos`. The password must be changed before use outside a trusted test network.

## Host verification

The following completed successfully:

- component checksums before the final overlay and a global checksum after it;
- catalog coverage for 97 systems and 196 launch-profile occurrences;
- dynamic load smoke test for all 114 libretro cores;
- full mini PLUS and PortMaster regression suites;
- release-content candidate audit: 12,481 files, 17 approved firmware files, zero user media, zero private keys;
- MBR partition geometry, FAT32/ext4 filesystem checks, raw boot-prefix comparison, and image readback verification;
- RTL8821CS ABI-policy, first-connect, SSH credential, and full-image contract tests.

## Device acceptance still required

The previously tested frontend-only image reached the frontend and accepted basic controller input. This full image itself has not yet been booted. Device acceptance still needs:

- full-image cold boot and boot-stage capture;
- RTL8821CS load result, association, DHCP, reconnect, and SSH login;
- emulator and application launch/exit coverage, including GPU-backed paths;
- audio, all controls, suspend/resume, reboot, shutdown, and SD readback.

Until those checks pass, the forced Wi-Fi module path must be treated as experimental and the image must remain non-publishable.
