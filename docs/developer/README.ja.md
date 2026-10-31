# plumOS mini PLUS 開発者ガイド

[English](README.md) | [利用者マニュアル](../user/README.ja.md)

実装・検証・復旧は進んでいますが、最終配布imageの生成・exact-hash受入・公開は別工程です。[検証ガイド](validation.ja.md)と[TODO](../../TODO.md)で現状を確認してください。

## 項目

- [構成と所有権](architecture.ja.md)
- [ビルドと再現性](build.ja.md)
- [Runtimeと実機配備](runtime.ja.md)
- [FEとエミュレーター](frontend-emulators.ja.md)
- [音声経路](audio-routing.ja.md)
- [ハードウェアサービス](hardware-services.ja.md)
- [ストレージと更新境界](storage-and-updates.ja.md)
- [検証と実装状況](validation.ja.md)
- [アプリ統合](apps.ja.md)
- [libretro coreとcatalog](libretro-cores.ja.md)
- [ネットワークサービス](network-services.ja.md)
- [手動配備と復旧](manual-updates.ja.md)
- [リリース工程](release-process.ja.md)

## 正本・所有境界

- rootfs/mini-plus-frontend/: read-only System overlay
- package/frontend-mini-plus/: FE・launcher・service・初期設定
- configs/input/mini-plus-controller-map.json: 入力map
- package/frontend-mini-plus/plumos/config/frontend/runtime-coverage.json: 経路coverage
- configs/mini-plus-runtime-validation.json: 実機監査台帳
- scripts/: build・検証、tests/: contract test
- docs/validation/: 原証拠、docs/decisions/: 判断の記録

管理Runtimeは/storage/plumos、利用者領域は/storage/userです。管理領域にも利用者設定・save等があるため、directory全体を管理ファイル扱いにしません。メニューキーはSTART右上の丸いキーで、撮影専用FNの位置は未確認です。

共通FE項目・catalogを削除して未実装を隠さず、未対応表示と追跡理由を残します。FEと他rendererの同時描画は禁止し、SIGSTOPだけを画面解放とみなしません。

Bubble参考記録はmini PLUS実機合格へ継承しません。[Bubble原記録](../reference/bubble/validation/2026-09-11-bubble-release-final-device-check.md)とmini PLUSの証拠を区別してください。

[シリーズ移植・問題対策ガイド（日本語原文）](../../plumOS_gitlog_problem_solution_guide.ja.md)も実装・切分け前に参照します。権利境界は[第三者NOTICE](../../THIRD_PARTY_NOTICES.md)に従ってください。
