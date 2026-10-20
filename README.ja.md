<p align="center">
  <img src="package/frontend-mini-plus/plumos/config/frontend/boot-splash.png" alt="plumOS" width="640">
</p>

# plumOS mini PLUS

GKD mini PLUS（RK3566 / ARM64）向けに、plumOS-Bubbleのユーザーランド資産を移植する作業ツリーです。

現在の成果物は**ホスト検証済み・実機未検証のbring-up候補**です。stockOS SDから読み取ったmini-PLUS固有のRockchipブート先頭領域、kernel、DTB、overlayを使用し、mini-PLUS専用の外部initramfsからplumOS SYSTEMを起動します。元のstockOS SDには書き込んでいません。

最小ブート候補に加え、Bubble由来のフロントエンド、日本語フォント、テーマ、設定、補助ツールをp2へ収録したUI確認用候補も生成できます。後者はエミュレータruntimeをまだ収録していないため、完成版ではありません。

## 現在の構成

- p1（FAT32、512 MiB）: stock kernel、`rk3566-gkdmini-pro.dtb`、overlay、plumOS initramfs、SquashFS SYSTEM
- p2（ext4、2 GiB）: 設定、ログ、ユーザーデータ
- stock p2の既存データ: plumOS候補へコピーしない
- Wi‑Fi: stock `SYSTEM`内のRTL8821CS moduleと実行kernelのvermagic不一致があるため、現候補では無効

## ビルド

SDイメージ候補を再生成します。

```sh
./scripts/build-mini-plus-image.sh
```

成果物:

```text
output/image/mini-plus/plumOS-mini-PLUS-0.1.0-dev-host-candidate.img
```

UI確認用候補を再生成します。

```sh
./scripts/build-mini-plus-frontend-image.sh
```

成果物:

```text
output/image/mini-plus-frontend/plumOS-mini-PLUS-0.1.0-dev-frontend-host-candidate.img
```

ブート資産はGit管理外の`artifacts/vendor/mini-plus-stock-source/`に置き、各ファイルを固定ハッシュで検証します。stock `SYSTEM`本体は解析専用で、生成イメージへコピーしません。

## 重要な状態表示

ホスト側では、両候補のイメージ全体SHA-256、MBRレイアウト、FAT/ext4、raw boot prefix、kernel/DTB/overlayを検証済みです。UI候補ではフロントエンドcomponentの全ファイルもチェックサム検証済みです。LCD、入力、音声、shutdown、suspend、実機Wi‑Fiは未確認です。空のテスト用SDへ書き込み、実機で確認するまではリリース扱いにしません。

- [作業状況](TODO.md)
- [stockOS読み取り記録](docs/validation/2026-10-20-mini-plus-read-only-inventory.md)
- [ホスト候補ビルド記録](docs/validation/2026-10-20-mini-plus-host-candidate.md)
- [Bubble由来の参考検証](docs/reference/bubble/validation/)

## ライセンス

plumOS独自部分には[MIT License](LICENSE)が適用されます。GKD stockOS由来のboot/runtimeファイルや第三者componentはMITには含まれず、各権利者の条件が継続します。

- [第三者表記](THIRD_PARTY_NOTICES.md)
- [GKD stockOS permission notice](docs/licenses/GKD-stockOS-PERMISSION-NOTICE.txt)
- [mini PLUS vendor runtime notice](docs/licenses/mini-plus-vendor-runtime-NOTICE.txt)
