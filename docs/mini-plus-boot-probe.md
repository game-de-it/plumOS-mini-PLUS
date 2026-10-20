# mini PLUS boot probe

実機未検証のhost candidateを、新しいテスト用SDで段階確認するためのstage契約です。stockOS SDでは実行しません。

## Build

```sh
./scripts/build-mini-plus-image.sh
```

生成物は`output/image/mini-plus/plumOS-mini-PLUS-0.1.0-dev-host-candidate.img`です。raw prefix、kernel、DTB、overlay、FAT/ext4と全体SHA-256はbuild時に検証します。

## U-Boot stages

| Stage | Meaning |
| --- | --- |
| `S10` | instrumented `boot.scr`へ入った |
| `S11` | `uEnv.txt`をimportした |
| `S12` / `E12` | plumOS external initramfsのload成功 / 失敗 |
| `S13` / `E13` | stock kernelのload成功 / 失敗 |
| `S14` / `E14` | `rk3566-gkdmini-pro.dtb`のload成功 / 失敗 |
| `S15` | overlay/fixup処理後、handoff直前へ到達 |
| `S19` | `booti`呼出し直前 |
| `E20` | `booti`が戻ったためkernel handoff失敗 |

U-Boot stageはUART consoleへだけ出力します。U-BootからFATへ書きません。

## plumOS initramfs stages

| Stage | Meaning |
| --- | --- |
| `S21` | plumOS external initramfsへ到達 |
| `S22` / `E22` | marker付きp1と同じSDのp2を解決 / media identity失敗 |
| `S23` / `E23` | p1 `SYSTEM`のSHA-256確認 / 欠落または不一致 |
| `S24` / `E24` | SquashFS SYSTEMをread-only loop mount / mountまたはcontract失敗 |
| `S25` / `E25` | p2を`/storage`へread-write mount / mount失敗 |
| `S26` / `E26` | p1、proc、sys、run、tmp、devを移動してswitch-root / handoff失敗 |

失敗時はserial console上のBusyBox shellへ落ちます。自動partition拡張、format、repairは行いません。

## SYSTEM stages

| Stage | Meaning |
| --- | --- |
| `S30` | plumOS SYSTEM entryへ到達 |
| `S31` / `E31` | `/storage`確認 / 不在 |
| `S32` / `E32` | `/flash`確認 / 不在 |
| `S33` / `E33` | 640x480 framebuffer marker描画 / framebuffer不在 |
| `E34_WIFI_DRIVER_ABI_UNVERIFIED` | RTL8821CS driverを意図的にloadしていない |
| `S39` / `E39` | recovery idleへ到達しstorageをread-only化 / read-only化失敗 |

## Acceptance order

1. stockOS SDを抜いて保管する。
2. host candidateを別の空SDへraw writeし、書き込み後に全体readback hashを確認する。
3. mini PLUSでcold bootし、UARTまたはp1 `plumos-probe/system-stage.txt`を回収する。
4. `S33`まで合格後にcontroller、RK817 audio、shutdown/rebootを確認する。
5. kernel一致のRTL8821CS moduleが得られるまでWi-Fiを有効化しない。
6. 最小SYSTEM合格後にBubble frontend/app layerを追加する。

host buildだけでは物理acceptanceになりません。LCD、入力、音声、電源、SD readbackの記録がそろうまで`publishable=no`を維持します。
