# mini PLUS hardware acceptance and power follow-up

日付: 2026-10-21

## ユーザー実機acceptance

ユーザーの物理操作により、次を合格とした。

- mini PLUSにはanalog stickが存在しない。実在する全入力は正常。
- Fnキーは4個あり、そのうち1個からRetroArch/PicoArchのメニューを表示できる。
- speaker/headphoneを含む音声は正常。
- 保存済みWi-Fiへの再接続は正常。
- SD整合性とSDR104運用は正常。
- 標準アプリは正常。
- 全emulator routeの物理試験は未完了だが、これまで実行したゲームでは不具合を確認していない。

最後の項目は代表実機acceptanceであり、ROM2の不足contentを含む全route合格へ読み替えない。

## ゲーム中のterminal power競合

ゲーム中にRebootまたはShutdownを選ぶと、ゲーム終了後に操作可能なfrontendが再表示され、
約8秒後に遅延finalizerが電源動作を行っていた。ログではforeground終了からpower request確定までの間に
PID 1がfrontendを再起動していた。

source `4b5b8cd`では次の順序へ変更した。

1. `/run/plumos/power-action/in-progress`をatomicに確定する。
2. supervised frontendを終了する。
3. game/app process groupとdisplay ownerをbounded terminationする。
4. storageを安全に停止し、reboot/shutdown requestを確定する。
5. PID 1が起動したreplacement launcherはDRM/inputを開かず待機し、request確定後ただちにPID 1へ戻る。
6. fallible処理が失敗した場合だけmarkerを除去し、通常frontendを復帰する。

ホスト試験はpower menu、sleep、START menu、power finalizer、managed volume、physical input contractが合格した。
実機へは2 script、frontend manifest/checksumおよび対応するglobal checksum entryだけを配備した。
frontend componentは227/227、変更したglobal entryは4/4一致した。

診断rebootではboot IDが
`ad3ffdee-927d-4a20-abcd-cc36fb5f906f`から
`6996bde0-4407-402d-a9ac-c38ee069af4b`へ変わり、次を記録した。

```text
frontend_power_transition=wait marker=/run/plumos/power-action/in-progress
frontend_power_transition=handoff action=reboot owner=pid1
```

これにより自動経路のFE再表示競合は解消した。2026-10-31、ユーザーはゲーム画面からの
RebootとShutdownを別々に物理確認し、どちらも正常と判定した。

## Suspendの未解決境界

`/sys/power/state`は`freeze mem`、`/sys/power/mem_sleep`は
`s2idle [deep] lite ultra`を公開する。一方で、Wi-Fi停止とdriver settle、RTC wakealarm、
`wakeup_count` handshakeを行っても`freeze`と`mem`のwriteは即座にEBUSYとなる。
fresh reboot直後にも再現し、suspend statisticsはentry前のまま0だった。stock由来のlive kernel `Image`と
`/proc/config.gz`は保存済みstock artifactとSHA-256一致している。

診断時はbattery statusが`Charging`を返していた。2026-10-31、USB給電を外したbattery-only状態では
deep suspendへ入り、power keyで復帰した。音声とゲームprocessは継続したが、画面は黒いままだった。

直後の実機証拠は次の通り。

- `power-action.log`: `stage=suspend-enter`から`stage=suspend-resume`へ到達し、`result=resumed`。
- kernel: `vop2_crtc_atomic_disable`後に640x480p60で`vop2_crtc_atomic_enable`、DSI encoder enable、
  `PM: suspend exit`まで正常。
- backlightはraw/actualとも52、DSI connectorは`enabled`、DPMSは`On`。
- read-only DRM probeではCRTC 71とprimary plane 57/fb 158だけがactiveで、ゲームに使われていた
  overlay plane 105は`crtc_id=0 fb_id=0`だった。
- power overlay logはSleep直前に`plane=105 action=disable fb=162 result=ok`、
  overlay終了時に`action=restore ... result=failed`を記録した。

kernel/panel/backlightではなく、overlay processの別DRM fdからゲームprocess所有framebufferを戻せないことが
黒画面の原因だった。source `62fe884`では、SCM_RIGHTSで保持しているゲーム自身のDRM open file descriptionに
次を追加した。

1. runtime停止後、overlayを開く前にCRTC/mode/connector、DPMSおよび全active planeの8 geometry propertyを保存する。
2. Sleep復帰後に同じDRM fdでmasterを再取得する。
3. CRTC/DPMSと全planeを完全復元してからゲームへ`SIGCONT`を送る。

power menu、sleep、power finalizer、shell syntaxおよび`-Werror` AArch64 buildは合格した。実機へは
`plumos-drm-broker-run`、`plumos-drm-master`、`plumos-runtime-quiesce`、frontend manifest/checksumを
atomic配備した。frontend componentは227/227、変更したglobal entryは5/5一致した。

live global checksumの全件検証では、配備前rollback版の時点から空白を含む5,224 pathが第1語へ
切り詰められている既存metadata不良を確認した。今回の5 entry以外は変更せず、利用者のPortMaster更新物を
新baselineへ取り込まない。clean app-layer再生成での是正を`MPLUS-META-01`へ分離する。

新しいbrokerは次のゲーム起動から有効になる。新規ゲームprocessでSleep復帰後の表示・操作・音声を
物理確認するまで`MPLUS-HW-05`は未合格のままとする。

## Rollback

実機の変更前ファイルは次へ保存した。

```text
/storage/plumos/state/app-deploy/4b5b8cd-power-transition/rollback/
/storage/plumos/state/app-deploy/62fe884-sleep-display/rollback/
```
