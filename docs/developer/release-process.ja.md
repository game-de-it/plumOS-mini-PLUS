# リリース工程

[English](release-process.md) | [開発者ガイド](README.ja.md)

v0.1.0は下記の制限付き経路で公開済みで、同一imageの物理受入は未完了です。ドキュメント更新だけで稼働中の開発SDや旧imageをrelease扱いにしません。

PLUMOS_MINI_PLUS_RELEASE_DRAFT=1 scripts/prepare-mini-plus-release.shで、実機受入manifestなしのhost検証済み-draft bundleを作成できます。manifestに実機未受入を明記し、GitHub下書きだけに使用します。受入済みreleaseとして公開しません。通常modeは同一image hash・書込み読戻し・cold boot 3回・maintainer承認を要求します。image manifestにはversion keyがないため、verifierで読戻したRuntime VERSIONとSystem os-releaseで版を確認します。

1. source revisionと承認済み外部入力を固定し、full raw imageを再生成する。
2. image verifier・content/license/secret audit・component/global checksumを通す。
3. filename・byte size・SHA-256を記録し、そのimageを新SDへ書込み・読戻しする。
4. 初回進捗・cold boot 3回・warm reboot・Wi-Fi/service・SD1/SD2・入力・speaker/headphone可聴音・代表runtime・保存読込・電源・USBあり/なしSleepを記録する。
5. 更新rollback・復旧の証拠を試験対象boot契約へ結び付ける。
6. exact-image受入後にチェックサム・NOTICEを整備する。圧縮を行う場合は展開後raw hash一致も確認する。
7. 明示的な公開承認後、byteを変えず公開し、匿名downloadで公開hashを再確認する。

利用者の指示により開発imageは非圧縮のままで構いません。writer完了・host test合格・別imageでの成功は実機受入の代わりにはなりません。[チェックリスト](../plumos-implementation-checklist.ja.md)と[検証](validation.ja.md)を参照してください。

正式版はVERSIONの0.1.0です。[リリースノート](../releases/0.1.0.md)は日英併記です。scripts/prepare-mini-plus-release.shも同版を既定にし、Bubble形式の配布名を使います。同一imageの受入とimage/Runtime版の一致を要求します。検証済みimage読戻しからライセンス原文をlicenses/へ取り出し、日英索引を付けます。plumOS MITのLICENSE・THIRD_PARTY_NOTICES.md・個別原文をbundle checksumに含めます。

制限付き公開は別経路です。PLUMOS_MINI_PLUS_RELEASE_RECORDED_LIMITS=1では、利用者の公開依頼を記録したhash付きpublication-with-recorded-limits manifestを要求し、new_image_device_acceptance=no・physical_cold_boots=not-recordedを明記します。実機合格を作成したり該当checklistを完了にしたりしません。詳細な検証状態は公開manifestと開発者向け検証記録へ保持します。利用者向けrelease noteはSD imageの取得・書込み・起動の案内に絞ります。この経路を明示しない場合は従来の厳格な受入gateを維持します。
