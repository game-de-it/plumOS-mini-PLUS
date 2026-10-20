# GKD mini PLUS Bubble contract修正後host候補

Date: 2026-10-20

Baseline: `docs/plumos-implementation-checklist.ja.md`

## 結論

4 GiB固定p2のbring-up imageを廃止し、Bubbleで成立したplumOSのstorage、System A/B、
matching boot bundle、初回provisioning、archive検証のcontractをmini PLUS固有boot substrateへ
移植した。新しいraw imageは**2,902,458,368 bytes**、配布形式と同じ7zは
**481,027,169 bytes（459 MiB）**で、500 MB未満になった。

これはhost検証済みのnon-publishable device-validation候補である。full-stack image自体の
実機boot、Wi-Fi、音声、全入力、emulator/app、power、SD readbackはまだ合格していない。
特にRTL8821CS moduleのkernel ABI不一致は未解決なので、plumOS release完成とは判定しない。

## artifact

| 種類 | file | bytes | SHA-256 |
|---|---|---:|---|
| raw | `output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.img` | 2,902,458,368 | `b069c172a02fea985047bef3616abd405f881295e41b5002f4d1c1117190498e` |
| 7z | `output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-full-stack-validation.7z` | 481,027,169 | `57a7d5d93fe5681338f097139932c60b67b8a0016716c0d64d6ab583905fd439` |

- implementation source: `5b62e1f`
- image format: `plumos-mini-plus-full-stack-validation-image-v3`
- archive test: `7zz t` success
- archive round-trip: streaming展開したraw SHA-256が上表rawと一致
- publication: `publishable=no`

## image geometry

| 領域 | sector | size | 用途 |
|---|---:|---:|---|
| Rockchip boot prefix | 0–32767 | 16 MiB | mini PLUS stock由来、SHA-256 `aa8bd95d...26e9` |
| p1 | 32768–1081343 | 512 MiB | FAT32 boot、kernel、mini PLUS DTB/overlay、initramfs、System A/B |
| p2 | 1081344–1212415 | 64 MiB | raw matching boot bundle |
| p3 | 1212416–5668863 | 2,176 MiB | ext4 managed Runtime/state seed |
| p4 | first bootで作成 | 残領域 | `PLUMOS` user/update/media ownership |

p3のseedは固定4 GiBではない。app layer実使用量`2,008,227,253` bytesに
`268,435,456` bytesの最低余裕を加え、128 MiB単位に切り上げた結果が2,176 MiBである。
初回起動では永続intentを使ってp3を8,192 MiBへ拡張し、残領域にp4を作る。最小カード容量は
14,336 MiBである。

## host検証

full imageから各partitionを再抽出して次を確認した。

- mini PLUS boot prefix、`rk3566-gkdmini-pro.dtb`とsensor別DTB、overlayの固定hash
- p1 filesystem、p2 raw matching bundle、p3 filesystemのhashと`fsck`
- read-only SquashFS System A/Bとboot slot state
- first-boot storage transactionの中断再開、既存／未知partition非破壊gate
- 12,482 app-layer filesのglobal checksum
- 97 systems、196 launch profiles、114 libretro coresのcatalog/load gate
- release-content audit: user media 0、private key 0、approved firmware 17
- SD2 identity/fallback、power finalizer、signed Runtime Update/rollback
- credential-free Wi-Fi scan/config保存契約、Dropbear host-keyの実機生成契約
- vendor/runtime license audit

## チェック表の再判定

`PASS`は現在のartifactでhost証拠まで揃った項目、`PARTIAL`はhost実装済みだが実機証拠が
必要な項目、`PENDING`は実機acceptance待ちを示す。

