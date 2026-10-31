# GKD mini PLUS port status

Bubbleで得られた検証結果は`docs/reference/bubble/`に保存するが、mini-PLUSの実機合格としては扱わない。

> 2026-10-20監査: 以下の`MPLUS-P2-03`は2-partition bring-up artifactの生成完了を示すだけで、
> plumOS完成imageの合格ではない。4 GiB固定p2版はrelease候補から撤回した。基準と全判定は
> `docs/plumos-implementation-checklist.ja.md`および
> `docs/validation/2026-10-20-mini-plus-plumos-conformance-audit.md`を参照する。修正後の
> full-stack候補は`docs/validation/2026-10-20-mini-plus-bubble-contract-host-candidate.md`に記録した。

## 完了

- [x] `MPLUS-P0-01` stockOS SDを`/dev/disk5`（Secure Digital、124383133696 bytes）として識別した。
- [x] `MPLUS-P0-02` p1を読み取り専用で固定し、ブート先頭16 MiBをSHA-256付きで取得した。
- [x] `MPLUS-P0-03` stock kernel、外部initrd、`uEnv.txt`、active DTB、sensor別DTB、overlayを取得して固定ハッシュ化した。
- [x] `MPLUS-P0-04` stock `SYSTEM`を解析専用として扱い、USB module、Mali userspace pairを個別取得した。内蔵Wi-Fiはlive stockOSでSDIO `02D0:A9A6` + `bcmdhd` matching setとして再採取した。
- [x] `MPLUS-P1-01` stock p2 rootに依存せず、p1上のplumOS SYSTEMを起動するmini-PLUS専用外部initramfsを実装した。
- [x] `MPLUS-P1-02` raw boot prefix + FAT32 p1 + ext4 p2のhost candidate imageを生成した。
- [x] `MPLUS-P1-03` image SHA-256、MBR、FAT/ext4、boot prefix、kernel、DTB、overlayをホスト上で検証した。
- [x] `MPLUS-P1-04` Bubble由来frontendを含む別のUI確認用候補を生成し、component checksumとp1/p2のimage内byte一致を検証した。
- [x] `MPLUS-P2-01` UI確認用候補でfrontendが起動し、コントローラーによる基本操作が可能なことをユーザー報告で確認した（`docs/validation/2026-10-20-mini-plus-frontend-user-acceptance.md`）。
- [x] `MPLUS-P2-02` frontend、114 libretro core、RetroArch、PicoArch、単体emulator、Pyxel、PortMaster、NextCommander、Music Player、network servicesをfull app layerへ統合した。
- [x] `MPLUS-P2-03` 512 MiB FAT32 p1 + 4 GiB ext4 p2のfull **bring-up** artifactを生成し、partition、filesystem、boot payload、app layerをimageから読み戻して検証した。4 GiB固定layoutは撤回済み（`docs/validation/2026-10-20-mini-plus-full-host-candidate.md`）。
- [x] `MPLUS-P2-04` live stockOSで確認した`bcmdhd`、BCM43438A1 firmware、AP6212A NVRAMによる通常load、Wi-Fi初回接続UI、DHCP、Dropbear SSH自動待受を実装し、host contract testを通過した。
- [x] `MPLUS-PORTS-01` Apotris v4.2.0の無音とSIGSEGVを実機再現し、v4.1.0とのA/BでPCM進行、可聴音、継続動作、通常終了を確認した。既知のv4.2.0 SHAだけを検証済みv4.1.0へbindするPortMaster互換ガード、raw PWM no-op、厳密なmount cleanupを実装・配備した（`docs/validation/2026-10-21-mini-plus-apotris-portmaster.md`）。
- [x] `MPLUS-INPUT-01` plumOS共通の`SELECT`＋音量－／＋による20段階輝度hotkeyを常駐hardware-key serviceへ移植した。音量単独、長押し中の操作種別固定、遅延設定保存、ゲーム中の非grab入力を維持する。
- [x] `MPLUS-INPUT-02` mini PLUS実機でBubble由来のPWMカーブはレベル1〜12（raw 1〜52）の変化がほぼ見えず、13（raw 68）から急増することを確認した。暗い側のraw 52を維持しつつ、応答境界を含むraw 52〜255を20段階へ再配分し、ホットキー操作で自然に明るさが変化することをユーザー確認した。
- [x] `MPLUS-HW-03` mini PLUSにはstickが存在しないことを機種契約へ反映し、全物理入力をユーザー確認した。4個のFnキーのうち1個からRetroArch/PicoArchの各メニューへ到達することも確認した。
- [x] `MPLUS-HW-04` speaker/headphone、左右、音量/mute、jack切替を含む音声操作をユーザー総合確認した。既存のRK817 `SPK_HP`補正と各runtimeのPCM/可聴試験を合わせ、mini PLUS音声acceptanceを完了した。
- [x] `MPLUS-APP-01` 標準アプリの起動・操作をユーザー確認した。
- [x] `MPLUS-PERF-01` SDR104/148.5 MHz候補について、起動高速化、SD整合性および継続利用時の安定性をユーザー確認し、既定採用可と判定した。
- [x] `MPLUS-NET-02` 保存済みnetworkへのWi-Fi再接続をユーザー確認した。shutdown/reboot中の表示・入力競合はnetwork項目から分離し、`MPLUS-HW-05`で追跡する。

## plumOS contract修正完了

