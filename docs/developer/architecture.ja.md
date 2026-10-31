# 構成と所有権

[English](architecture.md) | [開発者ガイド](README.ja.md)

mini PLUSのstock由来prefix・kernel・DTBと外部initramfsから起動します。Systemはread-only SquashFS、書込み可能な管理Runtimeは/storage/plumosです。SoCが同じでもBubbleのbootファイルで代用しません。

| partition | 役割 |
| --- | --- |
| p1、FAT32 512MiB | /flash。System A/Bとboot payload。通常read-only |
| p2、raw 64MiB | matching boot bundle |
| p3、ext4実測seed | /storage。初回起動で8GiBへ拡張 |
| p4、残りのFAT32 | /storage/user。初回起動で作成 |

所有境界は[ストレージと更新](storage-and-updates.ja.md)、build成功と独立した受入条件は[実装チェックリスト](../plumos-implementation-checklist.ja.md)を参照してください。
