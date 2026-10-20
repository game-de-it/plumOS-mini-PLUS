<p align="center">
  <img src="package/frontend-mini-plus/plumos/config/frontend/boot-splash.png" alt="plumOS" width="640">
</p>

# plumOS mini PLUS

GKD mini PLUS（RK3566 / ARM64）向けに、plumOS-Bubbleのユーザーランド資産を移植する作業ツリーです。

現在の成果物は**ホスト検証済み・公開不可のfull-stack実機検証候補**です。stockOS SDから読み取ったmini-PLUS固有のRockchipブート先頭領域、kernel、DTB、overlayへ、Bubbleで成立したstorage／update contractを移植しています。元のstockOS SDには書き込んでいません。

Bubble由来frontend、114個のlibretro core、RetroArch、PicoArch、単体emulator、Pyxel、PortMaster、NextCommander、Music Player、network serviceを統合しています。以前のUI確認用imageでは実機frontend到達と基本controller操作を確認済みですが、修正版full-stack image自体は実機未検証です。

## 現在の構成

- 先頭16 MiB: hash固定したmini PLUS用Rockchip boot prefix
- p1（FAT32、512 MiB）: vendor kernel、mini PLUS DTB/overlay、plumOS initramfs、read-only SquashFS System A/B
- p2（raw、64 MiB）: immutable matching boot bundle
- p3（ext4、2,176 MiB）: app payload実測値+256 MiBの余裕から算出したmanaged Runtime/state seed
- 初回起動: 中断再開可能な手順でp3を8 GiBへ拡張し、残領域へp4 `PLUMOS`を作成。最小カード容量14 GiB
- stock p2の既存データ: plumOS候補へコピーしない
- Wi‑Fi: stock RTL8821CS moduleはkernel ABI不一致。明示許可した強制load経路はdebug実験で、release合格条件ではない

## ビルド

canonical full-stack imageを再生成します。

```sh
./scripts/build-mini-plus-full-image.sh
```

成果物:

```text
output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.img
```

実機検証用7zを作成し、archive testと展開後raw hash一致を確認します。

```sh
./scripts/prepare-mini-plus-validation-archive.sh
```

成果物:

```text
output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.7z
```

ブート資産はGit管理外の`artifacts/vendor/mini-plus-stock-source/`に置き、各ファイルを固定ハッシュで検証します。stock `SYSTEM`本体は解析専用で、生成イメージへコピーしません。現在のrawは2,902,458,368 bytes、検証済み7zは481,027,169 bytesです。

## 重要な状態表示

ホスト側では、image/partition checksum、MBR、FAT/ext4、raw boot prefix、kernel/DTB/overlay、System A/B、matching p2、first-boot transaction、app-layer全ファイル、114 coreを検証済みです。full-stack imageでのLCD、全入力、音声、shutdown、suspend、Wi‑Fi/SSH、SD readbackは未確認です。空のテスト用SDへ書き込み、実機で確認するまではrelease扱いにしません。

- [作業状況](TODO.md)
- [stockOS読み取り記録](docs/validation/2026-10-20-mini-plus-read-only-inventory.md)
- [ホスト候補ビルド記録](docs/validation/2026-10-20-mini-plus-host-candidate.md)
- [frontend実機確認記録](docs/validation/2026-10-20-mini-plus-frontend-user-acceptance.md)
- [Bubble contract修正後host候補とチェック表](docs/validation/2026-10-20-mini-plus-bubble-contract-host-candidate.md)
- [Bubble由来の参考検証](docs/reference/bubble/validation/)

## ライセンス

plumOS独自部分には[MIT License](LICENSE)が適用されます。GKD stockOS由来のboot/runtimeファイルや第三者componentはMITには含まれず、各権利者の条件が継続します。

- [第三者表記](THIRD_PARTY_NOTICES.md)
- [GKD stockOS permission notice](docs/licenses/GKD-stockOS-PERMISSION-NOTICE.txt)
- [mini PLUS vendor runtime notice](docs/licenses/mini-plus-vendor-runtime-NOTICE.txt)
