# mini PLUS runtimeの検証範囲と既知の制限

全97 system・196起動経路・package済み114 coreを保持したまま、ROM2での監査結果を整理した。
`configs/mini-plus-runtime-validation.json`が全経路の機械可読な台帳であり、
`summarize-mini-plus-runtime-validation.py --verify`で現在のcatalogと双方向に照合できる。
利用可能なROM/BIOSの不足はruntime自体の未対応判定ではない。

| 分類 | 経路数 | 内容 |
|---|---:|---|
| 起動を機械確認 | 170 | うち166経路でPCM進行を確認。全ゲームの目視・可聴音・操作の一括合格ではない |
| 親archive不足 | 2 | CPS1 `fbalpha2012_cps1`、CPS2 `fbalpha2012_cps2`。子ROMだけでは起動不可 |
| BIOS不足 | 1 | Channel F / freechaf。`sl31253.bin`、`sl31254.bin`、`sl90025.bin`が不足 |
| 対応content不足 | 20 | WonderSwan Color、X68000、TIC-80、Vectrex、BK、Daphne、Flashback、Palm、Rick Dangerous、SG-1000の4経路、Sharp X1、Wolf3D、ZX81、Arduboy、Mega Duck、PuzzleScript、Super Bros War |
| NGP content不成立 | 1 | SD2 archive読込み失敗と、互換性のある単色NGP content不足 |
| VMU content不成立 | 1 | metadataに対応するVMS payloadが不足 |
| 外部portの別試験 | 1 | PortMasterは共通の有限時間emu harness対象外。Apotrisは互換ガード付きv4.1.0で別途実機合格。全portの合格を意味しない |

未検証26経路もFEとcatalogから削除していない。追加試験には台帳の理由に対応する
互換content/BIOS/親archiveを利用者が用意する必要がある。ROMや利用者BIOSを配布物へ追加しない。
この台帳の整備で移植監査の追跡は完了するが、content不足の経路を実機合格へ変更してはいない。
