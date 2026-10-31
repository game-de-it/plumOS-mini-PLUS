# 検証と実装状況

[English](validation.md) | [開発者ガイド](README.ja.md)

完了判定前にTODO.mdと[実装チェックリスト](../plumos-implementation-checklist.ja.md)を読みます。新SD通常起動・初回進捗・入力/音声・SD1/SD2プレイ・輝度・USBあり/なしSleep・Wi-Fi再接続は利用者確認済みです。RuntimeとSystem A/B復旧には実機試験証拠があります。

[リリース前作業記録](../validation/2026-10-31-mini-plus-pre-release-work.md)は日本語の原記録です。[runtime制限](../validation/2026-10-31-mini-plus-runtime-limitations.ja.md)に起動受入未完了の26経路を残します。機械起動170・PCM進行166を全ゲームの表示・可聴音合格とは扱いません。

```sh
python3 tests/test-mini-plus-documentation.py
python3 tests/test-mini-plus-supported-systems-doc.py
sh tests/test-mini-plus-runtime-coverage.sh
sh tests/test-mini-plus-release-content-audit.sh
```

安全な実機試験には[FE lifecycle](frontend-emulators.ja.md)を使います。image hash・経路/core・content識別・映像・可聴音・入力・保存読込・終了を個別に記録します。docs/reference/bubble/は参考でありmini PLUS合格ではありません。最終imageの受入は未完了です。[リリース工程](release-process.ja.md)を参照してください。
