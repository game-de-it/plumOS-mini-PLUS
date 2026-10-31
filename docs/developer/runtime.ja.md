# Runtimeと実機配備

[English](runtime.md) | [開発者ガイド](README.ja.md)

package/frontend-mini-plus/はapp-layer overlayと初期設定を供給し、scripts/build-mini-plus-app-layer.shがRuntime組立てとVERSIONを所有します。使用中設定・セーブ・導入portは利用者所有です。

/storage/plumosの実機変更は、対象管理ファイルと対応component metadata・manifest.json・checksums.sha256のentryを同じ整合した配備単位に含めます。実機baselineを保持し、対象の管理entryだけを更新してください。利用者が変更した設定やPortMasterをホスト全体metadataで上書きしません。

BusyBoxではcp・chmod・atomic mvを使います。再起動前に配備SHA-256とapp-layer checksumを確認します。不一致はbootstrap拒否につながります。復旧可能なbackupを残し、構造変更には[署名付き更新](../plumos-mini-plus-runtime-update.ja.md)を優先してください。

書込み中のcomponentを更新せず、正規FE lifecycleと電源・更新のquiesce経路を使います。
