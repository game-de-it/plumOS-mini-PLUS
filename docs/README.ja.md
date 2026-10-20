# plumOS mini PLUS ドキュメント

> Bubble互換full-stack imageはhost統合検証とarchive検証まで合格しました。実機ではfrontend到達と基本controller操作だけが確認済みで、full-stackのhardware／Wi-Fi acceptanceは未完了です。現在の確認済み範囲は[ルートREADME](../README.ja.md)を参照してください。

文書は利用対象ごとに分けています。日本語版は`.ja.md`、英語版は`.md`です。

## 利用者向け

[ユーザー向け取扱説明書](user/README.ja.md)には、SDカードへの書き込み、基本操作、
ROM・BIOS、エミュレータ、ホットキー、セーブ、スクレイピング、ネットワーク、
更新、トラブル対応を記載します。Linuxや開発環境の知識は必要ありません。

- [対応システム・ROMフォルダ・拡張子・エミュレータ一覧](user/supported-systems.ja.md)
- [エミュレータとゲーム中の操作](user/emulators.ja.md)

## 開発者向け

[開発者向けガイド](developer/README.ja.md)には、boot/storage ownership、再現build、
System/app-layer、frontend・emulator起動経路、hardware service、update、release検査、
実機validation記録への入口をまとめています。

- [plumOS実装チェックリスト](plumos-implementation-checklist.ja.md)
- [mini PLUS conformance監査（2026-10-20）](validation/2026-10-20-mini-plus-plumos-conformance-audit.md)
- [Bubble contract修正後host候補（2026-10-20）](validation/2026-10-20-mini-plus-bubble-contract-host-candidate.md)

## 法的文書

- [MIT License](../LICENSE)
- [第三者表記](../THIRD_PARTY_NOTICES.md)
- [GKD stockOS permission notice](licenses/GKD-stockOS-PERMISSION-NOTICE.txt)

## English

- [English documentation index](README.md)
