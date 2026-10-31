# ビルドと再現性

[English](build.md) | [開発者ガイド](README.ja.md)

repositoryルートで、設定済みcontainer toolchainとhash確認済みstock boot/GPU/firmware入力を使います。必要入力はbuild scriptが検証します。不足を他機種のbinaryで埋めないでください。

```sh
./scripts/build-mini-plus-full-image.sh
sh scripts/verify-mini-plus-frontend-probe-image.sh output/image/mini-plus-frontend-probe/<image>.img
```

full-image wrapperはfrontend-probe builderへ委譲し、System・initramfs・Runtime・実測seedを組み立てます。--assemble-onlyはcache再利用であり、sourceからの新規buildの証拠ではありません。seedは管理payloadと余裕を含む約2.90GBで、固定4GB root partitionではありません。

commit・dirty状態・version・toolchain・外部入力hash・出力SHA-256を記録します。componentの前提はscripts/build-mini-plus-{frontend-system,external-initramfs,app-layer,frontend-probe-image}.shを参照してください。圧縮と昇格は別の[リリース工程](release-process.ja.md)です。

full-image wrapperはVERSIONの0.1.0を子buildへexportします。明示的なPLUMOS_MINI_PLUS_VERSIONを優先し、component直接起動の開発用defaultは保持します。正式配布名はBubble形式のplumos-mini-plus-v0.1.0-sd-image.img／.7zです。旧dev imageの名前だけを0.1.0へ変更しません。
