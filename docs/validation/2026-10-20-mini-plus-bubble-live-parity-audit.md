# mini PLUS / Bubble live parity audit

Date: 2026-10-20

mini PLUS: live plumOS full-stack candidate

Bubble: live plumOS reference

Decision: **common app stack is present, but the mini PLUS candidate is not release-ready**

## Scope and method

The two running devices were inspected over SSH. The audit compared the managed app
layer, frontend assets and launch catalog, ALSA routing, emulator launch behavior,
network state and target-specific runtime metadata. Runtime tests stopped the
frontend completely before taking DRM/KMS ownership, isolated configuration,
save and state directories, forced volume to zero for the matrix, and restored the
frontend and the original mini PLUS volume afterwards.

The audit did not overwrite either device app layer or user content. It did not
repair the user SD card.

## Result summary

| Area | Result | Evidence and remaining boundary |
| --- | --- | --- |
| Managed app layer | PASS | `sha256sum -c checksums.sha256` passed on both devices. The live mini PLUS checksum manifest hash is `5c5ecac6dfd33e38cb5b459434ab746dc73d1fad04c6eb49a21ce842f659c195` and matches the host output. |
| Frontend and GGFE assets | PASS | Frontend, GGFE, menus, GGFE configuration, header and logo assets match Bubble exactly. Device-specific differences are limited to the intended device ID, Pyxel profile and mini PLUS input/SD2 wrappers. |
| Frontend runtime | PASS | The mini PLUS reached system stage `S40_FRONTEND_SUPERVISOR_READY`; exactly one controller UI process owned `/dev/fb0` before and after the test. |
| SD2 content discovery | **FAIL** | The user SD2 stores system directories at its root. The current wrapper only discovers `roms`, `ROMS` or `Roms`, falls back to SD1, and the frontend finds no user ROMs. Bubble works because its reference card has a `roms/` wrapper directory. |
| Audio device and PCM path | PASS at software/device level | Both devices expose `rockchip,rk817-codec` through `fe410000.i2s-rk817-hifi` and route `plumos_output` to `hw:0,0`. A direct PCM write passed on both; 32 representative routes reached RUNNING PCM with pointer progress on mini PLUS. Physical speaker loudness, headphones, mute and jack switching still need human/device acceptance. |
| Emulator catalog | PASS at package/catalog level | 97 systems, 196 profile occurrences, 114 unique source-core records, 116 RetroArch IDs, 20 PicoArch IDs and five standalone IDs resolve. The host catalog verifier passes. |
| Representative emulator runtime | PASS for tested routes | All 32 SFC/GB/GBA/N64/NDS routes started; every route owned DRM and made PCM progress. Mali-required N64 and DraStic routes loaded the Mali userspace driver; CPU routes did not load software GL. |
| Saturn runtime | PARTIAL | Standalone Yabasanshiro and RetroArch Yabasanshiro started with Mali and PCM progress. Beetle Saturn correctly failed because the mini PLUS user SD lacks `mpr-17933.bin`; this is a user-media BIOS gap, not a missing packaged core. |
| Wi-Fi and remote services | PASS for current boot | `wlan0` is associated with `192.168.10.141/24`, DHCP/default route work, and Dropbear, FTP and SMB are running. Saved-network reconnect and power-off race acceptance remain open. |
| Build/runtime metadata | **FAIL** | Source `runtime-coverage.json` lists `MPLUS-NET-02`, but the host app-layer output and live image still list `MPLUS-NET-01`. The final assemble-only build reused a stale frontend component cache. Runtime Wi-Fi works, but the build is not metadata-reproducible. |
| User SD health | WARNING | The kernel reports that `mmcblk3p1` was not properly unmounted and may be corrupt. No repair was attempted. Run an offline filesystem check before relying on writes. |

## Frontend parity

The following files are byte-identical by SHA-256 between the live Bubble and
mini PLUS:

- `bin/plumos-frontend`
- `bin/plumos-ggfe`
- `config/frontend/menus.json`
- `config/ggfe/ggfe.json`
- the GGFE header and logo assets

