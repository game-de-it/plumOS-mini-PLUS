# リリース工程

[English](release-process.md) | [開発者ガイド](README.ja.md)

最終リリース準備は未完了です。ドキュメント更新だけで稼働中の開発SDや旧imageをrelease扱いにしません。

1. source revisionと承認済み外部入力を固定し、full raw imageを再生成する。
2. image verifier・content/license/secret audit・component/global checksumを通す。
3. filename・byte size・SHA-256を記録し、そのimageを新SDへ書込み・読戻しする。
4. 初回進捗・cold boot 3回・warm reboot・Wi-Fi/service・SD1/SD2・入力・speaker/headphone可聴音・代表runtime・保存読込・電源・USBあり/なしSleepを記録する。
5. 更新rollback・復旧の証拠を試験対象boot契約へ結び付ける。
6. exact-image受入後にチェックサム・NOTICEを整備する。圧縮を行う場合は展開後raw hash一致も確認する。
7. 明示的な公開承認後、byteを変えず公開し、匿名downloadで公開hashを再確認する。

利用者の指示により開発imageは非圧縮のままで構いません。writer完了・host test合格・別imageでの成功は実機受入の代わりにはなりません。[チェックリスト](../plumos-implementation-checklist.ja.md)と[検証](validation.ja.md)を参照してください。
