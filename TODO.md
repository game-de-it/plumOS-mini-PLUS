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

## plumOS contract修正完了

- [x] `MPLUS-ARCH-01` mini PLUS実測prefix/DTBを使うp1 System A/B + p2 matching bundle + measured p3 seedを再構築し、first bootでp3を8 GiBへ拡張してp4 `PLUMOS`を作る経路を同一imageへ統合した。
- [x] `MPLUS-ARCH-02` raw imageと7z validation assetのsize/hash/展開round-tripを別々に記録し、固定4 GiB p2 contract testをmeasured seed contractへ置き換えた。
- [x] `MPLUS-ARCH-03` Bubble由来の`648078...` prefix、`rk3566-gkd-geek-bbg.dtb`、`0a3a3b6` source refがmini PLUS build/release scriptへ残らないgateを追加した。

## 実機bring-up待ち

- [ ] `MPLUS-HW-01` 空のテスト用SDへ候補を書き、cold bootとU-Boot stage `S10`〜`S19`を確認する。
- [x] `MPLUS-HW-02` full-stack候補でinitramfs `S21`〜`S29`の成功、SYSTEM `S40_FRONTEND_SUPERVISOR_READY`、frontend/LCD到達を実機確認した。
- [ ] `MPLUS-HW-03` frontendの基本操作はユーザー報告で確認済み。`retrogame_joypad`の全ボタン、両stick、Fnキーを確認する。
- [ ] `MPLUS-HW-04` RK817 ALSA/softvol、直接PCM write、32 emulator routeのPCM進行は確認済み。NES実行中の無音を調査し、`Playback Path=OFF`、続いてmini PLUSで発音しない`SPK`単独経路を確認した。`SPK_HP`へ切り替えると実機で可聴音を確認し、OFF/SPKだけをSPK_HPへ補正するmanaged初期化を追加した。headphone単独、左右、全音量段、mute、jack自動切替は引き続き確認する。
- [ ] `MPLUS-HW-05` clean shutdown、reboot、suspend/resume、SD readbackを確認する。

## 未解決

- [ ] `MPLUS-PERF-01` mini PLUS SD1をSDR50/50 MHzからSDR104/148.5 MHzへ切り替える可逆overlayを作成した。128 GB検証カードのcold boot 1/5、tuning成功、64 MiB p3→p4 readback、起動前半3.4秒短縮を確認した。残るcold boot、長時間I/O、macOS readback、物理音声と代表ゲーム回帰を確認してから既定採用を判断する。
- [x] `MPLUS-NET-01` live stockOSでSDIO `02D0:A9A6`、`bcmsdh_sdmmc`/`bcmdhd`、matching kernel ABI、実使用firmware/NVRAMを確認し、RTL8821CS force-load経路を廃止した。
- [ ] `MPLUS-NET-02` Wi-Fi association、DHCP、SSH/FTP/SMB待受は実機確認済み。保存済みnetworkのreconnectとpower-off競合を確認する。
- [ ] `MPLUS-FE-01` 実SD2をBubble互換の`roms/<system>` + `bios`へ修正し、FEで10,247 files/534 ROMsを索引化した。ROM2全196 routeを実機走査し、補正再試験込みで170 route起動、PSP/PSX/OpenBORを含む166 routeのPCM進行、全観測経路のDRM/Mali表示契約を確認した。残る2 routeはROM2の親archive不足、24 routeは互換content/BIOS不足で未合格。全routeの物理コントローラー操作とspeaker可聴playtestを行う。
- [x] `MPLUS-GPU-01` hash一致するMali AArch64/ARMhf pairを組み込み、N64、DraStic、YabasanshiroでDRM/KMS/EGLとMali-G52描画を実機確認した。
- [ ] `MPLUS-REL-01` live `runtime-coverage.json`とflat-root SD2の不整合は解消し、ROM2監査を記録した。残る物理操作/可聴/電源項目と、書き戻し後のpartition/hashを記録してrelease可否を判定する。
