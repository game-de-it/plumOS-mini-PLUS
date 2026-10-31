# 標準アプリと終了方法

[English](apps.md) | [マニュアル](README.ja.md)

`START → Apps`から開きます。以下が表示されるアプリです。Scraping内部の補助処理を別アプリとして探す必要はありません。

| アプリ | 用途・FEへの戻り方 |
| --- | --- |
| Scraping | アートワーク取得。[取得ガイド](scraping.ja.md)を参照し、戻る・終了操作で戻る |
| File Manager | NextCommanderでファイル操作。Exitを選択 |
| Music Player | 音楽再生。画面の終了・戻る操作で戻る |
| RetroArch | RA設定。Quit RetroArchで終了 |
| Pyxel Setup | Pyxelコンテンツの設定・導入。画面の案内に従い終了 |
| PortMaster | portの導入・管理。Quit/Exitメニューで終了 |
| Update PortMaster | 管理ツールを更新。完了まで待つ |
| Repair SD2 | FAT32 SD2の検査・修復。案内を読み5秒以内に再度Aで実行 |
| Game Gear | 専用カルーセル。SELECTで設定を開きExitを選択 |

Repair SD2はSYSを対象にしません。修復前に重要ファイルをバックアップし、処理を中断しないでください。

PortMasterのゲームはタイトルごとに操作・終了方法が異なります。起動前に各ゲームの説明を確認してください。RAのホットキーは共通ではありません。必要なゲームデータは別途用意します。Apotris互換ガードは記録済みv4.2.0ビルドを検証済みv4.1.0 runtimeで動かす限定対応であり、全port・全版の保証ではありません。

Game Gearでは左右で選択、上下で5件移動、Aで起動、Xでケース表示切替です。カルーセルのB/STARTでは終了しません。SELECT → Exitを使ってください。ゲーム起動後のRA/Picoメニューは[エミュ操作](emulators.ja.md)を参照してください。

インストール・更新中は電源を切らないでください。パッケージ更新では導入済みportと管理情報を保持します。
