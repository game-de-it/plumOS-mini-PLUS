# Audio routing

[日本語](audio-routing.ja.md) | [Developer guide](README.md)

mini PLUS uses the stock-compatible RK817 ALSA path. plumos-mini-plus-audio-init and plumos-audio-output in package/frontend-mini-plus/plumos/bin/ establish routing; the SPK_HP correction and runtime-specific initialization are part of the port.

Inspect /proc/asound/cards and /proc/asound/card*/pcm*/sub*/status for device/PCM evidence. Advancing PCM does not prove audible sound. Test speaker and headphones, insertion/removal, left/right, volume/mute, exit/relaunch and resume separately.

RetroArch, PicoArch, standalone and PortMaster runtimes need independent checks. The Apotris compatibility fix is limited to the identified build; see [the device record](../validation/2026-10-21-mini-plus-apotris-portmaster.md). Do not globally replace SDL/ALSA libraries to fix one port.

For a black display with continuing audio, investigate display resume too; audio survival is not successful wake acceptance.
