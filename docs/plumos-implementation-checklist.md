# plumOS implementation checklist

[日本語](plumos-implementation-checklist.ja.md)

These device-independent requirements derive from Bubble's architecture and release process. Do not copy partition numbers, DTB names or driver assumptions between devices. Boot substrate, device identity, display/input/audio/network drivers are device-specific; ownership, update transactions and acceptance boundaries are shared.

Status: PASS requires all evidence for the target artifact; PARTIAL means implementation/host evidence exists but integration/device proof is incomplete; FAIL means the requirement is unmet or contradicts the artifact; PENDING means an acceptance gate has not been run.

| ID | Requirement | Required evidence |
| --- | --- | --- |
| PLM-ART-01 | Track raw image and compressed distribution separately | Names, sizes, hashes; extracted raw hash matches |
| PLM-ART-02 | Size the seed from actual payload plus explicit headroom | Capacity calculation, free-space gate, partition manifest |
| PLM-ART-03 | Safely expand managed storage and create user media on first boot | Resumable fixtures and device first boot |
| PLM-ART-04 | Rebuild from clean checkout and pinned inputs | Build record, component checksums, image verifier |
| PLM-ART-05 | Exclude ROMs, saves, credentials and private keys | Content audit and secret scan |
| PLM-ART-06 | Promote the exact accepted raw bytes | Tested hash matches promotion manifest |
| PLM-BOOT-01 | Pin device prefix/kernel/DTB/overlay/initramfs | Inventory, build hash gates, readback |
| PLM-BOOT-02 | Keep boot matching set outside Runtime updates | Matching manifest, image hashes, recovery policy |
| PLM-SYS-01 | Read-only SquashFS System | Extracted hash and mount evidence |
| PLM-SYS-02 | A/B active/pending/healthy state and inactive readback | Verifier, successful switch and failure rollback |
| PLM-STO-01 | Separate managed Runtime/state from user/update/media ownership | Labels, mounts, ownership tests |
| PLM-STO-02 | Resumable resize/provisioning with persistent intent | Interruption and unknown/existing-partition safety fixtures |
| PLM-STO-03 | Boot filesystem read-only after normal boot | Device mount table and rejected writes outside updater |
| PLM-STO-04 | Resolve SD2 by identity; tolerate absence/dirty/unsupported media | Host tests, device fallback/reinsertion |
| PLM-STO-05 | Stop writers and unmount/remount read-only before power action | Finalizer tests and post-boot fsck/readback |
| PLM-FE-01 | Automatic FE startup with display and controls | Exact-image boot and input evidence |
| PLM-FE-02 | Correct physical buttons, available sticks, FN and hold/hotkeys | evdev/js map and physical matrix; mini PLUS has no sticks |
| PLM-EMU-01 | Bidirectional catalog/profile/runtime resolution | Catalog verifier and core-load smoke |
| PLM-EMU-02 | Software/PicoArch/GLES/standalone launch, exit and FE return | Device renderer matrix |
| PLM-APP-01 | Standard applications launch and exit | Host contracts and device app matrix |
| PLM-HW-01 | LCD, speaker/headphones, volume/mute, sleep/resume, performance | Device hardware acceptance |
| PLM-NET-01 | Matching Wi-Fi module/kernel ABI; normal load | vermagic/symbol CRC and load evidence |
| PLM-NET-02 | UI scan/save/reconnect without embedded credentials | Clean-image audit and first-connect/reconnect |
| PLM-NET-03 | DHCP, SSH/SFTP and device-generated host keys | IP/listener/login/key evidence |
| PLM-NET-04 | Optional FTP/SMB lifecycle and power coordination | Listener/settings and shutdown evidence |
| PLM-UPD-01 | Signed Runtime target/ABI/version, staging, journal, health, rollback | Host and device update/recovery |
| PLM-UPD-02 | Inactive System write/full readback then atomic state commit | A/B, downgrade refusal, bad-slot recovery |
| PLM-REC-01 | Visible stages, persistent failure logs and recovery route | Stage readback and recovery shell/known-good media |
| PLM-LIC-01 | Separate MIT, stock/vendor and third-party rights | Inventory, vendor audit, publication policy |
| PLM-DOC-01 | User docs match actual paths, partitions and features | Manifest/docs consistency |
| PLM-REL-01 | Exact full-image write/readback, three cold boots and hardware/runtime gates | Dated device acceptance tied to SHA-256 |
| PLM-REL-02 | Verifier, compression, archive test, extracted hash and SHA256SUMS | Release bundle log |

Source implementation, passing host fixtures, inclusion in an image and device operation are distinct evidence. Do not carry a pass from another image to a new one. Final release gates must refer to the same raw hash. During pre-release work, compression can be deferred; this does not mark final packaging complete.
