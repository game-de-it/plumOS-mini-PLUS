# plumOS 実装チェックリスト

このチェックリストは、Bubbleで成立したplumOSの設計とrelease工程から、機種に依存しない
必須条件を取り出したものです。partition番号やDTB名をそのまま他機種へコピーするための表では
ありません。機種固有なのはboot substrate、block-device解決、表示・入力・音声・network driver
です。storage ownership、更新transaction、検証とreleaseの境界はplumOS共通です。

判定は次の4種類を使います。

- `PASS`: 対象artifactで必要な証拠まで揃っている。
- `PARTIAL`: 実装またはhost testはあるが、対象imageへの統合か実機証拠が不足している。
- `FAIL`: 必須条件を満たしていない、または対象imageと実装が矛盾している。
- `PENDING`: 実機操作など、まだ実行していないacceptance gateである。

## 1. 配布artifactと再現性

| ID | 必須条件 | 合格証拠 |
|---|---|---|
| `PLM-ART-01` | raw imageと配布用圧縮archiveを別物として記録する | 両方のfilename、byte size、SHA-256、archive展開後raw hash一致 |
| `PLM-ART-02` | seed partitionはpayloadの実使用量と明示した余裕から算出し、空領域を固定値で過剰確保しない | 容量計算、最小空き容量gate、partition manifest |
| `PLM-ART-03` | 初回起動で対象容量へ安全に拡張し、user partitionを残領域へ作る | 中断再開可能なhost fixtureと実機first-boot記録 |
| `PLM-ART-04` | clean checkoutとhash固定した外部入力から再現buildできる | clean-build記録、全component checksum、image verifier |
| `PLM-ART-05` | ROM、save、credential、private keyなどの利用者データを含めない | release-content auditとsecret scan |
| `PLM-ART-06` | 実機合格したraw imageそのものを、byteを変えずにreleaseへ昇格する | device-tested SHA-256とpromotion manifestの一致 |

## 2. boot、System、storage ownership

| ID | 必須条件 | 合格証拠 |
|---|---|---|
| `PLM-BOOT-01` | 対象機のboot prefix、kernel、DTB、overlay、initramfsをhash固定し、他機種の値を混ぜない | read-only inventory、build-time hash gate、image readback |
| `PLM-BOOT-02` | boot payloadをmatching setとして扱い、通常Runtime Updateから分離する | matching bundle manifest、partition/full-image hash、recovery方針 |
| `PLM-SYS-01` | read-only SquashFS Systemを使う | imageから抽出したSystemのhashとmount証拠 |
| `PLM-SYS-02` | System A/B、active/pending/healthy state、inactive slot readbackを持つ | A/B verifier、正常切替、失敗時rollback |
| `PLM-STO-01` | managed Runtime/stateは`PLUMOS_SYS`、user/update/mediaは`PLUMOS`または同等の別ownershipへ分離する | filesystem label、mount table、path ownership test |
| `PLM-STO-02` | first bootのresize・user partition作成を永続intent付きで中断再開できる | interruption fixture、既存・未知partition非破壊gate |
| `PLM-STO-03` | 通常起動後はboot filesystemをread-onlyにする | 実機mount tableと更新経路以外からのwrite拒否 |
| `PLM-STO-04` | SD2は番号固定でなくidentityで解決し、不在・dirty・非対応でもSD1 bootを止めない | SD2 host testと実機挿抜・fallback記録 |
| `PLM-STO-05` | shutdown/reboot前にwriterを止め、user/SD2/runtimeをcleanにunmountまたはread-only化する | power finalizer test、再起動後fsck/readback |

## 3. frontend、emulator、app

| ID | 必須条件 | 合格証拠 |
|---|---|---|
| `PLM-FE-01` | frontendが自動起動し、表示と基本controller操作が成立する | 対象imageの実機bootと操作記録 |
| `PLM-FE-02` | 全button、stick、Fn、hotkey、long-pressを物理labelどおりに扱う | evdev/js mapと実機入力matrix |
| `PLM-EMU-01` | catalogの全system/profileが存在するruntimeへ双方向に解決する | catalog verifierとcore load smoke test |
| `PLM-EMU-02` | software、PicoArch、GLES、standaloneの代表routeで起動・終了・FE復帰する | 実機renderer別launch/exit matrix |
| `PLM-APP-01` | Pyxel、PortMaster、NextCommander、Music Playerなど標準appが起動・終了する | host contractと実機app matrix |
| `PLM-HW-01` | LCD、speaker/headphone、volume/mute、suspend/resume、性能設定が成立する | 実機hardware acceptance記録 |

## 4. networkとdebug

| ID | 必須条件 | 合格証拠 |
|---|---|---|
| `PLM-NET-01` | Wi-Fi driverとrunning kernel ABIが一致する。強制loadはrelease条件にしない | kernel/module vermagicとsymbol CRCの一致、通常load成功 |
| `PLM-NET-02` | credentialをimageへ埋めず、UIからscan・保存・再接続できる | credential-free image auditと実機first-connect/reconnect |
| `PLM-NET-03` | DHCP後にSSH/SFTPを利用でき、host keyを実機生成する | 実機IP、port 22、host-key path、login記録 |
| `PLM-NET-04` | FTP/SMBなど任意serviceのstart/stopとshutdown競合を処理する | 実機listener、設定反映、network中shutdown記録 |

## 5. update、回復、公開

| ID | 必須条件 | 合格証拠 |
|---|---|---|
| `PLM-UPD-01` | Runtime Updateは署名、target/ABI/version検証、staging、journal、health gate、rollbackを行う | signed update host testと実機update/rollback |
| `PLM-UPD-02` | System Updateはinactive slotへ書き、full readback後にatomic commitする | A/B update test、downgrade拒否、bad-slot recovery |
| `PLM-REC-01` | boot/runtime failureを可視stageとpersistent logで残し、回復経路を持つ | stage readback、recovery SSHまたはknown-good media |
| `PLM-LIC-01` | plumOS MIT、vendor stock、第三者runtimeの権利境界とNOTICEを分離する | license inventory、vendor audit、publication policy |
| `PLM-DOC-01` | user documentが実際のpartition/path/機能と一致する | image manifestとuser docsの整合test |
| `PLM-REL-01` | full imageでwrite/readback、3 cold boots、入力・音声・network・代表runtime・powerを合格する | 日付付きdevice acceptanceと最終SHA-256 |
| `PLM-REL-02` | verifier、圧縮、archive test、streaming展開hash、SHA256SUMSを通す | release bundle log |

## 合格の単位

source treeにコードがあること、host fixtureが通ること、imageへ収録されていること、実機で動くことは
別々の証拠です。`PASS`はチェック対象の段階まで揃った場合だけ付けます。別imageでの成功を新しい
full imageへ引き継がず、最終的には`PLM-REL-01`と`PLM-REL-02`を同一raw imageのSHA-256へ
結び付けます。
