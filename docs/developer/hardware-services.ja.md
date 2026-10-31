# ハードウェアサービス

[English](hardware-services.md) | [開発者ガイド](README.ja.md)

入力の正本はconfigs/input/mini-plus-controller-map.jsonです。スティックなし、FN4個です。driverのABS/L3/R3は互換aliasとして残します。メニューはSTARTの右上の丸いキーで、撮影専用FNの物理位置は未確認です。

音量キーserviceがSELECT＋音量による20段階輝度を担当します。mini PLUS実測のPWMカーブが必要で、Bubbleのカーブでは1〜12段階がほぼ変化しませんでした。音量単独と長押しの動作を保持します。

電源操作はゲーム・writerを止めてから再起動・終了します。Sleep復帰では音・入力だけでなく表示も復旧します。USB接続Sleepにはstock kernelの限定patchを使い、元Imageを保持します。SDR104は検証済みoverlayで、試験カードでは148.5MHzでした。

[USB Sleep記録](../validation/2026-10-31-mini-plus-usb-sleep.md)を参照してください。USBあり・なし、speaker・headphone、renderer、入力の合格は別々です。蓋閉じ機構はなく、USBは充電専用、ADB/HDMIは未対応です。
