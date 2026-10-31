# libretro coreとcatalog

[English](libretro-cores.md) | [開発者ガイド](README.ja.md)

package済みlibretro coreは114です。catalogの97 entry・196経路と、自動生成する利用者表の対応88 systemは集計範囲が異なり、数の差をpackage欠落とは解釈しません。

package/frontend-mini-plus/plumos/config/frontend/systems.json・runtime-coverage.json・configs/mini-plus-runtime-validation.jsonを整合させます。catalog変更後は利用者表を再生成します。

```sh
python3 scripts/generate-mini-plus-supported-systems-doc.py
python3 scripts/generate-mini-plus-supported-systems-doc.py --check
python3 scripts/summarize-mini-plus-runtime-validation.py --verify
```

package coreでもBIOS・content形式・別rendererが必要な場合があります。content不足は検証制限であり、そのまま機種未対応ではありません。3DS等の明示的未対応もcatalogから黙って除外しません。[FE経路](frontend-emulators.ja.md)と[制限](../validation/2026-10-31-mini-plus-runtime-limitations.ja.md)を確認してください。
