# mini PLUS SD2 / ROM2 emulator audit (2026-10-21)

## Scope

Bubble互換のROM pathをmini PLUSの実SD2へ適用し、
`/Volumes/public/02/motoki/emu/ROM/rom2`のROM/BIOSを検証用contentとして使って、
frontend、色、映像、音声、emulator routeを実機`192.168.10.141`で再監査した。
自動化で確認できないspeakerの可聴品質と全routeの物理入力操作は、本記録では合格扱いにしない。

## SD2 layout

実SD2 rootは次のみに整理した。

- `roms/<system>/...`
- `bios/...`
- `System Volume Information/`
- `autorun.inf`
- `autorun.ico`

旧flat-rootの104 system directoryは`roms/`配下へ移動した。
`/run/media/sd2/roms`から`/storage/user/Roms`、`/run/media/sd2/bios`から
BIOS rootへのbindを確認した。frontend scanは10,247 files、534 matched ROMsだった。
移動前root inventoryは
`artifacts/device-validation/2026-10-20-mini-plus-sd2-root-before.txt`
（SHA-256 `631a795115f50b8cf892f116e0d47d43ef050c9bc9e3ebc335770148f9b31a50`）に保存した。

SD2 FATにはdirty flagが残る。稼働中の媒体へfsckは実施していない。電源断後にMacまたは
保守起動から検査する必要がある。

## ROM2 validation set

content選択は`/storage/plumos/state/device-matrix/content/rom2-20260904`へ転送した
1.3 GiB、1,704 filesである。mapは
`artifacts/device-validation/2026-10-20-mini-plus-rom2-content-map.json`
（SHA-256 `865e8ab5c4c8e743ad8c1395939583c861089bffd291274f6e0a090d3069f868`）。
Neo Geo CD用`bios/neocd`はフォルダ単位で追加転送し、source/readback hashを一致させた。

提供セットに次は存在しなかった。

- Channel F: `sl31253.bin`、`sl31254.bin`、`sl90025.bin`
- Palm OS BIOS
- ECWolf: `ecwolf.pk3`
- VMU: `.VMI`に対応する`.VMS` payload
- CPS1 clone `varthj.zip`のparent `varth.zip`
- CPS2 clone `ssf2tu.zip`のparent `ssf2t.zip`

## Bubble parity and fixes

BubbleのRGB565、PicoArch byte order、RetroArch ALSA resume、NES audio pacing、
PCSX SDL、aspect/rotationの履歴をmini PLUS sourceと照合した。対象patchは移植済みだったが、
次のmini PLUS側の漏れを修正した。

1. GB palette
   - Gambatte、Gearboy、VBA-Mをneutral grayscaleへ統一した。
   - VBA-Mは`vbam_palettes = black and white`に加え、DMG ROMをGBC modeへ上げないよう
     `vbam_gbHardware = gb`を設定した。
   - RetroArch/PicoArchともprofile未作成時だけseedし、既存ユーザー設定は保持する。
   - 90-frame実機captureは
     `artifacts/device-validation/2026-10-21-mini-plus-gb-color/vbam-gb-hardware.png`
     （SHA-256 `8f3dd4a4077765f68ef5a038e3d567420611594504321f1e90fac862ff209748`）。
     目視で緑かぶりのない白黒表示を確認した。GB 8 route、GBC 8 routeの表示/PCMも通過した。
2. PicoArch config safety
   - config bufferのNUL終端、bounded parse、NULL default bindを修正した。
3. Game Gear後のaspect汚染
   - 通常Game Gear起動からcustom viewportを除き、診断用`integer3x`だけに限定した。
   - 診断用append configは`config_save_on_exit = false`とし、後続routeへ4:3設定を保存しない。
4. display verifier
   - DRM logの`aspect`は既にcore rotation適用後であるため、検証器の二重反転を除去した。
   - 正しい縦`360x480`を合格、誤った`640x480` stretchを不合格にする回帰testを追加した。
5. blueMSX / ColecoVision
   - MSXは不完全なSD2 `Machines/Databases`よりmanaged C-BIOSを優先し、blueMSX/fMSXとも合格した。
   - ROM2にblueMSX用Coleco machine BIOSがないため、ColecoVision既定routeを、提供される
     `fbneo/coleco.zip`を使うFBNeoへ置換した。DRM、PCM進行、4:3 viewportを実機確認した。
6. forced-timeout cleanup
   - matrixがDraSticを強制終了した場合も、7つのnested bind mountを全層解除するようにした。
   - 残留していた二重mountを解除後、package側`drastic.cf2`は配布hashへ復帰した。

## Device matrix result

全件report:

- `artifacts/device-validation/2026-10-21-mini-plus-rom2-full-matrix.json`
- SHA-256 `55d0714d38a8b632219d44a0c56f6b01c699e94e52de191b31630a219fab5a50`
- 初回値: 164 started、10 failed、22 not run

補正再試験:

- `artifacts/device-validation/2026-10-21-mini-plus-rom2-targeted-rerun.json`
  - SHA-256 `0c834654c500afd4888e1d760b5efdd4a61e8b2add9e27e541cd4db114744eaa`
