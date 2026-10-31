# アプリ統合

[English](apps.md) | [開発者ガイド](README.ja.md)

[利用者アプリガイド](../user/apps.ja.md)に表示9項目と終了方法をまとめています。apps.jsonには内部補助actionもあり、全entryを独立メニューとして案内しません。

File Manager・Music Player・Pyxel・PortMaster・GGFEは正規FE launcherを使います。描画所有者を一つにし、子processを正常終了します。PortMaster更新・ダウンロード・導入状態は利用者の可変データであり、Runtime組立てで上書きしません。

GGFEは通常Galleryとは別です。SELECT設定メニューにExitがあり、B/STARTはカルーセル終了ではありません。Apotrisはbuild限定の互換ガードで、PortMaster全体runtimeの置換ではありません。

Repair SD2はSD2を識別・実行確認・安全なmount解放を行い、SYSを対象にしません。修復・filesystem試験はfixtureか明示許可された予備カードで実施します。
