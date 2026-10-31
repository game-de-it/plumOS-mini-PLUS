# mini PLUS USB-connected sleep

日付: 2026-10-31

## Acceptance before this change

ユーザーは`62fe884`配備後のSleep復帰が正常であると確認した。battery-onlyの表示復帰は合格とする。
USBを接続したままではSleep後すぐ元に戻るとの報告を受け、充電中に調査した。

## Cause proved on the live kernel

USB接続中の`plumos-safe-shutdown --sleep --wakeup-sec 12`はrc=1となり、kernelの
`PM: suspend entry`へ到達しなかった。USB root hubのwakeはdisabledだった。

function_graphで`state_store`だけを追うと次のcall chainを記録した。

```text
state_store
  avrman_rk817_bat_get_charge_state
    rk817_battery_get_property
      power_supply_get_drvdata
```

stock ImageをAArch64 disassembleした結果、`state_store`はhelper呼出し直後に戻り値が非zeroなら
`-EBUSY`を返していた。helperはbattery STATUSが1（Charging）または4（Full）なら1を返す。
この独自gateは通常の`pm_suspend`・device suspend callbackよりも前にある。

## Exact kernel change

`scripts/patch-mini-plus-usb-sleep-kernel.py`はvendor入力と命令contextの両方を検証し、別outputへ保存する。
vendor入力への上書きと既存outputへの上書きを拒否する。

| 項目 | 値 |
|---|---|
| input SHA-256 | `670c32a86cf006a574d5ec498df6c14e3ac61af6ed6b109f458b5711c228da56` |
| output SHA-256 | `c18890e0bc6c439095f5a0f97d0d643ee3019cad94eaed8a459c3dc015f48653` |
| size | 20,039,688 bytes（変化なし） |
| file offset | `0x8bd40` |
| original | `c0030035` / `CBNZ w0, return_ebusy` |
| replacement | `1f2003d5` / `NOP` |

変更はこの4 byteのみで、charger設定、充電保護、RTC/power key、通常suspend callbackは維持する。
host検証では前後領域のbyte一致、異なるkernel、欠損kernel、二重patch入力の拒否を確認した。

## Deployment and RTC test

元の`/flash/Image`は保持し、追加の`/flash/Image-usb-sleep`へ候補を配置した。
`uEnv.txt`の`kernelimg`だけを候補へ向け、write/readback hashを検証して`/flash`をread-onlyへ戻した。
ユーザーがゲームを終了した後に通常のsafe-shutdown rebootを実施した。

- old boot ID: `987babe3-55c5-4c5a-aac3-07dc9d98c1c8`
- new boot ID: `c8d89e5a-1a64-4563-9964-d409f3f0683f`
- before sleep: `bq2589x-usb/online=1`, battery STATUS=Charging
- `01:35:20Z`: wakealarm=12 seconds、suspend entry
- `01:35:32Z`: suspend resume、rc=0
- IRQ 64 (`RTC alarm`) count=1、power-key IRQ counts=0
- resume parent IRQ=58 (`rk817`)、Wi-Fi/SSHと同じFE PID 378へ復帰

kernel timestampはdeep sleep中の時間を含まないため、滞在時間は上記RTC wall clockで確認した。

復帰後のBQ25890 REG0Bは`0x5e`で、USB DCP input、power-good、charge-doneを示した。
REG03は`0x1a`（charging enable=1）、fault REG0Cは0だった。VBUS ADCは約4.8V。
stock `bq2589x_usb_get_property(ONLINE)`はREG0Bのcharge-stateが1/2のときだけ1を返し、
charge-done=3では0となることをdisassembleで確認した。満充電時のONLINE=0をUSB切断とは扱わない。

## Rollback and remaining gate

変更前`Image`と`uEnv.txt`は次へ保存した。

```text
/storage/plumos/state/kernel-deploy/usb-sleep-20261031/
```

`uEnv.txt`の`kernelimg=Image`へ戻せば元kernelを使用する。候補はapp-layer外の追加boot fileなので、
既存app-layer component/hashを変更していない。

ユーザーによるUSB接続中のnormal power menu→電源キー復帰、ゲーム表示・操作・音声は再試験待ち。
通常image builderへの候補kernel統合も未完了であり、既存生成imageへ変更が遡及したとは扱わない。
