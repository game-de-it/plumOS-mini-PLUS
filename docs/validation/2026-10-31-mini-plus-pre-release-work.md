# 最終リリース準備を除く残作業の実施結果

対象日: 2026-10-31。実機: `192.168.10.141`。
ユーザーは現在の実機SDを破損試験に使ってよいと明示した。

## 完了した作業

| 作業 | 結果 |
|---|---|
| 機種説明 | stick無し・FN4個へ修正。報告ABS軸/L3/R3は互換aliasとして数値mappingを保持 |
| 検証記録・gate | 完了済みHW/ネットワークgateを整理し、TODO監査はopen 1件、最終リリース受入のみ |
| runtimeの範囲 | 全196経路を台帳化、170経路の起動証拠と26経路の未検証理由を明示。core/profileを削減しない |
| SD readback | 可変MBRを除くprefix、旧p2のraw一致、p1全512 MiB比較と予定24 fileの一致。Mac metadata等の差分を特定 |
| SFTP転送 | SD1上の専用temporary file 65,536 bytesを往復しbyte一致、試験file削除 |
| Runtime更新 | 実機installed updaterの隔離試験で署名不正拒否、正常確定、2回rollback、downgrade拒否、利用者設定保持 |
| System更新・復旧 | 不足していた機能を実装。実機で正常B面更新、未健康A面trialからB面rollback、非使用面破損時の起動、active checksum破損時のA面復旧を確認 |
| 最終整合 | 管理12,483 fileのstaged checksum検証、元System image/設定の保持、FAT検査errorなし、通常FE復帰 |

## System A/Bの補完

以前の実装は2面の配置とhash検証だけで、どちらか片面の破損でも起動できなかった。
署名付き`system` packageは未使用面へ書き、全file readback後にpendingを公開する。
active面はFE readinessまで変更しない。initramfsは一度だけtrialを試し、次のbootまで
健康確定がなければ以前の正常面へ戻る。未健康trialのimageを自動fallback先に再利用しない。
実際にbootした面とactive metadataが不一致の間は更新を拒否し、使用中のimageを保護する。

更新対象はSquashFS Systemのみ。kernel/DTB/initramfs/p2は通常System packageから分離する。
旧initramfsにはcapabilityがないためSystem packageを拒否する。共通`System Update`項目は保持した。

## 実機試験と復元処理の修正

最初の実機試験では4つの更新・復旧動作は成功したが、試験cleanupが使用中のSystem fileを
同内容のbackupで置換してしまい、loop backing fileが`(deleted)`となりFATのRO remountに失敗した。
これは試験スクリプトの不備であり、未使用面だけを書き換える本来の更新処理とは別の問題だった。

cleanupは同内容のfileを触らず、使用中の異なるimageはその面を離れてから復元するよう修正した。
明示的なone-shot kernel引数で、System loopを開く前の未mount FATを検査・修復した。
13,893,632 bytesの孤立chainを回収し、dirty bitを解除した。修復要求は同じbootでuEnvから除去した。
修復helperは明示許可なし・mount中のdeviceを拒否し、通常bootで自動実行しない。

修復後、修正済みスクリプトで全実機試験を再実施し成功した。最後に以下を確認した。

- 元のA/B両imageのSHA-256一致、active `a`、pending無し。
- System backing fileに`(deleted)`無し、`/flash`はRO。
- system/frontend/network設定のhash保持。
- p1全512 MiBのsnapshotを`fsck.fat -vn`で検査しexit 0、孤立cluster・dirty bit・backup差分の指摘なし。

## バージョンとmetadata

app assemblerがキャッシュしたfrontendの`VERSION`をそのまま使っていたため、全体manifestの
`0.1.0-dev-20261031-firstboot`と実際のRuntime `0.1.0-dev`が不一致だった。
共通`VERSION`をRuntime assembler所有へ移し、frontend componentのchecksum対象から外した。
assemble-onlyで再生成し、manifest/VERSION一致、114 core load、97 system/196 route検証を合格した。

実機では既存metadataを基準に変更対象entryだけを更新した。ROM・save・ユーザー設定や
PortMaster更新物を、host側metadataに合わせて上書きしていない。
配備はcomponent manifest/checksumとglobal manifest/checksumを同じ単位に含め、全12,483件を検証した。

## 最終の稼働状態

- Runtime source: `2a91acb`。boot機能source: `aa74f4d`。
- Runtime VERSION: `0.1.0-dev-20261031-firstboot`。
- global checksum file SHA-256: `bcb48aac8d88d34627b5a112f6e03f87732e14733c629b3e8120d3c68d0c40f7`。
- app manifest SHA-256: `1b49591e11b885dc2523e5c052b0938b4581ce78fa63dad9b360769f193b1bd3`。
- kernel: `c18890e0bc6c439095f5a0f97d0d643ee3019cad94eaed8a459c3dc015f48653`。
- initramfs: `1f7c07f8dca1d19f778a6962df309c4de31c0064cf5b5c2a5e18fb0145ac0367`。
- p2 raw: `3a2cd8b5360b575a157708e11479540ae8a728ebb43d6a26ab53a7c78a143d82`。
- 元System A/B: `7dac0f22af72640b8940988ed9537e85598dde7a0b3d9a7fb8429b18eed594e2`へ復元。
- SD1はSDR104、実clock 148.5 MHz。輝度curveも機種専用設定を保持。

証拠は`artifacts/device-validation/2026-10-31-pre-release/`に保存した。
`system-device-summary.json`、`boot-fat-final-fsck.log`、`final-device-state.log`、
`final-managed-deploy-delta.json`、`final-regression.log`を参照する。
退避したbootと利用者設定は同directoryの`original-device/`（private backup）に保持する。

## 最終リリース準備へ残すもの

作業SDは旧full imageへ管理されたboot/app差分を加えた状態であり、以前の未圧縮imgと同一ではない。
以前のimgを今回のSystem A/B対応済み最終配布物として扱わない。
最終imageの再生成、exact-image受入manifest、リリースノート、圧縮・配布・公開は実施していない。
未検証26経路は既知の検証制限として保持し、全経路の物理合格へ読み替えていない。