The intentional configuration differences are:

- `apps.json`: `device_specific` is `mini-plus` versus `bubble`.
- `systems.json`: the Pyxel profile is `pyxel:mini-plus` versus `pyxel:bubble`.
- launch wrappers: mini PLUS uses its own input finder and SD2 integration.

No Bubble menu, GGFE asset or common launch profile was found missing from the
mini PLUS package.

## SD2 integration omission

The live mini PLUS SD2 has content directories such as `gb/`, `gba/`, `snes/`,
`n64/`, `nds/` and `saturn/` directly at the volume root. It contains 10,611 files,
but `/storage/Roms` remained the SD1 fallback and the frontend scan found only the
built-in Pyxel entry and zero user ROMs.

The device log records:

```text
sd2_bind=result-unavailable content=roms fallback=sd1
```

`plumos-mini-plus-mount-sd2` currently calls:

```text
find_content_dir "$SD2_MOUNT" roms ROMS Roms
```

The existing contract test also covers only an `$sd2/roms` fixture. The fix must
add a guarded flat-root layout detector and a regression test without treating
arbitrary card roots as ROM trees. Until then, the frontend cannot provide the
normal game list for the user's actual mini PLUS media.

## Emulator runtime evidence

The representative matrix exercised every configured route for these systems:

| System | RetroArch routes | PicoArch routes | Standalone routes | Result |
| --- | ---: | ---: | ---: | --- |
| SFC | 7 | 7 | 0 | 14/14 started |
| GB | 5 | 3 | 0 | 8/8 started |
| GBA | 5 | 2 | 0 | 7/7 started |
| N64 | 2 | 0 | 0 | 2/2 started, Mali loaded |
| NDS | 0 | 0 | 1 | 1/1 started, Mali loaded |

Local evidence files and hashes:

- `artifacts/device-validation/2026-10-20-mini-plus-live-content-map.json`: `12995c1ae54133b49d4077702270eebfa895fb42ce1829a451684fc16eaf7d70`
- `artifacts/device-validation/2026-10-20-mini-plus-live-representative-matrix.json`: `d9486c91c408aa4b0e06f584f82d86554afe67439c5b37d0e323dde82a7688fc`
- `artifacts/device-validation/2026-10-20-mini-plus-live-saturn-matrix.json`: `14c8b49eebb954d1d80c0223e72b58877894737bf24c46167dedaba11f24ea9e`

The user SD did not contain suitable PSP, PSX or OpenBOR test content, so PPSSPP,
PCSX-ReARMed and OpenBOR were not live-launched in this audit. Their packaged
files and catalog routes pass checksum and host validation, but that is not a
substitute for mini PLUS runtime acceptance.

## Audio evidence and limits

Both devices report ALSA card 0 as `rockchip,rk817-codec`; playback and capture use
`fe410000.i2s-rk817-hifi`. Both use the same `plumos_output` softvol contract over
`hw:0,0`. The mini PLUS audio initialization log records
`audio_init=result-ok route=alsa-softvol`.

A bundled confirmation sample was written on mini PLUS at the restored volume 8
and the command completed successfully. That proves the ALSA write path, not that
the listener heard the physical speaker. Audible confirmation plus headphone,
mute and jack-switch checks remain required.

## Post-test state

- mini PLUS volume restored to 8 (`softvol` raw value 232)
- one frontend process restored and owning the display
- no validation bind mounts left active
- no emulator or test process left owning DRM or ALSA
- Wi-Fi, SSH, FTP and SMB remained available

## Acceptance decision

Bubble's common frontend, audio routing and emulator assets are present on the
mini PLUS, and the tested runtime routes work. The port nevertheless fails the
plumOS release gate because the actual flat-root SD2 layout is not exposed to the
frontend and because the assembled artifact contains stale runtime-coverage
metadata. Complete mini PLUS acceptance also still requires all physical controls,
speaker/headphone behavior, clean power management and SD readback.
