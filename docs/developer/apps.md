# Application integration

[日本語](apps.ja.md) | [Developer guide](README.md)

The [user app guide](../user/apps.md) lists the nine visible entries and exit methods. apps.json also contains helper actions; do not present every helper as a separate menu app.

Use normal FE launchers for File Manager, Music Player, Pyxel, PortMaster and GGFE. Preserve one display owner and clean child-process exit. PortMaster updates/downloads and installed-state records are mutable user data; Runtime assembly must not overwrite them.

GGFE is independent from the ordinary Gallery. Its SELECT settings menu provides Exit; B/START are not carousel exit shortcuts. Apotris has a build-specific compatibility guard, not a general PortMaster runtime replacement.

Repair SD2 must identify SD2, confirm the request, release mounts safely and never target SYS. Keep repair and filesystem tests on fixtures or expressly authorized spare media.
