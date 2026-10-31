# plumOS mini PLUS Runtime・System更新仕様

[English](plumos-mini-plus-runtime-update.md) | [開発者ガイド](developer/README.ja.md)

START → System Settings → System Updateは署名付きRuntime・Systemに対応します。canonical META/manifest.jsonのEd25519署名、payload hash、機種・architecture・vendor-runtime・ABIを確認します。比較可能なSemVerが必要で、同じ版・古い版は拒否します。inboxは/storage/user/updates、targetはgkd-mini-plus・aarch64・mini-plus-stockos-r1です。

## パッケージ生成

Runtime入力はVERSIONが更新先版と一致する組立て済みplumos directoryです。差分には旧Runtimeを--base-dirで渡し、full payloadでは省略します。

```sh
python3 scripts/build-mini-plus-update-package.py \
  --type runtime --input /path/to/new/plumos \
  --base-dir /path/to/previous/plumos \
  --version <new-version> --base-version <installed-version> \
  --signing-key /secure/path/private-key.pem
```

System入力はSquashFSファイルです。

```sh
python3 scripts/build-mini-plus-update-package.py \
  --type system --input /path/to/SYSTEM \
  --version <new-version> --base-version <installed-version> \
  --signing-key /secure/path/private-key.pem
```

出力はdist/plumos-mini-plus-{runtime|system}-<version>.tar.gzとSHA-256 sidecarです。秘密鍵をsource・image・archiveへ入れません。通常FE経路は未署名の開発packageを拒否します。

## Runtime transaction

通常FE起動前にrequest/packageを再検証し、全payloadをstaging・hash確認、操作全体をjournal化します。旧管理fileを/storage/plumos/backups/update-previousへ保持し、metadataを最後にatomic置換します。renderer-readyの証拠で起動正常を確定します。中断・不健康起動は変更・削除fileの復元と新規fileの除去で回復します。

対象は実行file・core・theme・font・静的catalog・初期設定です。使用中の設定・save・state・log・ROM・BIOS・Wi-Fi資格情報・鍵・導入port・PortMaster導入状態は利用者所有です。

## System A/B transaction

対応boot契約はp1-slot-policy-trial-v1です。非使用p1 System面へ書込み、全readback確認後pending trialを記録します。次回起動で試行し、FE健康確認で確定します。失敗trialは後続起動でrollbackし、active面破損も正常面で回復できます。

System packageはread-only SquashFSだけを交換します。bootloader/prefix・kernel・DTB・overlay・外部initramfs・p2 matching bundleは交換しません。これらの変更はmatching full SD imageで行います。互換性のない旧bootはSystem更新を拒否します。

## 電源と証拠

FEは互換packageを選択・検証して通常の安全な再起動を呼びます。writer停止・read-only化失敗後に再起動を強行しません。使用中active Systemを上書きしません。

Runtime・Systemの実機復旧証拠は[リリース前作業](validation/2026-10-31-mini-plus-pre-release-work.md)にあります。開発カードの復旧試験合格を新規release imageの受入へ継承しません。[release gate](developer/release-process.ja.md)と[利用者更新手順](user/updates.ja.md)も参照してください。
