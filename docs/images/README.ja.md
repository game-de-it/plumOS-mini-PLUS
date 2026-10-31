# README画像の由来

[English](README.md)

- gkd-mini-plus.jpg：利用者提供のIMG_4834.jpg。2760×2070。元fileは変更せず、EXIF/XMP・MPF・camera固有APP領域と主画像後の補助画像を除去。表示用ICCは保持。再圧縮していません。
- 主画像のdecoded RGBA SHA-256は元画像・処理後とも6c745c7fdb4cb592dab9bdaa017feb9755d79aa7b2d1497e9c8435284d58f534です。EXIF位置・camera metadataを含まないことを確認しました。
- frontend-text.png、frontend-graphics-list.png、frontend-gallery.png：2026-10-31にmini PLUSの通常FEから撮影したNES一覧のText・Graphic・Gallery。全て640×480です。
- frontend-graphics.png：同日に撮影したmini PLUSのGraphicシステム一覧です。
- 画面例のartwork・ゲームはOS配布物には含みません。
- ggfe.png：従来の参考画像。今回のREADMEのmini PLUS実機画像には使っていません。

撮影はFE自身の入力・撮影機能を使用し、別rendererを起動していません。撮影前のFE設定はbyte単位で復元し、通常画面へ戻しました。秘密情報を含む設定・ログは画像資産に含めていません。