| ID | 状態 | 修正後の証拠／残作業 |
|---|---|---|
| `PLM-ART-01` | `PASS` | raw/7zのfilename、byte size、SHA-256、展開round-tripを記録した。 |
| `PLM-ART-02` | `PASS` | p3をpayload実測+256 MiB余裕、128 MiB alignmentで2,176 MiBに算出した。 |
| `PLM-ART-03` | `PARTIAL` | imageへfirst-boot経路を統合し、中断再開host fixtureは合格。実機初回起動待ち。 |
| `PLM-ART-04` | `PARTIAL` | 全component/image verifierは合格。clean checkout再現build記録は未作成。 |
| `PLM-ART-05` | `PASS` | 12,482 filesを監査し、user media/private keyは0。 |
| `PLM-ART-06` | `PENDING` | 同じraw hashの実機合格とpromotion manifestが必要。 |
| `PLM-BOOT-01` | `PASS` | mini PLUS実測prefix、kernel、全DTB/overlayをimage readbackで照合した。 |
| `PLM-BOOT-02` | `PASS` | matching boot bundleを独立p2へ収録し、raw partition hashを照合した。 |
| `PLM-SYS-01` | `PASS` | imageから抽出したread-only SquashFS Systemを検証した。 |
| `PLM-SYS-02` | `PARTIAL` | System A/Bとstateを収録。実機切替、health、rollback待ち。 |
| `PLM-STO-01` | `PASS` | managed p3とfirst-boot p4 `PLUMOS`のownershipを分離した。 |
| `PLM-STO-02` | `PARTIAL` | 永続intentとhost interruption fixtureは合格。実機中断再開待ち。 |
| `PLM-STO-03` | `PARTIAL` | read-only mount実装済み。実機mount table/write拒否待ち。 |
| `PLM-STO-04` | `PARTIAL` | identity/fallback host testは合格。実機SD2挿抜待ち。 |
| `PLM-STO-05` | `PARTIAL` | power-finalizer host testは合格。実機shutdown/fsck待ち。 |
| `PLM-FE-01` | `PARTIAL` | 旧UI候補では実機合格。現在のfull-stack rawは未起動。 |
| `PLM-FE-02` | `PENDING` | 全button/stick/Fn/hotkey/long-pressの実機matrixが必要。 |
| `PLM-EMU-01` | `PASS` | catalog 97 systems/196 profiles、114 coresのhost gate合格。 |
| `PLM-EMU-02` | `PENDING` | renderer別launch/exit/FE復帰の実機matrixが必要。 |
| `PLM-APP-01` | `PENDING` | Pyxel/PortMaster/NextCommander/Music Playerの実機起動待ち。 |
| `PLM-HW-01` | `PENDING` | 音声、jack、volume、suspend、性能設定の実機確認待ち。 |
| `PLM-NET-01` | `FAIL` | `8821cs.ko`は4.19.172、kernelは4.19.193+modversions。強制loadはrelease合格にしない。 |
| `PLM-NET-02` | `PARTIAL` | credential-free host gateは合格。実機association/reconnect待ち。 |
| `PLM-NET-03` | `PENDING` | DHCP後のport 22、host key、SSH loginを実機確認する。 |
| `PLM-NET-04` | `PENDING` | listener、設定反映、network中shutdownを実機確認する。 |
| `PLM-UPD-01` | `PARTIAL` | signed Runtime Update/rollback host fixture合格。実機更新待ち。 |
| `PLM-UPD-02` | `PARTIAL` | inactive System slot経路を収録。実機readback/rollback待ち。 |
| `PLM-REC-01` | `PARTIAL` | stage/log/recovery実装済み。実機stage readback待ち。 |
| `PLM-LIC-01` | `PASS` | vendor audit、NOTICE、publication boundary合格。 |
| `PLM-DOC-01` | `PASS` | 文書とp1/p2/p3/first-boot p4 contractを修正した。 |
| `PLM-REL-01` | `PENDING` | write/readback、3 cold boots、hardware/runtime/network/power合格が必要。 |
| `PLM-REL-02` | `PARTIAL` | verifier、7z test、streaming hashは合格。実機合格後のrelease bundleは未作成。 |

集計: `PASS 10`、`PARTIAL 13`、`FAIL 1`、`PENDING 8`。

## 次のacceptance

このrawを空のテスト用SDへ書き、同じSHA-256をreadbackで確認する。最初のcold bootでは
System A/B、p3 resize、p4作成、frontend到達を確認する。Wi-Fiは通常loadを先に試し、
ABI不一致moduleの強制load結果はdebug evidenceとして分離する。network不成立でも、serialまたは
p1のpersistent stage/logを回収し、boot/storage/runtimeの合否と混同しない。
