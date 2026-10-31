# Runtime・Systemの更新

[English](updates.md) | [マニュアル](README.ja.md)

1. 署名付きの**mini PLUS用**RuntimeまたはSystemパッケージとチェックサムを入手します。
2. ハッシュを確認し、重要なセーブ・設定をバックアップします。
3. SD1のPCから見えるPLUMOS内`updates/`へコピーします。ネットワーク経由では`/storage/user/updates/`（共有からは`user/updates/`）です。
4. `START → System Settings → System Update`を選びます。互換パッケージの選択・検証後、通常の安全な再起動を要求します。
5. 電源を接続し、書込み中はカードを抜かず電源を切らないでください。
6. 再起動後、バージョン・FE・Wi-Fi・ゲーム・セーブを確認します。

署名・機種・更新元バージョン・ABIの一致が必要です。同じ版や古い版への更新は拒否されます。

Runtimeはアプリ・core等の管理ファイルをジャーナル付きで更新し、起動確認に失敗した場合は旧Runtimeを復元します。Systemは非使用A/B面へ書込み・読戻しし、FEが正常起動すると確定します。試行起動に失敗した場合は後続の起動で正常面へ戻ります。

System更新には`p1-slot-policy-trial-v1`対応bootが必要です。kernel・DTB・initramfs・p2 matching bundleは**更新しません**。旧boot構成には互換性のあるSD全体イメージが必要です。

どちらも利用者のROM・BIOS・セーブ・ステート・設定・PortMasterダウンロードを保持します。SDイメージの再書込みはカードを消去する新規インストールです。詳細は[開発者向け更新仕様](../plumos-mini-plus-runtime-update.ja.md)を参照してください。
