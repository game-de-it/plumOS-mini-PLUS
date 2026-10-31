# Basic controls, power and sleep

## Frontend

| Control | Action |
| --- | --- |
| D-pad | Move through systems, games and settings |
| `A` | Confirm or launch |
| `B` | Back |
| `SELECT` on a game | Choose an available emulator or core |
| `START` | Open the main menu |
| Short power-button press | Open the power menu |

Set `SHOW EMPTY SYSTEM` to OFF in UI settings to hide systems with no games.
Refresh the list or reboot after adding or removing ROMs.

mini PLUS has four function keys and no physical analog sticks. The driver's
ABS axes and L3/R3 names are compatibility identifiers.

## Power

Use `Reboot` or `Shutdown` from the power menu or the `START` menu. The shutdown
path first terminates a stuck emulator. Do not remove a card until the display
and LED have turned off.

## Sleep

Open the power menu and choose `Sleep`; press power again to resume. Sleep is
available during games. After resume, check video, controls and the expected
speaker/headphone route.

## Volume and display

The physical volume down/up buttons change system volume, including during a
game. Hold `SELECT` while pressing volume down/up to change screen brightness in
20 steps; hold-repeat is supported. The same volume and brightness values are
available under `START` → `System Settings`. Contrast, hue and saturation are
also available there.

On mini PLUS, the twenty levels use a device-specific curve over the panel's
effective PWM range.

## Connectors

- USB: charge-only
- HDMI: currently unsupported
- SYS: top edge, boot/system SD1
- SD2: bottom edge, optional ROM/BIOS card

## Updates

`System Update` accepts signed Runtime and System packages. Runtime updates
replace managed apps/cores and roll back if startup is not confirmed. With a
compatible A/B initramfs, System updates write and read back the inactive slot,
try it on the next boot, and commit after the frontend is ready. An unsuccessful
trial returns to the previous slot on the following boot. Keep power connected
and do not interrupt an update.

Older boot implementations reject System packages and require a compatible full
SD image. System packages do not replace the kernel, DTB, initramfs or p2 matching
bundle. Updates preserve user ROMs, BIOS, settings, saves and states.
