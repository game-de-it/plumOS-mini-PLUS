# Hardware services

[日本語](hardware-services.ja.md) | [Developer guide](README.md)

configs/input/mini-plus-controller-map.json is the canonical input map. There are no sticks and four FN keys. Driver ABS/L3/R3 names remain compatibility aliases. The menu key is the round key above-right of START; the screenshot FN's physical position is unconfirmed.

The volume-key service handles SELECT + volume for 20-step brightness. mini PLUS needs its measured PWM curve; the Bubble curve produced almost no change at levels 1–12. Preserve volume-only behavior and hold handling.

Power actions quiesce games and writers before reboot/shutdown. Resume restores display state as well as audio/input. USB-connected Sleep uses the narrowly patched stock kernel; the original Image is retained. SDR104 uses the verified overlay and ran at 148.5 MHz on the tested card.

Review [USB Sleep evidence](../validation/2026-10-31-mini-plus-usb-sleep.md). USB/no-USB, speaker/headphone, renderer and input acceptance remain distinct. This device has no lid-close policy; USB is charging only and ADB/HDMI are unavailable.
