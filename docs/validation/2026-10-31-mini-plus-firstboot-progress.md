# 新規SDの初回進捗画面

## 報告と採取結果

ユーザーは`0.1.0-dev-20261031`を新規SDで起動したが、領域拡張などの
初回進捗画面が表示されなかったと報告した。対話式設定wizardを指すものではない。
`192.168.10.141`から採取したfirst-boot.logでは、seedのp3を8 GiBへ拡張、
ext4拡張、p4 FAT32作成、userdata契約作成、System A/B検証、switch_rootまで成功した。
したがって初期化未実行ではなく表示の不具合として追跡する。

kernel時刻ではstorage mutationが1.678〜3.853秒、約2.2秒で完了した。
p1実物のinitramfsを展開し、全progress stripの存在と開始画像のhost一致を確認した。
旧実装は144行のfooterだけをfb0へseekして書き込み、失敗を捨てていた。
同じ書込みは起動後の独占previewで成功したため、初回の非表示原因を断定する証拠はない。

## 修正候補

- external initramfsだけの全画面640×480 XRGB8888進捗へ変更する。
- 初回だけ開始とstorage完了100%を各2秒表示する。通常bootには待機を追加しない。
- 共通helperが画像size、device種別、書込み結果を検証し、stdoutとkmsgへphase/resultを記録する。
  provisionerのstdoutは既存経路でfirst-boot.logへ保存される。
- 表示失敗でpartition初期化を止めない。完了markerの削除や既存partitionの再初期化は行わない。

## 検証

- first-boot storage中断・再開fixture合格。
- progress helperの正常出力、欠損/旧footer画像、device不在、write失敗、不正phase拒否fixture合格。
- 新規SD上のFEを完全終了し、全display fd解放を確認後、開始と完了の全画面を順に表示。
  fb0から各1,228,800 bytesをreadbackし、入力画像と完全一致した。
  active DRM planeはfbconのXR24、640×480、pitch 2560、CRTC activeであった。
  終了時にvalidation holdを解除し通常FEへ戻した。

採取先: `artifacts/device-validation/2026-10-31-firstboot-progress/`。
このpreviewは起動後の表示経路の機械確認であり、初期userspaceでの物理表示合格とは区別する。
修正候補の新規SD書込み後、初回の開始・工程・100%画面と2回目の通常起動を目視確認するまで
`MPLUS-BOOT-UI-01`を未完了とする。
