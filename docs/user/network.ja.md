# Wi-Fi・ファイル転送

[English](network.md) | [マニュアル](README.ja.md)

`START → Network Settings`でWi-Fiを有効にし、Connect Wi-FiでSSIDを選んでパスワードを入力します。接続後のIPはINFORMATIONで確認します。保存済みの接続先には自動再接続します。

**SSHとSFTPはサービスの有効化設定が別です。** `START → Network Settings → NW Service`で利用するサービスをONにしてください。SSHが接続できてもSFTPが有効とは限りません。SFTP・FTP・Sambaは利用前に有効にします。

| サービス | 接続先・ポート | ユーザー / パスワード |
| --- | --- | --- |
| SSH | 本体IP、22 | root / plumos |
| SFTP | 本体IP、22 | root / plumos |
| FTP | 本体IP、21 | anonymous / パスワードなし |
| Samba | `\\\\<IP>\\SDCARD` | plumos / plumos |

信頼できないネットワークで利用する前に初期パスワードを変更してください。USBは充電専用のため、転送にはWi-Fiを使います。

## 転送先

SFTPの開始位置は`/storage`です。FTPとSDCARD共有も`/storage`を公開し、利用者領域と本体管理領域の両方が含まれます。

- 例：`Roms/nes/`は**現在有効な**ROM領域です。SD2装着時はSD2、それ以外はSD1です。
- `BIOS/`も有効なカードを参照します。
- `user/Roms/`・`user/BIOS/`を指定するとSD1へ転送できます。
- `plumos/saves/`・`plumos/states/`・`plumos/config/`・`plumos/logs/`はSD1の本体管理領域です。
- 更新パッケージは`user/updates/`へ置きます。

SD2なしでもSFTPとSD1のゲームを利用できます。転送後は一覧を更新してください。大容量転送が中断した場合はサイズやハッシュを確認します。接続できないときはサービスのON/OFF、現在のIP、同一LAN、クライアントのファイアウォールを先に確認してください。SD2の取り外し前に[ストレージ](storage.ja.md)も参照してください。
