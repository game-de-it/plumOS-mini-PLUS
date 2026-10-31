# mini PLUS autonomous integration and validation

日付: 2026-10-31

## Integrated boot payload and image

source `427c28a`から通常の`build-mini-plus-full-image.sh --assemble-only`で
`0.1.0-dev-20261031`候補を生成した。frontendは同じsourceから再buildし、残るruntime componentは
検証済みcacheを使用した。package内のsource scriptと各component stagingの一致も確認した。

- raw: `output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-dev-20261031-full-stack-validation.img`
- size: 2,902,458,368 bytes
- SHA-256: `1d3f3067cb9cffed2909e52344001dee968269ec157f4fc5dcfe6f41ffe09392`
- 元stock `Image`を保持し、p1/p2へ追加の`Image-usb-sleep`を収録。
- active kernel SHA-256: `c18890e0bc6c439095f5a0f97d0d643ee3019cad94eaed8a459c3dc015f48653`
- p1/p2へ`overlay-user/mini-plus-sd1-sdr104.dtbo`を収録。
- overlay SHA-256: `675bca0f0c8a91db7333010bedac1471222b3dd8ed5d0ef029cb74ec05dcf776`
- uEnvは`kernelimg=Image-usb-sleep`、`user_overlays=mini-plus-sd1-sdr104`。
- kernelとoverlayは現在の実機検証カード上の同じfileとhash一致。

image verifierは、raw hash、partition map、prefix、FAT/ext4、p1/p2双方のboot file、System A/B、
initramfs、global checksum、97 systems/196 routeの双方向catalog、114 core load、
ROM/private key/credential非混入、license gateを合格した。

vendor boot DTBはU-Boot用の独自encoded形式であるためbyte一致を検証し、overlayの意味検証には
hash固定した採取済みruntime DTBを使った。`compare-fdt.py`では追加が
`/dwmmc@fe2b0000:sd-uhs-sdr104`の1 propertyだけであることを確認した。

## Live checksum repair

修復前のglobal checksumには、空白を含む5,224 filenameが第1語へ切られた状態で残っていた。
`repair-mini-plus-checksum-paths.py`は元packageをpath dictionaryとしてだけ使い、
digestとprefixが一致する完全pathを復元した。同じdigestの重複iconは対応する完全集合が
特定できる場合だけ復元し、不完全・曖昧な集合は拒否する。hash自体の変更は0件。

- before: `b9ed8b123cb8809230f424dae644d0c23bd7ceca944c03ed6a6679ea294b8f7a`
- after: `923fa295947e4cf47b1b3b8229bf85ae5a5e2a64e982223778993293632a5a66`
- 実機でstaging checksumを全件検証し、12,482/12,482一致後にatomic確定。
- rollback: `/storage/plumos/state/app-deploy/20261031-checksum-path-repair/`

live binary、利用者設定、PortMaster更新物、ROM/saveは修復のために上書きしていない。

## Cross-runtime sleep machine checks

通常FEをsupervisor hold後に完全終了し、display fdの解放を確認してから各runtimeを起動した。
設定、save/state、runtime mutable directoryは専用bind sandboxへ隔離した。
実際のpower overlay UIへ`--script up,up,up,a`でSleepを選択させ、safe-shutdownへ7秒RTCを追加した。
overlayとbrokerによる通常のdisplay handoffを通している。

| runtime | content | suspend/resume | exact active plane geometry | PCM pre/post |
|---|---|---|---|---|
| RetroArch / Gambatte | GB Baseball | PASS | PASS | PASS / PASS |
| PicoArch / Gambatte | GB Baseball | PASS | PASS | PASS / PASS |
| RetroArch / Mupen64Plus-Next | N64 AeroGauge | PASS | PASS | PASS / PASS |
| standalone PPSSPP | PSP Telegraph Crosswords | PASS | PASS | PASS / PASS |

全経路で同じgame process groupが復帰し、ALSA `RUNNING`と異なる`hw_ptr`を2標本で確認した。
plane判定は8 geometry propertyの一致とactive framebufferの存在であり、非黒pixel、
画像内容、向き、可聴音質、実controller操作の合格を意味しない。

## Save/state persistence

Gambatte/GBC `Cross Hunter - X Hunter Version.gbc`を専用save/config sandboxで試験した。
通常FEは完全終了し、直接runtimeを起動する前にdisplay fdが無人であることを確認した。

1. stdin commandでstateを保存し、59,656 byteのstateとSRAM fileを確認した。
2. 正常QUIT後に両fileのSHA-256を記録し、syncした。
3. 新しいruntime processを起動して両fileのhash一致を確認した。
4. 同じstateのLOAD_STATE成功をruntime logで確認した。SRAMについては別process起動後の
   file保持とhash一致を合格証拠とし、ゲーム内save UIからの読込みは未操作とする。

network無効buildはstdinのO_NONBLOCK初期化を省略するため、試験時だけ
`with-nonblocking-stdin`を使用した。`quit_press_twice=false`も試験用append configに限定した。
ユーザーの既存save/stateや入力・終了設定には適用していない。

全試験後、sandbox mount残留なし、foreground markerなし、通常FE 1個へ復帰した。
この合格はGambatte代表経路のファイル永続性であり、全coreのstate互換性の合格ではない。

## Host checks and remaining physical boundary

以下が合格した。

- power menu / finalizer / sleep / physical input contract
- first-boot storage中断再開fixture
- SD2 UUID解決・SD1 fallback / storage health / fast boot gate
- signed Runtime Update、downgrade拒否、2 rollback、mutable設定保持fixture
- supported systems文書整合
- checksum path repairの曖昧性拒否・hash保持・重複集合・冪等性test

記録は`artifacts/device-validation/2026-10-31-maintenance/`に保存した。
新規imageの別SD書込み/readback、first boot、cold boot 3回、SD2の物理挿抜、System A/Bの
実機更新/故障復旧、追加runtimeの物理画面・音・入力は未確認のままである。
`publishable=no`および`physical_boot_status=unverified-full-image`を維持する。
