# GKD mini PLUS plumOS conformance audit

Date: 2026-10-20

Baseline: `docs/plumos-implementation-checklist.ja.md`

> この文書は4 GiB固定版を検査した**修正前baseline**として保持する。ここで指摘した
> architecture問題を直した新しいfull-stack候補と再判定は
> `2026-10-20-mini-plus-bubble-contract-host-candidate.md`に記録した。

Audited full artifact:
`output/image/mini-plus-full/plumOS-mini-PLUS-0.1.0-dev-full-host-candidate.img`

## 結論

現行full artifactは、mini PLUS固有boot substrateでfrontendと全app payloadを試すための
**2-partition bring-up image**です。Bubbleで確立したstorage/update/release contractを備えた
plumOS完成候補ではありません。以後、このraw imageをrelease candidateまたはBubble同等完成版
として扱いません。

最大の問題はpayload量ではなくlayoutです。mini PLUSとBubbleのfull app layerはほぼ同じです。

| 項目 | Bubble | mini PLUS現行full |
|---|---:|---:|
| app layer (`du -sk`) | 1,988,744 KiB | 1,988,804 KiB |
| raw prefix | 16 MiB | 16 MiB |
| p1 | 512 MiB | 512 MiB |
| matching p2 | 64 MiB | なし |
| managed Runtime seed | p3 2,304 MiB | p2 4,096 MiB固定 |
| raw image | 3,036,676,096 bytes | 4,848,615,424 bytes |
| 配布archive | 480,810,424-byte `.7z` | 未作成 |

Bubbleの「500MB以下」は3,036,676,096-byte raw imageを7z圧縮したrelease assetです。
mini PLUSの4,848,615,424 bytesは未圧縮raw imageです。ただし、比較形式の違いだけでなく、
mini PLUS側が4 GiB p2を固定確保した設計ミスもあります。Bubbleと同じpayload量なので、
4 GiB p2を必須とする根拠はありません。

## 判定表

