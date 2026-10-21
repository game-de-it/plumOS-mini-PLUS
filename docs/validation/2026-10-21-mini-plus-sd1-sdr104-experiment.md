# mini PLUS SD1 SDR104高速化実験

日付: 2026-10-21

## 目的

同一メーカー・容量規格のSDカードを使ってもBubbleよりmini PLUSの起動前半が遅い原因を分離し、
ROM、BIOS、設定、セーブを保持した128 GB検証カード上で可逆的にSD1を高速化する。

## 実測baseline

両機とも起動時は既存frontend indexを利用し、ROM全走査を省略していた。

| 項目 | Bubble | mini PLUS |
|---|---:|---:|
| SD1 mode | SDR104 | SDR50 |
| SD1 clock | 148.5 MHz | 50 MHz |
| 64 MiB matching検証 | 1.41秒 | 3.11秒 |
| System検証 | 0.39秒 | 1.42秒 |
| frontend起動開始 | 4.60秒 | 8.59秒 |

mini PLUSとBubbleのlive runtime DTBで`/dwmmc@fe2b0000`を比較すると、SD1 nodeの差は
Bubbleにのみ存在するempty property `sd-uhs-sdr104`だった。`max-frequency=150000000`、
`bus-width=4`、`vmmc-supply`、`vqmmc-supply`を含む他propertyは一致した。

## 変更方式

mini PLUSのstock由来base DTBは変更しない。既存boot scriptが提供する`overlay-user`経路で
`configs/device-tree/mini-plus-sd1-sdr104-overlay.dts`を適用し、
`/dwmmc@fe2b0000`へ`sd-uhs-sdr104`だけを追加する。

適用スクリプトはactive DTBのSHA-256、`fdtfile`、kernel versionを確認し、変更前の`uEnv.txt`と
DTBをホスト側`artifacts/hardware/`およびカード上`plumos-probe/sd1-sdr104-backup/`へ保存する。
既存の別user overlayがある場合やrollback backupが既にある場合は上書きしない。

```sh
./scripts/prepare-mini-plus-sd1-sdr104-test-macos.sh --apply /Volumes/PLUMBOOT
```

カードが起動しない場合はmacOSへ戻し、次で元の`uEnv.txt`へ復旧する。

```sh
./scripts/prepare-mini-plus-sd1-sdr104-test-macos.sh --rollback /Volumes/PLUMBOOT
```

## 実機acceptance

以下が揃うまで通常imageの既定値にはしない。

- [ ] 5回以上の完全電源OFFからのcold bootでfrontendへ到達する
- [ ] `dmesg`でSD1がSDR104、約150 MHzとして初期化される
- [ ] tuning failure、CRC、timeout、I/O errorがない
- [ ] 起動stageとfrontend ready時刻を採取し、baselineより改善する
- [ ] p1/p2/p3/p4の読み取りと書き込みに異常がない
- [ ] macOSへ戻した後のfilesystem検査と管理対象ファイルのSHA-256照合が通る
- [ ] Wi-Fi、音声、frontend、代表エミュレーター起動に回帰がない

SDR104はSDカードと基板配線の信号品質へ依存する。1回の起動成功だけでは採用しない。

## 128 GB検証カードへの適用

2026-10-21、`/dev/disk5`（123,773,911,040 bytes）の既存4-partition検証カードへ適用した。
変更対象はp1 `PLUMBOOT`上の`uEnv.txt`と新規user overlayだけで、base DTB、System、
ROM/BIOS/設定/セーブを含むp4 `PLUMOS`は変更していない。

- base DTB SHA-256: `8e864607d2188d98fdcbc4f3ee961628585c7f7d5c2b10d77a45fee795407781`
- overlay SHA-256: `675bca0f0c8a91db7333010bedac1471222b3dd8ed5d0ef029cb74ec05dcf776`
- card rollback: `PLUMBOOT/plumos-probe/sd1-sdr104-backup/`
- host rollback: `artifacts/hardware/mini-plus-sd1-sdr104-20261021T014436Z/`
- p1 FAT32 read-only fsck: exit 0
- p4 FAT32 read-only fsck: exit 0

これはホスト側適用合格であり、SDR104での実機起動や長期安定性の合格ではない。
