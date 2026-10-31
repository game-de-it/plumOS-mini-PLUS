# ストレージと更新境界

[English](storage-and-updates.md) | [開発者ガイド](README.ja.md)

[構成](architecture.ja.md)はboot/System・管理Runtime・FAT利用者領域を分離します。SD2はdisk番号固定ではなくidentityで解決します。不在・dirty・未対応SD2でSD1起動を止めません。

SD2ルートroms/<system>とbiosが有効ROM/BIOS aliasを置換し、設定・セーブはSD1に残ります。[利用者パス](../user/storage.ja.md)と[共有ルート](../user/network.ja.md)を参照してください。初回拡張・利用者partition作成の前にintentを記録し、中断後も再開可能にします。

Runtime更新は署名manifest・staging・journal・renderer health、System更新は非使用面readback・pending/healthy・trial rollbackを使います。kernel・DTB・initramfs・p2はmatching full-image境界です。[更新仕様](../plumos-mini-plus-runtime-update.ja.md)を参照してください。

電源断前にwriterを停止し、書込み領域をunmountまたはread-onlyにします。mount中のfilesystemを修復しないでください。writer停止・read-only化に失敗したまま通常再起動を強行しません。
