# mini PLUS Apotris PortMaster compatibility validation

Date: 2026-10-21  
Device: GKD mini PLUS at `192.168.10.141`  
Scope: Apotris audio, crash, PWM compatibility, PortMaster lifecycle and live deployment

## Failure reproduced

The PortMaster release installed on SD2 contained Apotris v4.2.0. Its AArch64
executable had SHA-256
`3fe5e66ed7c184f7cda3ae6161f5004f4937a16dd4a19b51b5f463ffc42fc7ec`,
matching the official 2026-10-20 package exactly.

Two user launches at `02:29:07Z` and `02:29:24Z` both logged
`Failed to open PWM: No such file or directory` and then terminated the game
with `SIGSEGV`. A pre-fix managed launch at `02:52:00Z` redirected the missing
PWM files successfully but the same v4.2.0 executable still received `SIGSEGV`
after 16 seconds. PCM remained closed. This separated the missing raw PWM path
from the remaining v4.2.0 crash.

No OOM kill, SD/MMC I/O error, filesystem error, new Mali/DRM fatal error or
global RK817 route failure accompanied these crashes. PortMaster session cleanup
and frontend restoration were clean.

## Version A/B

The immediately preceding official repository revision
`735c89c0c666eef6602a54e144cdfa55bcf165fa` supplied Apotris v4.1.0 with
SHA-256
`86ba76c37c45ba56271a51c01688a90c37bf27d067d302b994fbb0e8216d0c06`.
The v4.2.0 binary and `Apotris.sav` were hash-backed up before the comparison and
restored byte-for-byte afterward.

Under the same launcher, assets, controller mapping, Mali runtime, ALSA router
and save data, v4.1.0:

- opened RK817 playback and kept ALSA PCM in `RUNNING` state;
- advanced `hw_ptr` and `appl_ptr` continuously;
- produced physically audible sound confirmed by the user;
- ran for approximately 90 seconds without `SIGSEGV`;
- exited normally and restored the frontend.

The regression is therefore isolated to the v4.2.0 executable rather than the
plumOS audio route or the installed game data.

## Implemented compatibility boundary

Source commits:

- `3c9cde8`: exact-path raw PWM compatibility and port exit/PCM diagnostics;
- `272be6c`: SHA-gated Apotris v4.1.0 fallback selection;
- `54d2400`: exact Apotris bind-target cleanup allowlist and regression test.

The hardware shim only redirects absent
`/sys/class/pwm/pwmchip{0,1}/pwm0/duty_cycle` accesses to two no-op files under
`/run/plumos/portmaster`. Existing PWM files and unrelated paths are preserved.
It does not export a kernel-owned PWM channel.

The known-port guard applies only when the installed Apotris executable matches
the exact rejected v4.2.0 SHA. It verifies the fallback SHA before bind-mounting
v4.1.0 for that launch. The installed SD2 file stays unchanged, an already-good
v4.1.0 runs directly, and unknown future hashes run without substitution. A
missing or corrupted fallback fails closed instead of launching the known-bad
binary.

The mount cleanup allowlist accepts only
`Roms/PORTS/apotris/Apotris.aarch64` in addition to its existing private mount
targets. Host tests verify missing-PWM redirection, real-PWM preservation,
unrelated-path preservation, exact SHA selection, missing-fallback rejection,
future-version pass-through and exact bind cleanup.

## Managed live deployment

Only PortMaster-managed files and their matching metadata entries were updated.
The installed port, ROMs, credentials and user settings were excluded. The
verified fallback is mutable PortMaster compatibility state with a provenance
record, not a managed app-layer payload.

Rollback artifacts:

- PWM shim deployment:
  `/storage/plumos/state/app-deploy/20261021-apotris-pwm/rollback.tar`
  - SHA-256 `ed2d8da9446003900d5d6dd93989ece4da1f0d790d28c693df153a6c68c3ba8d`
- v4.1.0 guard deployment:
  `/storage/plumos/state/app-deploy/20261021-apotris-v41-guard/rollback.tar`
  - SHA-256 `12080e085c9611271ed6baa95d8997d40313d63a8f8e015c96d10db4d5b30f2e`
- exact mount cleanup deployment:
  `/storage/plumos/state/app-deploy/20261021-apotris-mount-cleanup/rollback.tar`
  - SHA-256 `9b39a06464c5baef05d74383a2026df6f69efcc98a0945764bf3e92bcbf2c08f`

After the final deployment, all 246 PortMaster component entries and all 12,482
global app-layer entries passed. The final global checksum file SHA-256 is
`cbc0f8655fc9b67473e5cadb065942d71dd2b1e31237f5604ae66ca4d1cfbe8e`.

## Final device evidence

A normal guarded launch ran from `03:03:24Z` through `03:06:19Z`. The log selected
the v4.1.0 fallback, PCM was `RUNNING`, no `SIGSEGV` occurred, the user exited
normally, and session cleanup was clean. The save changed during this accepted
play session from SHA-256
`a9026da4f679fdf323464b2054100b4c3d9b56615c2de62ef9177d582c19c436`
to `2c3fea4c5f885245a1152be5f45b98e4b9ff98bf20e678ae02a6f2a20505accf`;
this user-owned change was preserved.

A second guarded launch at `03:13:21Z` kept PCM `RUNNING` and was stopped after
25 seconds through the managed PortMaster stop path. Exit code 143 was expected
for this deliberate TERM. Cleanup removed the bind, emptied `port.mounts`,
closed PCM, restored exactly one frontend process and exposed the unchanged
underlying v4.2.0 SHA on SD2. The PortMaster component checksum passed again.

Apotris is accepted on mini PLUS through the verified v4.1.0 compatibility
route. A future upstream executable must complete the same audio, stability and
cleanup checks before the SHA-specific fallback can be retired.
