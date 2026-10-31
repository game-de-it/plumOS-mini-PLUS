# 音声経路

[English](audio-routing.md) | [開発者ガイド](README.ja.md)

mini PLUSはstock互換のRK817 ALSA経路を使います。package/frontend-mini-plus/plumos/bin/のplumos-mini-plus-audio-init・plumos-audio-outputが経路を初期化し、SPK_HP補正とruntime別初期化を含みます。

/proc/asound/cardsと/proc/asound/card*/pcm*/sub*/statusでdevice・PCMの証拠を確認します。PCM進行だけでは可聴音を証明できません。speaker・headphone、抜差し、左右、音量・mute、終了再起動、Sleep復帰を別々に確認してください。

RetroArch・PicoArch・単体・PortMasterごとの確認が必要です。Apotrisの互換修正は識別済みbuildへの限定対応です。[実機記録](../validation/2026-10-21-mini-plus-apotris-portmaster.md)を参照し、1本のport修正でSDL/ALSAを全体置換しないでください。

音が継続して画面が黒い場合は表示復帰も調べます。音声継続だけでは復帰合格ではありません。
