# GKD mini PLUS live stock Wi-Fi反映後のSD image再ビルド

Date: 2026-10-20

## 結論

live stockOS上で実際に`wlan0`を生成しているWi-Fi stackを採取し、不適合だった
offline `8821cs.ko`の強制load経路を廃止した。修正済みsource `b2e2c7f`からSD imageを
再生成し、image内部の全checksum、filesystem、Wi-Fi ABI、app layer、archive展開後のraw hashを
ホスト上で検証した。

配布対象の7zは**485,622,918 bytes（463.13 MiB）**であり、Bubbleと同じく500 MB未満である。
raw imageの2.9 GBはSD上のpartition geometryとapp seed領域を含む論理サイズであり、
配布アーカイブサイズではない。

## 成果物

| 種類 | file | bytes | SHA-256 |
|---|---|---:|---|
| raw | `output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.img` | 2,902,458,368 | `1cf6f7cf63a0505f0389f2f36d665a07fc84293ce9addb5a9b5baefbc26a256a` |
| 7z | `output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.7z` | 485,622,918 | `96e6c48530f315492bf20fc5fb1ccdcc8bf525c3a46e668a325fbb04afe1e4f6` |

- image format: `plumos-mini-plus-full-stack-validation-image-v3`
- image source ref: `b2e2c7f`
- publication state: `publishable=no`
- `7zz t`: success
- archive round-trip: 展開後raw SHA-256が上表と一致

## live stockOSで確認したWi-Fi stack

| 要素 | 値 |
|---|---|
| SDIO ID | `02D0:A9A6` |
| bus driver | `bcmsdh_sdmmc` |
| module | `bcmdhd.ko` |
| kernel ABI | `4.19.193-g5a07852a55cf-dirty SMP mod_unload modversions aarch64` |
| module SHA-256 | `b6cb52f3f8fd1e47d53e030a9d18acb6659937c6f25f5f77d333298682315c7f` |
| firmware | `fw_bcm43438a1.bin` |
| firmware SHA-256 | `c587abd06865aab98290e1bdd1e9185cfb5c30f89af329c77e0202afe4b932c1` |
| NVRAM | `nvram_ap6212a.txt` |
| NVRAM SHA-256 | `d3bb6e76a248f392dbc200b86cdc71e0056003c6fbddd34138832db8dd653dd9` |
| regulatory DB SHA-256 | `0a4abd7ae20d07bb70642937ccb2293a72a6504730eea45a698882599f586368` |

moduleのkernel releaseとvermagicは一致し、`CONFIG_MODVERSIONS=y`に対応する`__versions`を持つ。
image内では`firmware_path=/etc/firmware/fw_bcmdhd.bin`と
`nvram_path=/etc/firmware/nvram.txt`を指定した通常loadのみを行う。`insmod -f`は使用しない。

## ホスト検証

- raw boot prefix、MBR、p1/p2/p3 geometryとpartition checksum
- FAT/ext4/SquashFSの整合性、System A/B、matching boot bundle
- first-boot時のp3拡張とp4 `PLUMOS`作成の中断再開fixture
- Wi-Fi module/kernel ABI、symbol CRC、firmware/NVRAM/regulatory DB hash
- 資格情報なしのSSID scan経路と保存済み設定保持
- 97 systems、196 launch profiles、114 libretro cores、app layer全checksum
- `7zz t`とstreaming展開後のraw SHA-256一致

## 実機acceptanceで残る項目

この記録は「イメージ内に正しいdriver stackが入っている」ところまでの証拠である。
plumOSでのWi-Fi動作確定ではない。空のテスト用SDへ書き込んだ後、次を実機で確認する。

1. cold boot、LCD、frontend到達、controller入力
2. SettingsのWi-Fi画面にSSIDが表示されること
3. association、DHCP、再起動後のreconnect
4. `root` / `plumos`、TCP 22でのSSH/SFTP接続
5. shutdown/suspendとWi-Fiの競合、全入力、音声、emulator/GPU runtime
6. 書き込み後SDのraw readback SHA-256

上記が合格するまでは`publishable=no`を維持する。
