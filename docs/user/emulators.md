# Emulator exit, menu and hotkey reference

[日本語](emulators.ja.md) | [User manual](README.md)

## Find the menu key first

The **menu key is the round key above-right of START**. Its driver alias is Function 1 (F1, evdev 704 / js17), not a physical numbering of the four function keys. See the [body photo](../../README.md).

## Exit or resume

| Runtime | Open menu | Return to FE | Resume game |
| --- | --- | --- | --- |
| RetroArch (RA) | Menu key | Hold `SELECT`, press `START`; repeat if quit confirmation asks. Alternatively use `Quit RetroArch` in the main menu | Same menu key or `Resume` |
| PicoArch (PICO) | Menu key | Menu's `Exit` item | `Resume game` or equivalent |
| PPSSPP (PSP) | Menu key | Pause menu's exit item; this port launches games with pause-menu-exit | `Continue` or equivalent |
| PCSX-ReARMed standalone (PS) | Menu key | Menu's exit item | Resume item |
| YabaSanshiro (Saturn) | Menu key | Menu's exit item | Resume item |
| DraStic (DS) | Menu key opens the normal menu | Normal menu's quit item | Normal menu's resume item |
| OpenBOR | Menu key / `START`, where supported by the title | Game's quit item; title-specific | Game's resume item |
| PortMaster / Ports | Game's pause/settings menu | Game's own exit item | Game's resume item |
| Pyxel | Application-specific | Application's own exit control | Follow the application |

Follow the on-screen confirm/cancel hints inside each emulator. `Back` and `Resume` do not quit. RetroArch's `Close Content` is also different from quitting RetroArch.

Do not assume RA's `SELECT + START` works in every emulator or port. Normal exit restores the FE automatically. Use [power recovery](#if-an-application-stops-responding) for an unresponsive application.

## RetroArch in-game hotkeys

Hold `SELECT` first, then press the other key. User changes to bindings take precedence.

| Control | Action |
| --- | --- |
| `SELECT` + `START` | Quit to FE; repeat if confirmation asks |
| `SELECT` + `R` | Save state |
| `SELECT` + `L` | Load state |
| `SELECT` + D-pad left/right | Previous/next state slot |
| `SELECT` + `Y` | Toggle FPS display |
| `SELECT` + `R2` | Toggle fast-forward |
| `SELECT` + `L2` | Toggle slow motion |
| Menu key, without SELECT | Toggle RA menu/game |

Loading a state replaces current progress. States are not necessarily compatible between cores or RA/PICO. Also use normal in-game saves; see [save locations and backup](save-data.md).

## Screenshots

- **Frontend:** menu key above-right of START. Saved on SD1 in `Screenshots/` (`/storage/Screenshots/`).
- **RetroArch game:** menu key → `Quick Menu → Take Screenshot`. Default destination: SD1 `Images/` (`/storage/Images/`).
- A separate screenshot FN binding (driver F2 / js10) exists, but its physical location is unconfirmed. This guide uses the reliable menu route.

## System-wide volume and brightness

| Control | Action |
| --- | --- |
| Volume − / + alone | System volume |
| `SELECT` + volume − / + | Twenty-level display brightness |
| Short power press | Power menu |

These work in the frontend and games, independently of RA hotkeys.

## Game Gear frontend (GGFE)

Launch `START → Apps → Game Gear`. This application is separate from the ordinary Gallery view.

| Control | Action |
| --- | --- |
| D-pad left/right | Previous/next, hold-repeat and wrap |
| D-pad up/down | Jump five entries |
| `A` | Launch with selected RA/PICO route |
| `X` | Toggle cartridge case |
| `SELECT` | Settings/exit menu |
| `B` / `START` while browsing | Not the exit control |

Exit GGFE through its `SELECT` menu. Once a game launches, use that RA/PICO runtime's controls.

## If an application stops responding

Short-press power, then choose `Reboot` or `Shutdown`. The system terminates the foreground application before the power action. Wait for the display and LED to turn off before removing cards. Prefer normal application exit when available.

## Apotris compatibility

Only the known incompatible Apotris v4.2.0 executable is temporarily replaced during launch with the device-validated v4.1.0 compatibility copy. Different future executable hashes are left alone. This does not provide universal controls or compatibility for every port.
