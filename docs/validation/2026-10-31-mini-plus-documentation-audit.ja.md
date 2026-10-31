# mini PLUS ドキュメント項目監査（2026-10-31）

[English](2026-10-31-mini-plus-documentation-audit.md)

Bubble・MF・Pixel2・RK2020のdocs/userとdocs/developerを読み取り比較しました。単に同名fileを作るのではなく、mini PLUSに適用される操作・所有境界・終了方法・検証を対応付けています。

A30・MMF・XU20V32・V90Sのuser/developer項目一覧も照合しました。共通の利用者項目と構成・build・Runtime・storage・validationを下表で網羅します。A30のfeature-index・portingは実装チェックリストとシリーズ移植・問題対策ガイドへ対応付けます。MMF固有のHAL・SDL・Onion・描画研究は機種固有の参考資料とし、mini PLUS操作として転記しません。RK2020のstorage-and-reimagingはinstall・storage・updatesで扱います。

| 比較対象の項目 | mini PLUSでの掲載先（全て日英対） |
| --- | --- |
| 利用者：導入・操作・SD | user/install · operation · storage |
| 対応機種・エミュ・保存/ホットキー | user/supported-systems · emulators · save-data |
| 画像取得・network・更新・困ったとき | user/scraping · network · updates · troubleshooting |
| アプリと終了方法 | user/apps |
| 構成・build・Runtime | developer/architecture · build · runtime |
| FE・core・音声・hardware | developer/frontend-emulators · libretro-cores · audio-routing · hardware-services |
| storage/更新・network・手動配備 | developer/storage-and-updates · network-services · manual-updates |
| アプリ・検証・release・実装状況 | developer/apps · validation · release-process; implementation checklist |

Bubble/MF共通の利用者10ガイドに加え、アプリの終了案内を独立させました。MFの開発者topicを揃え、Pixel2のimplementation-statusとfrontend-feature-auditはvalidation・frontend-emulators・実装チェックリストに対応付けました。Pixel2のsave/hotkey独立ガイドの内容はemulators・save-dataへ集約しています。

## 修正した不一致

- 実機未確認という古い状態、System A/B未実装という旧制限を更新。
- FNメニュー位置は利用者確認済みのSTART右上の丸いキー。撮影FN位置は未確認とし、RA Quick Menu → Take Screenshotを案内。
- RA終了の二度押し確認、Pico/単体/portの個別終了、GGFEのSELECT → Exitを明記。
- SSHとSFTPの別スイッチ、共有ルート/storage、SD2優先とSD1明示パスを記載。
- FEのScreenshots/とRAのImages/を区別。セーブはPCから見えるFATだけではbackupできないことを追記。
- READMEの旧Bubble画像をmini PLUS実機のText/Graphic/Galleryへ交換。本体写真のmetadataを除去。
- developer indexの古いinput/coverage path、存在しない.py verifier、旧/mnt/plumos表記を修正。

## 適用範囲と検証

蓋閉じSleep・ADB等の他機種固有機能をmini PLUSへあるものとして案内しません。共通FE項目・catalogは変更していません。原実験log・Bubble参考記録・第三者NOTICEは原資料の言語を保ち、現行user/developer guideと現状・制限説明を日英で提供します。

画像の[由来・metadata処理](../images/README.ja.md)、自動checkのtests/test-mini-plus-documentation.pyを参照してください。今回の変更はドキュメントと画像・検証であり、新release imageの生成・公開ではありません。

合格したcheck：日英対・Markdown/HTML内部リンク・画像寸法/JPEG metadata、対応表生成、物理入力contract、runtime台帳（196経路・機械起動170・未検証26）、git diff空白検査。ImageMagickで写真に残るprofileがICCだけであることと、主画像のdecoded pixel SHA-256が元画像と一致することも確認しました。これらは文書の検証であり、新たなゲーム・hardware合格ではありません。
