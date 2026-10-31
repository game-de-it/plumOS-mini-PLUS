# BIOS・セーブ・スクリーンショット

[English](save-data.md) | [マニュアル](README.ja.md)

利用権のあるBIOSを有効なカードのBIOS領域へ置きます。SD2装着時は`bios/`、未装着時はSD1の`BIOS/`です。ディスク・コンピューター・アーケード系には特定のBIOSやROMセットが必要な場合があります。拡張子を認識しても動作保証ではありません。

| データ | 本体パス |
| --- | --- |
| RetroArchセーブ / ステート | /storage/plumos/saves/ · /storage/plumos/states/ |
| 設定 / ログ | /storage/plumos/config/ · /storage/plumos/logs/ |
| RetroArch撮影画像 | /storage/Images/ |
| FE撮影画像 | /storage/Screenshots/ |
| 単体エミュ設定 | /storage/plumos/config/standalone/ |
| PPSSPP state領域 | /storage/plumos/state/standalone/ppsspp/ |

撮影画像はFAT利用者領域にあります。セーブ・設定はSD1本体管理領域のため、[SFTP/Samba](network.ja.md)で構造を保ってバックアップしてください。他の単体エミュやportは独自の保存先を持ちます。利用中runtimeとダウンロード済みportのディレクトリも含めて保存してください。

ゲーム内で保存し、正常終了してからコピーします。ステートにはcore・バージョン依存があるため、復元時は同じcore・版を使い、通常のゲーム内セーブも残してください。Gambatteの保存試験合格を全coreの互換性へ一般化しないでください。

Game Gearシェーダーは`/storage/plumos/config/shaders/gamegear-lcd.glslp`です。独自変更はバックアップしてください。メニュー撮影・ステート操作・終了方法は[エミュ操作](emulators.ja.md)にまとめています。
