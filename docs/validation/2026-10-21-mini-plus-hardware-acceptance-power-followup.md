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

これにより自動経路のFE再表示競合は解消した。ゲーム画面からのRebootとShutdownは別々に物理再試験する。

## Suspendの未解決境界

`/sys/power/state`は`freeze mem`、`/sys/power/mem_sleep`は
`s2idle [deep] lite ultra`を公開する。一方で、Wi-Fi停止とdriver settle、RTC wakealarm、
`wakeup_count` handshakeを行っても`freeze`と`mem`のwriteは即座にEBUSYとなる。
fresh reboot直後にも再現し、suspend statisticsはentry前のまま0だった。stock由来のlive kernel `Image`と
`/proc/config.gz`は保存済みstock artifactとSHA-256一致している。

診断時はbattery statusが`Charging`を返していた。mini PLUS固有kernelの給電中gateか、stock userspaceが行う
未採取のpre-suspend操作かを分離するため、次はUSB給電を外したbattery-only状態で同じnormal power menuを試す。
これは`MPLUS-HW-05`未合格のまま維持する。

## Rollback

実機の変更前ファイルは次へ保存した。

```text
/storage/plumos/state/app-deploy/4b5b8cd-power-transition/rollback/
```
