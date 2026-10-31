# mini PLUS runtime validation scope and known limits

[日本語](2026-10-31-mini-plus-runtime-limitations.ja.md)

All 97 catalog entries, 196 launch routes and 114 packaged cores remain represented. configs/mini-plus-runtime-validation.json is the machine-readable ledger; scripts/summarize-mini-plus-runtime-validation.py --verify checks both directions against the current catalog. Missing content/BIOS is not automatically an unsupported runtime.

| Classification | Routes | Evidence / limit |
| --- | ---: | --- |
| Machine launch confirmed | 170 | PCM advanced on 166; this is not universal visual, audible or control acceptance |
| Missing parent archive | 2 | CPS1 fbalpha2012_cps1 and CPS2 fbalpha2012_cps2; child ROMs alone are insufficient |
| Missing BIOS | 1 | Channel F/freechaf: sl31253.bin, sl31254.bin, sl90025.bin |
| Missing compatible content | 20 | WonderSwan Color, X68000, TIC-80, Vectrex, BK, Daphne, Flashback, Palm, Rick Dangerous, four SG-1000 routes, Sharp X1, Wolf3D, ZX81, Arduboy, Mega Duck, PuzzleScript, Super Bros War |
| Invalid NGP content | 1 | SD2 archive read failure and no compatible monochrome NGP content |
| Invalid VMU content | 1 | Missing VMS payload matching the metadata |
| External-port separate test | 1 | PortMaster is outside the finite emulator harness. Apotris separately passed with guarded v4.1.0; this does not accept every port |

The 26 unaccepted routes remain in the FE/catalog. Further tests require compatible content, BIOS or parent archives supplied by the user. Do not add user ROM/BIOS data to distribution artifacts. Completing the ledger does not turn these routes into device passes.
