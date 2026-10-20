# GKD mini PLUS port status

Bubbleで得られた検証結果は`docs/reference/bubble/`に保存するが、mini-PLUSの実機合格としては扱わない。

## 完了

- [x] `MPLUS-P0-01` stockOS SDを`/dev/disk5`（Secure Digital、124383133696 bytes）として識別した。
- [x] `MPLUS-P0-02` p1を読み取り専用で固定し、ブート先頭16 MiBをSHA-256付きで取得した。
- [x] `MPLUS-P0-03` stock kernel、外部initrd、`uEnv.txt`、active DTB、sensor別DTB、overlayを取得して固定ハッシュ化した。
- [x] `MPLUS-P0-04` stock `SYSTEM`を解析専用として扱い、RTL8821CS、USB module、Mali userspace pairのみを個別取得した。
- [x] `MPLUS-P1-01` stock p2 rootに依存せず、p1上のplumOS SYSTEMを起動するmini-PLUS専用外部initramfsを実装した。
- [x] `MPLUS-P1-02` raw boot prefix + FAT32 p1 + ext4 p2のhost candidate imageを生成した。
- [x] `MPLUS-P1-03` image SHA-256、MBR、FAT/ext4、boot prefix、kernel、DTB、overlayをホスト上で検証した。
- [x] `MPLUS-P1-04` Bubble由来frontendを含む別のUI確認用候補を生成し、component checksumとp1/p2のimage内byte一致を検証した。
- [x] `MPLUS-P2-01` UI確認用候補でfrontendが起動し、コントローラーによる基本操作が可能なことをユーザー報告で確認した（`docs/validation/2026-10-20-mini-plus-frontend-user-acceptance.md`）。
- [x] `MPLUS-P2-02` frontend、114 libretro core、RetroArch、PicoArch、単体emulator、Pyxel、PortMaster、NextCommander、Music Player、network servicesをfull app layerへ統合した。
- [x] `MPLUS-P2-03` 512 MiB FAT32 p1 + 4 GiB ext4 p2のfull host candidateを生成し、partition、filesystem、boot payload、app layerをimageから読み戻して検証した（`docs/validation/2026-10-20-mini-plus-full-host-candidate.md`）。
- [x] `MPLUS-P2-04` stock RTL8821CSの通常load→明示許可付き互換load、Wi-Fi初回接続UI、DHCP、Dropbear SSH自動待受を実装し、host contract testを通過した。

## 実機bring-up待ち

- [ ] `MPLUS-HW-01` 空のテスト用SDへ候補を書き、cold bootとU-Boot stage `S10`〜`S19`を確認する。
- [ ] `MPLUS-HW-02` frontend/LCD到達はユーザー報告で確認済み。initramfs `S21`〜`S26`、SYSTEM `S30`以降のstage記録を回収する。
- [ ] `MPLUS-HW-03` frontendの基本操作はユーザー報告で確認済み。`retrogame_joypad`の全ボタン、両stick、Fnキーを確認する。
- [ ] `MPLUS-HW-04` RK817 speaker/headphone、音量、mute、jack切替を確認する。
- [ ] `MPLUS-HW-05` clean shutdown、reboot、suspend/resume、SD readbackを確認する。

## 未解決

- [ ] `MPLUS-NET-01` stock RTL8821CS module（`vermagic=4.19.172`、symbol CRCなし）を、通常load後に明示マーカー付き`insmod -f`で試す実験候補を実機検証する。running kernelは`4.19.193-g5a07852a55cf-dirty`かつ`CONFIG_MODVERSIONS=y`のため、成功まではABI不一致扱いとする。
- [ ] `MPLUS-NET-02` Wi-Fi association、DHCP、reconnect、power-off競合を実機確認する。
- [ ] `MPLUS-FE-01` frontend到達と基本操作は確認済み。全emulator/app layerを組み込んだ候補で各runtimeと終了復帰を実機検証する。
- [ ] `MPLUS-GPU-01` hash一致するMali AArch64/ARMhf pairを組み込み、DRM/KMS/EGLを実機確認する。
- [ ] `MPLUS-REL-01` 実機ログと書き戻し後のpartition/hashを記録してrelease可否を判定する。
