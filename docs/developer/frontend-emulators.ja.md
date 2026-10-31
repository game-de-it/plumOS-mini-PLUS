# FEとエミュレーター

[English](frontend-emulators.md) | [開発者ガイド](README.ja.md)

catalogはpackage/frontend-mini-plus/plumos/config/frontend/systems.json、経路台帳はruntime-coverage.jsonです。共通メニュー・system・core・launch profileを保持し、未実装機能は未対応表示と追跡理由を残します。無言で削除しません。

起動はFEの正規経路を使います。次のrendererを起動する前に画面所有を解放し、子process終了後にFEへ一度だけ戻します。SIGSTOPだけでは/dev/fb0や/dev/dri/card*を解放しません。同時描画は点滅や残像の原因です。

release gateは「全package coreから導線または明示的未対応へ」「全公開導線から実在launcher/coreへ」の双方向を確認します。

```sh
sh tests/test-mini-plus-runtime-coverage.sh
python3 scripts/summarize-mini-plus-runtime-validation.py --verify
```

Text/GraphicがUI Mode、GalleryはXで入ります。GGFEは別アプリです。メニュー・終了方法は[利用者操作](../user/emulators.ja.md)、未試験経路は[検証制限](../validation/2026-10-31-mini-plus-runtime-limitations.ja.md)を参照してください。
