# GKD mini PLUS stockOS read-only inventory — 2026-10-20

## Media identity and safety boundary

- media: `/dev/disk5`, Apple SDXC Reader, Secure Digital, removable
- whole-media size: `124383133696` bytes
- partition map: MBR
- p1: `/dev/disk5s1`, FAT32 `EMUELEC`, offset 16 MiB, mounted read-only during capture
- p2: `/dev/disk5s2`, Linux ext4, `2999975936` bytes
- policy: source media is read-only; no plumOS output is written to it

macOS initially mounted p1 writable before the investigation and created `.Spotlight-V100` and `.fseventsd`. They were not deleted. After identification, p1 was remounted read-only.

## Active boot contract

- boot prefix: first 16 MiB, SHA-256 `aa8bd95d5d75aaab1977c5e58732d67545221649a08e6b7afda36aee208e26e9`
- kernel: `Image`, SHA-256 `670c32a86cf006a574d5ec498df6c14e3ac61af6ed6b109f458b5711c228da56`
- kernel release: `4.19.193-g5a07852a55cf-dirty`
- stock external initrd: SHA-256 `8db4355a4df5224cc314e1c6554d73df48dc707968180286ff402a65fd3f4818`
- selected DTB: `rockchip/rk3566-gkdmini-pro.dtb`, SHA-256 `8e864607d2188d98fdcbc4f3ee961628585c7f7d5c2b10d77a45fee795407781`
- overlays: `rk3568-fiq-debugger-uart2m0`, `rk3568-disable-npu`
- stock root UUID: `69555c06-98f0-4639-85af-768facc97fd9`

The stock kernel contains an embedded initramfs at offset `16221060`. Its `init` accepts `SYSTEM_IMAGE`, mounts p1 at `/flash`, p2 at `/storage`, and mounts the selected SYSTEM as the root. A separate Debian initramfs-tools archive also exists on p1, but the captured `uEnv.txt` does not define `initrdimg` or `initrdsize`; whether U-Boot defaults activate that file requires live-environment evidence. plumOS mini PLUS explicitly supplies its own external initramfs, which overrides the embedded root-selection flow while keeping the same p1 SYSTEM / p2 storage boundary.

The read-only p2 image has UUID `69555c06-98f0-4639-85af-768facc97fd9`, SHA-256 `1f3cb01041dea04a7e504413ba06352de3b1a6f7d78e2cbf420fb43dcc11e522`, and contains user/application storage rather than a conventional Linux root filesystem.

The complete active-file hashes are recorded in `configs/mini-plus-stock-active-boot.expected.sha256`. The complete captured DTB inventory is ignored from Git but has aggregate SHA-256 `3b43ba93b6ea69895f74e232ecc66c839973a8236ee4acbd4cbebef242595573`.

## Stock SYSTEM boundary

- stock `SYSTEM`: SquashFS/LZO, SHA-256 `abe0bb60006a6c54f3995c1190cee47907d34636ed9f61fb020db30add333147`
- OS identity: `MINIPLUS`, build date `2024-06-07`, RK3566/aarch64
- policy: analysis-only; the complete stock SYSTEM is not copied into plumOS output

Individually captured ABI inputs are listed in `configs/mini-plus-stock-runtime.expected.sha256`. The AArch64 and ARMhf Mali pair matches the Bubble capture hashes. The offline stock `SYSTEM` inventory contained an `8821cs.ko` reporting `vermagic=4.19.172 SMP mod_unload aarch64`; that file does not match the stock kernel and is not the mini PLUS internal Wi-Fi driver.

Live stockOS inspection over SSH corrected the offline inference. The internal radio enumerates as SDIO `02D0:A9A6` and is bound to `bcmsdh_sdmmc` from `bcmdhd.ko`. The live module reports the exact stock kernel ABI, `4.19.193-g5a07852a55cf-dirty SMP mod_unload modversions aarch64`, and creates `wlan0`. At interface bring-up it selects `/etc/firmware/fw_bcm43438a1.bin` and `/etc/firmware/nvram_ap6212a.txt`; both open successfully, the firmware starts, and stockOS associates normally. The DT-side `wifi_chip_type = ap6330` name is therefore only a platform selector and does not supersede the observed SDIO ID and driver-selected AP6212A/BCM43438A1 payload.

The correct live Wi-Fi set is:

| File | Bytes | SHA-256 |
|---|---:|---|
| `bcmdhd.ko` | 24,719,608 | `b6cb52f3f8fd1e47d53e030a9d18acb6659937c6f25f5f77d333298682315c7f` |
| `fw_bcm43438a1.bin` | 414,579 | `c587abd06865aab98290e1bdd1e9185cfb5c30f89af329c77e0202afe4b932c1` |
| `nvram_ap6212a.txt` | 1,002 | `d3bb6e76a248f392dbc200b86cdc71e0056003c6fbddd34138832db8dd653dd9` |
| `regulatory.db` | 4,896 | `0a4abd7ae20d07bb70642937ccb2293a72a6504730eea45a698882599f586368` |
| `regulatory.db.p7s` | 1,182 | `bcd81aed039ea6b9b6f3726fbf26911a0caf4a5d894210e0fa2effb384d6b326` |

The driver also probes `/etc/firmware/clm_bcm43438a1.blob` and `/etc/firmware/config.txt`, but neither file exists in stockOS and both are explicitly ignored by the live driver. They are not required members of the captured set.

## Acceptance limit

This inventory proves source identity and host-side extraction only. It does not prove physical boot, LCD timing, controller mapping, audio, networking, suspend, shutdown or readback behavior.
