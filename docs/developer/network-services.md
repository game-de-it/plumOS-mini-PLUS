# Network services

[日本語](network-services.ja.md) | [Developer guide](README.md)

Wi-Fi uses the live-stock-verified SDIO 02D0:A9A6 bcmdhd matching set, BCM43438A1 firmware and AP6212A NVRAM. Verify module/kernel ABI and normal load; do not restore the old RTL8821CS force-load route.

plumos-network-control and plumos-network-services own Wi-Fi and listener lifecycle. SSH is enabled by default; SFTP/FTP/Samba have separate opt-in settings. Host keys are generated on-device. No Wi-Fi credentials or private host keys belong in images.

The shared root is /storage, not just /storage/user. SD2 absence must not prevent SFTP. See [user ports, credentials and paths](../user/network.md).

Test scan/connect, DHCP, reconnect, each service's enable/disable, authentication and transfer/readback separately. Keep recovery shell exposure distinct from successful frontend startup. USB has no ADB/data path in this port.
