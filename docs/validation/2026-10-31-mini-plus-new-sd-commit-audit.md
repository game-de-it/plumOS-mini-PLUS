# 新SDのコミット反映監査

2026-10-31、`192.168.10.141`の新規SDを読み取り中心に照合した。
対象はmini PLUS移植開始以降の実装と、継承したruntime全体。
稼働manifestは`0.1.0-dev-20261031-firstboot`、source `ee3a984`。
以後の`9083599`は成果物の記録文書であり、runtime変更を含まない。

## 結果

実装済み変更の新SDへの配備漏れは見つからなかった。

| 対象commit / 機能 | 新SDでの証拠 | 判定 |
|---|---|---|
| `b4e9f0e`以降のmini PLUS boot基盤 | MBR以降のprefix一致、p1予定24 file全件hash一致 | 反映済み |
| `6c8abbd` / `5b62e1f` System A/B・可変SD領域 | System A/B hash一致、p2 raw全64 MiB一致、p3 8 GiB/p4作成log | 反映済み |
| `27f1fb4` stock Wi-Fi | matching System hash、bcmdhd稼働、Wi-Fi経由SSH | 反映済み |
| `76a4d43` 音声・GB色・PicoArch補正 | launch/audio scriptとGB設定のsource一致、Pico config修正patch hashをcomponent manifest内で確認、binary checksum一致 | 反映済み |
| `2699b4a` / `427c28a` SDR104 | overlay/uEnv一致、実動作SDR104・148.5 MHz | 反映済み・稼働確認 |
| `3c9cde8` / `272be6c` / `54d2400` PortMaster/Apotris | PWM互換、既知port互換guard、launcher/cleanupを含むpackageと実機checksum一致 | 反映済み |
| `78f4441` / `8e1961a` 輝度hotkey・curve | service再build byte一致、実行中exe一致、curve linear-52-255-v1・level10/raw148 | 反映済み・service稼働 |
| `4b5b8cd` Reboot/Shutdown時のFE抑止 | frontend launch / power overlay / finalizerのsource一致 | 反映済み |
| `62fe884` Sleep復帰の画面復元 | broker/master/shareを現ソースで再buildしてbyte一致、quiesce script一致 | 反映済み |
| `3a2ddb3` / `427c28a` USB接続Sleep | active Image-usb-sleepのhashとuEnv選択一致 | 反映済み |
| `ee3a984` 初回進捗表示 | initramfs hash一致、全7工程written log、ユーザーの実機表示確認 | 実機合格 |

## ファイルとソースの照合

- live `checksums.sha256`はhost成果物と同一の
  `257ff0320eb79b57f4d4306b16c936f6e58a97044c6a6caacb2b3ae0cd9b4339`。
- live global checksumは12,482/12,482件成功。空白を含むpathの欠損もない。
- app manifestもhostと同一の
  `ff4e4359f994ee8ff6373f7d8a8e853c5795efac00bdf9c1b06871ab1cb5f3f8`。
- componentのcopy順を適用した有効package source 198 fileが、成果物のmanaged hashと全件一致。
  frontendの旧network-services stubは後続network-services componentが置換する正常な構成。
  host Pythonの非配布bytecode 3 fileは除外した。
- FE、volume-keys、DRM master、DRM broker、DRM shareの5 binaryを現在のsourceから
  同じcompiler flag/strip条件で独立再buildし、成果物とbyte一致。
  稼働中FE/volume-keysの`/proc/PID/exe`も配備fileとhash一致した。
- frontend component ref `427c28a`以後はそのsource/patch/configに差分がない。
  RetroArch component ref `8fd43aa`以後も、そのbuild scriptとRetroArch patch群に差分がない。
  PortMaster ref `54d2400`以後も、そのpackage/build scriptに差分がない。
  古いcomponent refだけを根拠に未反映とは判定しない。
- active `/init`は現在の`rootfs/mini-plus-frontend/init`とhash一致した。
- FEはSD2 `roms`/`bios`をrw解決し、536 ROMを索引化している。

照合中はゲーム起動、入力注入、輝度操作、再起動、Sleep、managed file更新を行っていない。
今回の判定はコミット内容の配備確認であり、新SDで全ゲームの画像・可聴音・controller・
Sleep復帰を再度物理試験したという意味ではない。

## 残存する説明の不整合

PicoArch manifest/build scriptとinput mapにはdual analog/stickの古い説明が残っている。
物理stick無しというユーザー確認と整合しないが、元ソースにも存在するため配備漏れではない。
`MPLUS-META-02`で追跡し、正常な入力mappingをこの監査で削除・変更してはいない。

採取資料: `artifacts/device-validation/2026-10-31-new-sd-commit-audit/`。
