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

## 実機bring-up待ち

- [ ] `MPLUS-HW-01` 空のテスト用SDへ候補を書き、cold bootとU-Boot stage `S10`〜`S19`を確認する。
- [ ] `MPLUS-HW-02` initramfs `S21`〜`S26`、SYSTEM `S30`以降、LCD 640x480表示を確認する。
- [ ] `MPLUS-HW-03` `retrogame_joypad`の全ボタン、両stick、Fnキーを確認する。
- [ ] `MPLUS-HW-04` RK817 speaker/headphone、音量、mute、jack切替を確認する。
- [ ] `MPLUS-HW-05` clean shutdown、reboot、suspend/resume、SD readbackを確認する。

## 未解決

- [ ] `MPLUS-NET-01` running kernel `4.19.193-g5a07852a55cf-dirty`に一致するRTL8821CS moduleを特定する。stock `SYSTEM`内のmoduleは`vermagic=4.19.172`のため現候補には入れない。
- [ ] `MPLUS-NET-02` Wi-Fi association、DHCP、reconnect、power-off競合を実機確認する。
- [ ] `MPLUS-FE-01` UI確認用候補のBubble frontendを実機で検証し、その後emulator/app layerを段階的に有効化する。
- [ ] `MPLUS-GPU-01` hash一致するMali AArch64/ARMhf pairを組み込み、DRM/KMS/EGLを実機確認する。
- [ ] `MPLUS-REL-01` 実機ログと書き戻し後のpartition/hashを記録してrelease可否を判定する。
