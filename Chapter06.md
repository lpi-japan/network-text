# ネットワークインターフェースとは

# インターフェース名

## インターフェース名の命名規則
[    3.391150] e1000 0000:00:08.0 enp0s8: renamed from eth1
[    3.402524] e1000 0000:00:03.0 enp0s3: renamed from eth0

00:08.0

00はバス番号
08はデバイス番号（スロット番号）
0はファンクション番号

enはイーサネット（EtherNet）

# カーネルモジュール
$ ethtool -i enp0s3
driver: e1000
version: 5.14.0-611.36.1.el9_7.x86_64
firmware-version:
expansion-rom-version:
bus-info: 0000:00:03.0
supports-statistics: yes
supports-test: yes
supports-eeprom-access: yes
supports-register-dump: yes
supports-priv-flags: no

# ボンディング
sudo nmcli connection add type bond con-name bond0 ifname bond0 bond.options "mode=balance-tlb"

$ nmcli device status
DEVICE   TYPE      STATE                     CONNECTION
enp0s3   ethernet  接続済み                  enp0s3
enp0s8   ethernet  接続済み                  enp0s8
bond0    bond      接続中 (IP 設定を取得中)  bond0
lo       loopback  接続済み (外部)           lo
enp0s10  ethernet  切断済み                  --
enp0s9   ethernet  切断済み                  --

nmcli conn show
NAME    UUID                                  TYPE      DEVICE
enp0s8  725e8ccb-77e5-3a8e-bbd9-70006c3f9aa6  ethernet  enp0s8
bond0   814fb650-f893-416c-ab07-dd7163c7f243  bond      bond0
lo      52c64e67-1cdb-42bb-9f59-fbdfea9be626  loopback  lo
enp0s3  e7bd8ac8-837b-34b2-930a-011778319496  ethernet  --

sudo nmcli conn add type ethernet slave-type bond con-name bond0-1 ifname enp0s9 master bond0
sudo nmcli conn add type ethernet slave-type bond con-name bond0-2 ifname enp0s10 master bond0

sudo nmcli conn up bond0

nmcli conn show
nmcli dev status


sudo nmcli conn modify bond0 connection.autoconnect-slaves 1

sudo nmcli conn down bond0
sudo nmcli conn up bond0

$ cat /proc/net/bonding/bond0

# ボンディングの削除
sudo nmcli conn down bond0

sudo nmcli conn del bond0-1
sudo nmcli conn del bond0-2

sudo nmcli conn del bond0

nmcli conn show
nmcli dev status

## 動作確認
ネットワークアダプター4を無効化

$ cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v5.14.0-611.36.1.el9_7.x86_64

Bonding Mode: transmit load balancing
Primary Slave: None
Currently Active Slave: enp0s9
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

Slave Interface: enp0s10
MII Status: down
Speed: Unknown
Duplex: Unknown
Link Failure Count: 1
Permanent HW addr: 08:00:27:6e:4c:c5
Slave queue ID: 0

Slave Interface: enp0s9
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:6c:00:8a
Slave queue ID: 0


WebブラウザでWebサーバーにアクセス

# ブリッジ

# VLAN

