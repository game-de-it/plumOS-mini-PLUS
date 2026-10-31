# 手動配備と復旧

[English](manual-updates.md) | [開発者ガイド](README.ja.md)

通常は[署名付きRuntime/System更新](../plumos-mini-plus-runtime-update.ja.md)を優先します。手動コピーは開発者向け復旧・配備操作であり、利用者の更新手順ではありません。

媒体変更前に対象カード・deviceを特定し、boot state・active/inactive System・設定・セーブをbackupします。使用中のactive Systemファイルを上書きせず、mount中のFATを修復しません。破壊的実機試験には範囲を限定した許可が必要です。

管理app-layerの差分は[Runtime配備](runtime.ja.md)に従い、実機利用者状態を保持して対応metadataをatomic更新します。ホストmetadata全体のrsyncで導入portや設定を上書きしません。

boot/kernel/DTB/initramfsの変更は検証済みmatching full-imageと予備カードを使います。復旧成功と最終配布imageは別gateです。hashと実際に通った経路を記録してください。
