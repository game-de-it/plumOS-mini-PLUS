# SD1・SD2の使い方

[English](storage.md) | [マニュアル](README.ja.md)

**本体上部SYSスロット**のSD1にはboot/System・Linux本体管理領域・PCから見えるPLUMOS FAT32利用者領域があります。bootや本体管理領域をフォーマットしないでください。

| SD1のPLUMOS内フォルダー | 用途 |
| --- | --- |
| Roms/<system>/ | SD2なしのROM |
| BIOS/ | SD2なしのBIOS |
| Images/ | RetroArchの撮影画像など |
| Screenshots/ | FEの撮影画像 |
| updates/ | 署名付き更新パッケージ |

SD2は**本体下部SD2スロット**の任意のFAT32カードです。Bubbleに合わせルートに`roms/<system>/`と`bios/`を作ります。Roms/ROMSやBIOS/Biosも認識しますが、大文字小文字だけ違う重複を避けてください。

SD2装着時はSD2のROM・BIOSを優先し、未装着時はSD1を使います。セーブ・設定・ログ・スクリーンショットはSD1に残ります。本体の`/storage/Roms`・`/storage/BIOS`は有効なカードを参照し、`/storage/user/Roms`・`/storage/user/BIOS`は明示的にSD1を参照します。

`/storage/plumos/saves`・`states`・`config`・`logs`等はPLUMOSとは別の本体管理領域です。[ネットワーク転送](network.ja.md)でバックアップしてください。PCから見えるFAT領域だけをコピーしてもセーブのバックアップにはなりません。

SD2は電源OFFで着脱してください。hot plugは対応外です。SYSも終了完了・画面とLEDの消灯後に抜いてください。FAT32 SD2の不調時は[Repair SD2](apps.ja.md)を参照してください。