| ID | 状態 | mini PLUSの証拠と不足 |
|---|---|---|
| `PLM-ART-01` | `FAIL` | 現行fullはrawだけ。release archive、archive hash、展開round-tripがない。 |
| `PLM-ART-02` | `FAIL` | `build-mini-plus-full-image.sh`が`storage_sectors=8388608`を固定し、4 GiB p2を作る。実使用量からの計算ではない。 |
| `PLM-ART-03` | `PARTIAL` | first-boot provisioning host fixtureは合格したが、現行full imageはp2までしかなく、その経路を使わない。 |
| `PLM-ART-04` | `PARTIAL` | component/image checksumはある。mini PLUS fullのclean-clone再現build記録はない。 |
| `PLM-ART-05` | `PASS` | release-content auditは12,481 files、user media 0、private key 0で合格。 |
| `PLM-ART-06` | `PENDING` | full image自体の実機boot・readbackが未実施。 |
| `PLM-BOOT-01` | `PARTIAL` | 現行2-partition imageは正しいmini PLUS prefix `aa8bd9...`と`rk3566-gkdmini-pro.dtb`を使う。一方、3-partition builderはBubble prefix `648078...`とBubble DTB名を残しておりbuild不能。 |
| `PLM-BOOT-02` | `FAIL` | 現行fullのp2は`PLUMOS_DATA`で、immutable matching boot bundleではない。 |
| `PLM-SYS-01` | `PARTIAL` | 9,240,576-byte SquashFS `SYSTEM`を収録する。別のUI確認用imageでは実機frontend到達済みだが、このfull image自体のmount証拠はない。 |
| `PLM-SYS-02` | `FAIL` | 現行fullは単一`SYSTEM`。A/B slot、pending/healthy、inactive readbackを収録しない。 |
| `PLM-STO-01` | `FAIL` | 現行fullはp2 `PLUMOS_DATA`へmanaged Runtimeとmutable dataを同居させ、p3/p4 ownershipを持たない。 |
| `PLM-STO-02` | `PARTIAL` | intent付きresize/p4作成コードとhost testはあるが、現行fullに統合されていない。 |
| `PLM-STO-03` | `PARTIAL` | initはp1 read-only mountを意図するが、full imageの実機mount/readback証拠がない。 |
| `PLM-STO-04` | `PARTIAL` | identity、fallback、OS-device拒否のhost testは合格。mini PLUS実機SD2は未確認。 |
| `PLM-STO-05` | `PARTIAL` | power-finalizer host testは合格。実機shutdown/reboot/fsckは未確認。 |
| `PLM-FE-01` | `PARTIAL` | frontend-only imageで起動と基本controller操作をユーザー確認済み。full image自体は未起動。 |
| `PLM-FE-02` | `PENDING` | 全button、stick、Fn、hotkey、long-pressの実機matrixがない。 |
| `PLM-EMU-01` | `PASS` | 97 systems、196 profile occurrences、114 coresのhost catalog/load gateは合格。 |
| `PLM-EMU-02` | `PENDING` | full imageのsoftware/PicoArch/GLES/standalone実機launch/exitがない。 |
| `PLM-APP-01` | `PENDING` | app payloadとhost contractはあるが、full imageでの実機起動証拠がない。 |
| `PLM-HW-01` | `PENDING` | 音声、headphone、volume、suspend/resume、性能設定が未確認。 |
| `PLM-NET-01` | `FAIL` | stock `8821cs.ko`は`4.19.172`、running kernelは`4.19.193`かつmodversions有効。`insmod -f`はdebug実験でありrelease条件を満たさない。 |
| `PLM-NET-02` | `PARTIAL` | credential-free scan/preserve host testは合格。実機association/reconnectは未確認。 |
| `PLM-NET-03` | `PENDING` | Dropbearと実機host-key生成コードはあるが、wlan/DHCP/port 22/loginの実機証拠がない。 |
| `PLM-NET-04` | `PENDING` | service payloadはあるが、実機listenerとnetwork中shutdownを未確認。 |
| `PLM-UPD-01` | `PARTIAL` | Ed25519、downgrade拒否、2回のrollback、mutable設定保持のhost testは合格。現行imageには`/storage/user`を所有するp4がなく、実機update未確認。 |
| `PLM-UPD-02` | `FAIL` | 現行imageにSystem A/Bがなく、System Updateを実装できない。 |
| `PLM-REC-01` | `PARTIAL` | stage/log/recovery codeはある。full imageのstage readbackとrecovery SSHは未確認。 |
| `PLM-LIC-01` | `PASS` | vendor audit、runtime license inventory、NOTICE、DraStic boundaryがhost gateを通過。 |
| `PLM-DOC-01` | `FAIL` | user docsは`/storage/user`とp4を前提にするが、現行fullはp2だけ。既存full image manifestは別imageのfrontend成功を`physical_boot_status`へ誤記している。release scriptはBubble source ref `0a3a3b6`を固定し、mini PLUS release notesもない。 |
| `PLM-REL-01` | `PENDING` | full imageのwrite/readback、3 cold boots、runtime/audio/network/power acceptanceがない。 |
| `PLM-REL-02` | `FAIL` | mini PLUS release bundleは未作成。現release scriptはmini PLUS固有promotion gateへ未移植。 |

集計: `PASS 3`、`PARTIAL 12`、`FAIL 9`、`PENDING 8`。

## 今回再実行したhost gate

次の既存testは2026-10-20に再実行して合格しました。

- current full-image contract（これは4 GiB固定という現状を検証するtestであり、仕様の正しさは証明しない）
- first-boot storage transaction fixture
- Wi-Fi ABI policyとcredential-free first-connect fixture
- release-content/vendor audit
- SD2 identity/fallback fixture
- power finalizer fixture
- signed Runtime Update、downgrade拒否、rollback fixture

## 作り直しの順序

1. 4 GiB固定の`build-mini-plus-full-image.sh`をrelease経路から外す。
2. 3-partition seed builder/verifierのBubble prefix、DTB、hash、device名をmini PLUS実測値へ置換し、copy残りを機械検査する。
3. p1 System A/B、p2 matching bundle、p3 measured seed、first-boot p4を同一imageへ統合する。
4. p3 seed容量をapp layer実使用量から計算し、raw/7zの両サイズとhashを記録する。500MB未満は実測前に約束しない。
5. kernel ABIが一致するRTL8821CS driverを確保する。強制load版はnetwork debug専用のprivate candidateに限定する。
6. full imageの実機boot後、Wi-Fi/SSHを使ってruntime、audio、input、powerを順にacceptanceし、最後にreadbackする。
7. mini PLUS固有release notes、promotion manifest、source ref gateへrelease scriptを作り直す。

この順序では、frontend-onlyで得た実機成功を保持しつつ、storage contractとnetworkを一度に
混同しません。次の書き込み対象は、少なくとも`PLM-BOOT-01`から`PLM-STO-03`までをhost上で
満たした新しいnon-publishable imageにします。