- [x] `MPLUS-ARCH-01` mini PLUS実測prefix/DTBを使うp1 System A/B + p2 matching bundle + measured p3 seedを再構築し、first bootでp3を8 GiBへ拡張してp4 `PLUMOS`を作る経路を同一imageへ統合した。
- [x] `MPLUS-ARCH-02` raw imageと7z validation assetのsize/hash/展開round-tripを別々に記録し、固定4 GiB p2 contract testをmeasured seed contractへ置き換えた。
- [x] `MPLUS-ARCH-03` Bubble由来の`648078...` prefix、`rk3566-gkd-geek-bbg.dtb`、`0a3a3b6` source refがmini PLUS build/release scriptへ残らないgateを追加した。

## 実機bring-up待ち

- [ ] `MPLUS-HW-01` 空のテスト用SDへ候補を書き、cold bootとU-Boot stage `S10`〜`S19`を確認する。
- [x] `MPLUS-HW-02` full-stack候補でinitramfs `S21`〜`S29`の成功、SYSTEM `S40_FRONTEND_SUPERVISOR_READY`、frontend/LCD到達を実機確認した。
- [x] `MPLUS-BOOT-02` 2026-10-31、ユーザーが新SDの通常起動確認をOKと報告した。厳密なcold boot回数やU-Boot stage採取はこの報告から追加推定しない。
- [x] `MPLUS-SD2-02` 新SDでSD2未装着のまま起動し、SFTP有効化後にport22接続、初期directory `/storage`、SD1 `/storage/user`一覧取得を確認した。最初の接続不可はSFTP設定が未有効だったためで、SD2依存の不具合ではなかった。再挿入後の認識・転送readbackは別途確認する。
- [x] `MPLUS-HW-05` SD整合性、ゲーム中Reboot/Shutdown、`62fe884`適用後のbattery-only Sleep復帰はユーザー確認済み。USB接続時のstock kernel充電gateを4-byteの限定patchで解除し、12秒Sleep/RTC復帰を実機ログで確認した。2026-10-31、ユーザーはUSB接続中のSleep復帰も正常と確認した。現在の検証カードの電源操作は合格とし、通常imageへの反映は`MPLUS-POWER-01`で追跡する（`docs/validation/2026-10-31-mini-plus-usb-sleep.md`）。

## 未解決

- [x] `MPLUS-BOOT-UI-01` `ee3a984`の全画面進捗・初回開始/完了各2秒・描画logを含む修正版で、ユーザーが新規SDの進捗表示を確認した。実機logでも開始〜完了の全7工程の書込み、p3拡張、p4作成、FE到達を確認した。複数回cold boot等は引き続き`MPLUS-REL-01`で追跡する。
- [ ] `MPLUS-META-02` 新SDへのコミット反映監査で、PicoArch component manifest/build scriptとinput mapの説明にdual analog/stickの古い記載が残っていた。ユーザー確認済みの物理stick無しとの整合を取る。新SDへの配備漏れではなく、元ソース側の説明・機種契約の残存であり、正常動作中の入力mappingを無検証で削除しない。
- [x] `MPLUS-POWER-01` `427c28a`で実機合格した`Image-usb-sleep`を通常image builderのp1/p2へ追加し、元stock Imageを保持した。生成imageからのreadback、4-byte限定patch、uEnvのkernel選択、稼働カードとのhash一致を検証した。新規SDへの物理bootは`MPLUS-REL-01`へ残す。
- [x] `MPLUS-PERF-02` 通常image builderのp1/p2へSDR104 overlayを収録し、uEnv選択、overlay hash、稼働カードとのhash一致、展開後runtime DTBに対する単一property追加を検証した。新規SDの物理cold bootは`MPLUS-REL-01`へ残す。
- [x] `MPLUS-META-01` live global checksumの5,224件の切れたpathを、元packageのdigestと完全pathの対応で復元した。記録済みhashは変更せず、実機12,482/12,482件の一致後にatomic適用した。新規生成imageのglobal checksumも全件readback合格した。
- [x] `MPLUS-SLEEP-01` USB接続中、RetroArch/Gambatte、PicoArch/Gambatte、RetroArch/Mupen64Plus-Next、単体PPSSPPでnormal power overlayの自動Sleepを試験した。各7秒のRTC復帰後、同じprocess group、active DRM plane geometry、ALSA PCM進行を確認し、通常FEを復帰した。画面の非黒pixel・物理音質・各button操作の確認はこの自動試験に含まない。
- [x] `MPLUS-SAVE-01` 専用sandboxのGambatte/GBCでステート59,656 byteとSRAMの保存を確認し、別process起動後に両fileのhash一致とstate読込みを確認した。ゲーム内save UIからの読込みや全coreのsave互換性へは一般化しない。
- [x] `MPLUS-NET-01` live stockOSでSDIO `02D0:A9A6`、`bcmsdh_sdmmc`/`bcmdhd`、matching kernel ABI、実使用firmware/NVRAMを確認し、RTL8821CS force-load経路を廃止した。
- [ ] `MPLUS-FE-01` 実SD2をBubble互換の`roms/<system>` + `bios`へ修正し、FEで10,247 files/534 ROMsを索引化した。ROM2全196 routeを実機走査し、補正再試験込みで170 route起動、PSP/PSX/OpenBORを含む166 routeのPCM進行、全観測経路のDRM/Mali表示契約を確認した。ユーザーがこれまで実行したゲームには不具合がなく概ね正常と評価した。残る2 routeはROM2の親archive不足、24 routeは互換content/BIOS不足で未合格であり、未確認routeを全合格とは扱わない。
- [x] `MPLUS-GPU-01` hash一致するMali AArch64/ARMhf pairを組み込み、N64、DraStic、YabasanshiroでDRM/KMS/EGLとMali-G52描画を実機確認した。
- [ ] `MPLUS-REL-01` live `runtime-coverage.json`とflat-root SD2の不整合は解消し、ROM2監査を記録した。残る物理操作/可聴/電源項目と、書き戻し後のpartition/hashを記録してrelease可否を判定する。
