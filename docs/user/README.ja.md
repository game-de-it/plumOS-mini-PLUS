# plumOS mini PLUS 取扱説明書

[English](README.md) | [トップページ](../../README.ja.md)

検証制限を明記して公開したv0.1.0向けガイドです。実機確認済みの操作と、最終配布イメージの受入は区別しています。[現在の状態](../../README.ja.md#現在の状態)を確認してください。

## 最初に覚える位置

| 名称 | 位置・用途 |
| --- | --- |
| SYSスロット（SD1） | 本体上部。起動用SD |
| SD2スロット | 本体下部。任意のROM／BIOS用SD |
| メニューキー（内部名F1） | **STARTの右上の丸いキー**。RA/Pico/対応単体エミュのメニュー。FEではスクリーンショット |

FNキーは4個あります。F1/F2という内部名を、写真の左右順や肩ボタン名と混同しないでください。位置未確認のスクショ用FNには頼らず、RetroArchではメニューから撮影できます。

> SD2は電源を切ってから抜き差ししてください。電源中のhot plugは対応外です。

## 目的別ガイド

1. [SDカードへの書き込みと初回起動](install.ja.md)
2. [基本操作・3つの表示・電源・スリープ](operation.ja.md)
3. [SD1 / SD2の使い分け](storage.ja.md)
4. [対応システム・ROMフォルダ・拡張子・core一覧](supported-systems.ja.md)
5. **[エミュレーターの終了・メニュー・ホットキー早見表](emulators.ja.md)**
6. [アプリの入口と終了方法](apps.ja.md)
7. [BIOS・セーブ・ステート・スクリーンショット](save-data.ja.md)
8. [画像スクレイピング](scraping.ja.md)
9. [Wi-Fi・SFTP等の有効化と転送先](network.ja.md)
10. [Runtime / System更新](updates.ja.md)
11. [困ったとき](troubleshooting.ja.md)

## 最短のゲーム起動

SD1へOSを書き、初回の領域作成を待ちます。ROMを`Roms/<system>/`へ追加し、FEでシステム → ゲーム → `A`。SD2を使う場合はそのルートの`roms/<system>/`と`bios/`が優先されます。追加後は一覧を更新するか、システムへ入り直します。

RAとPICO等の選択は`SELECT`から行えます。システム一覧での選択はシステムの既定、ゲーム一覧での選択はそのゲーム向けです。終了方法は[早見表](emulators.ja.md)で確認してください。

## 言語と制限

工場設定のUIは英語です。`START → System Settings → Language`から日本語を選べます。アナログスティックはありません。USBデータ転送・ADB・HDMIは未対応です。3DS/Java ME等は[対応表](supported-systems.ja.md)の状態を確認してください。

ROM、利用者BIOS、商用ゲームは同梱しません。[既知の検証制限](../validation/2026-10-31-mini-plus-runtime-limitations.ja.md)も参照してください。