- `artifacts/device-validation/2026-10-21-mini-plus-rom2-coleco-cps3-rerun.json`
  - SHA-256 `6595c9736444f493420d51003f4943a62dfac553f86efd131afe24487a76a704`

初回のSSH瞬断、NeoCD BIOS未転送、CPS3の早すぎる所有者sample、MSX system directory、
Coleco routeを補正した実効集計は次の通り。

| Result | Routes | Evidence |
| --- | ---: | --- |
| started | 170 | DRM ownerまたはroute固有renderer ownerを確認 |
| PCM running/progress | 166 | ALSA PCM ownerとprogressを複数sampleで確認 |
| started, PCM prepared only | 4 | 2048、Atari800、J2ME、TI83。ALSA初期化/openは確認、観測窓内に音声生成なし |
| failed | 2 | CPS1/CPS2 specialized FBA route。上記parent archive不足 |
| not run | 24 | 20 contentなし、NGP破損archive、external PortMaster、Channel F BIOS不足、VMU VMS不足 |

PSP、PSX 3 route、OpenBOR、N64、NDS、Dreamcast、Saturn、Pyxelは、それぞれ必要な
DRM/KMS/Mali contractとPCM進行を通過した。全started routeでsoftware GL強制は検出されなかった。

補正report 2本に対するdisplay contractは33 observed、33 pass、9 vertical pass。
Game Gearの後にGame & Watch、縦Arcade、J2MEを起動しても、縦viewportは中央配置を維持した。

## Managed deployment

変更はFE停止中にstaging hashを確認して原子的に切り替え、component checksumと
全12,480 fileのglobal checksumを通した。ユーザーconfigは配布・復元対象に含めていない。

- display/blueMSX launcher rollback:
  `/storage/plumos/state/app-deploy/20261021-display-bluemsx/rollback.tar`
  - SHA-256 `29cec2e1f0975d1ea7b563bc54f9f457c8761d8e0c0f6c4944019d15bb1008d8`
- Coleco catalog rollback:
  `/storage/plumos/state/app-deploy/20261021-colecovision-fbneo/rollback.tar`
  - SHA-256 `2933b273a2e242cf601ddaf3844a22580dce47f7515b9161175e16c196439a94`

最終global checksum file SHA-256は
`c5b9360f4ebe131e79613092fb68a4676e70db63a4e56a408fadd219d4724383`。
更新後にfrontend processが1個だけ復帰したことを確認した。

NES audible-audio correctionは同じmanaged deployment規則で追加配備した。ゲームの通常終了後、
FEとforeground runtimeが停止し、画面device ownerが残っていない状態で、音声初期化script、
frontend component metadata、global checksumを原子的に切り替えた。frontend 227 file、global
12,480 fileのchecksumは全件合格した。RK817経路を明示的に`OFF`へ戻した後、新しい
`plumos-audio-output prepare`が`hardware_route=spk-hp-from-off`を記録し、control readbackが
`SPK_HP`となることを確認した。hold解除後はFE 1 processだけが復帰し、PCMはclosedだった。

- RK817 route rollback:
  `/storage/plumos/state/app-deploy/20261021-rk817-route/rollback.tar`
  - SHA-256 `041133ae45d40fa1594ff6980cdf932284311fe420446e25c1d67628602a15dc`
- 更新後global checksum file SHA-256:
  `5703edaa439031d0d2456adaa7528ea4d877383db7958e584a736160430a81de`

## NES audible-audio correction

同日の通常FE導線からQuickNESで`Akumajou Densetsu.nes`を実行中、ユーザーが無音を報告した。
RetroArch PID 1277はALSA PCMを`RUNNING`で所有し、`hw_ptr`/`appl_ptr`は継続して進行、
softvolは論理volume 14を反映していた。一方、RK817の`Playback Path`は`OFF`だった。

経路を`SPK`へ変更しても無音だった。debugfsでcodecを確認すると、digital mute解除、
speaker control GPIO、PCM進行はいずれも成立していた。stockOSの設定とdriverが公開する経路を
照合し、`OFF`から`SPK_HP`へ変更したところ、同じゲーム、同じRetroArch processのまま
ユーザーが可聴音を確認した。したがってNES coreやPCM生成ではなく、mini PLUS固有の
RK817 playback route初期化漏れが原因だった。

`plumos-audio-output prepare`は以後、`Playback Path` controlが存在する場合に限り、
`OFF`または実機で無音だった`SPK`を`SPK_HP`へ補正する。既存の`HP`/`SPK_HP`経路は保持し、
controlがない機種では変更しない。疑似mixer testでOFF、SPK、HP、SPK_HPの4状態を検証した。
今回の可聴確認では出力endpointをspeaker/headphone別には記録していないため、jack切替を含む
個別acceptanceは未完了のままとする。

## Remaining physical acceptance

- speaker/headphoneでの可聴音質、左右、音量、mute、jack切替
- 各routeの実ゲーム操作、Fn/menu、終了復帰
- Atari800/J2ME/TI83で実際に発音する場面まで進めたPCM progress
- 不足BIOS/content/parent archiveを補った24 not-run + 2 failed route
- 電源断状態でのSD2 FAT検査とreadback

これらは自動DRM/PCM/loader検査では代替できないため、release acceptanceは未完了とする。
