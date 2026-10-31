# ネットワークサービス

[English](network-services.md) | [開発者ガイド](README.ja.md)

Wi-Fiはlive stockで確認したSDIO 02D0:A9A6のbcmdhd matching set・BCM43438A1 firmware・AP6212A NVRAMを使います。module/kernel ABI一致と通常loadを確認し、旧RTL8821CS force-loadへ戻しません。

plumos-network-control・plumos-network-servicesがWi-Fiとlistenerを管理します。SSHは既定ON、SFTP/FTP/Sambaは別々に有効化します。host keyは実機生成です。Wi-Fi資格情報や秘密host keyをimageへ含めません。

共有ルートは/storageであり/storage/userだけではありません。SD2不在でSFTPを止めないでください。[利用者向けport・認証・パス](../user/network.ja.md)を参照してください。

scan/connect・DHCP・再接続・各service ON/OFF・認証・転送読戻しを別々に試験します。復旧shell公開とFE正常起動を区別します。このportにUSBのADB/data経路はありません。
