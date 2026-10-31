# plumOS mini PLUS v0.1.0 publication record

Date: 2026-10-31 (Asia/Tokyo). 日本語は下段。

Published as a normal Latest release (not draft/prerelease):
[plumOS mini PLUS v0.1.0](https://github.com/game-de-it/plumOS-mini-PLUS/releases/tag/v0.1.0).
Repository: game-de-it/plumOS-mini-PLUS, public. Release source: 6764cd8.
Image build source: 03ebcb4; later commits describe packaging/publication scope.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Raw SD image | 2902458368 | 69e2ba6c909f7cfc93054338fe6c62f2b3bad16c6ff63344cfcb6fb5ea76cc69 |
| plumos-mini-plus-v0.1.0-sd-image.7z | 488720714 | 895514934b304645589b33b7b6b15d44313dbb9066bec2fff8f262b271befbb0 |
| plumos-mini-plus-v0.1.0-licenses.zip | 1011263 | d89e7942d0de180e64511802cb9272a6eaf273620f1374d48427f4d5a07a8796 |

Completed: full build; 114/114 core loads; 97 catalog entries / 196 routes;
image partition/filesystem/boot readback; managed checksums; first-boot and
progress fixtures; Runtime signature/downgrade/rollback tests; System A/B
inactive-readback/health/failure recovery tests; archive test and extracted raw
hash equality; 214 original license notices with bilingual index; all 10 public
assets downloaded without authentication and matched against local SHA-256/size.
GitHub recognizes the root license as MIT. Git history scan found no private-key
material; a literal detector pattern was distinguished from an actual key.

The user's publication request is recorded in
[the hash-bound publication manifest](0.1.0-mini-plus-publication.env).
Existing device results refer to the development card. Write/readback and three
cold boots of the newly generated exact image have not been repeated. This
publication does not mark those physical gates passed. The 26 route-validation
limits remain documented. Release notes disclose both scopes.

## 日本語

v0.1.0を通常のLatest releaseとして公開し、全10添付を公開URLから認証なしで読み直して
SHA-256・サイズ一致を確認しました。raw imageを新規生成し、114 core load、97 entry・196経路、
partition/filesystem/boot、全管理checksum、初回準備/進捗fixture、Runtime更新・System A/B復旧、
7z検査・展開後raw hash一致を確認しています。

plumOSはMIT、他componentは個別条件を保持します。214件の原文と日英索引をライセンスZIPに含め、
GitHubのMIT表示も確認しました。Git履歴に秘密鍵実体の検出はありません。

公開は利用者の依頼に基づく検証制限付きです。新規生成した同一imageの実カード書込み・読戻し・
cold boot 3回は未再試験で、開発カードの実機結果とは区別しています。物理gateを合格へ変更せず、
未検証26経路の制限も保持しています。SDイメージの新たな実機合格や全ゲーム互換を主張しません。
