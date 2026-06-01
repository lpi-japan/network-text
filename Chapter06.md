# ネットワークインターフェースとは
ネットワークインターフェースは、Linuxが動作するハードウェアに備えられているネットワーク機能を指します。有線LANや無線LAN、オンボードに増設カード、USB接続など様々な種類があります。

## オンボード
ハードウェアの中心であるマザーボード上に最初から備えられているネットワークインターフェース。

## ネットワークカード（NIC）
ハードウェアのPCI（Peripheral Component Interconnect）拡張スロットに挿すボード形状のネットワークインターフェース。この形式が最も一般的なため、形式に関係なくネットワークインターフェース全般をNIC（Network Interface Card）と呼ぶことがある。

## USB接続
オンボードもPCI拡張スロットも無い場合、USB接続のネットワークインターフェースが使用できます。

## 無線LAN
Linuxでは無線LAN（Wi-Fi）も使用できます。

本教科書では仮想マシンで用意された仮想ネットワークインターフェースのため種別はありません。

# インターフェース名
ネットワークインターフェースは、命名規則に従ってインターフェース名がつけられています。

## インターフェース名の命名規則
実習環境で使用しているネットワークインターフェースを例に、命名規則を確認してみましょう。

まず、Linux起動時のログをdmesgコマンドで確認し、ネットワークインターフェースの情報を確認します。

```
$ sudo dmesg | grep enp
[    1.496721] e1000 0000:00:09.0 enp0s9: renamed from eth1
[    1.545818] e1000 0000:00:08.0 enp0s8: renamed from eth0
[   13.769478] e1000: enp0s9 NIC Link is Up 1000 Mbps Full Duplex, Flow Control: RX
[   13.769757] e1000: enp0s8 NIC Link is Up 1000 Mbps Full Duplex, Flow Control: RX
```

### インターフェース名の数値の意味
e1000はカーネルモジュールとして読み込まれたネットワークインターフェース用のデバイスドライバーです。その後ろがPCIデバイスとしての番号です。頭についている0000:は無視して、00:09.0の部分だけを参照します。それぞれの意味は以下の通りです。

| 値 | 意味 |
| - | - |
| 00 | PCIバス番号 |
| 09 | デバイス番号（スロット番号） |
| 0 | ファンクション番号 |

これらのうち、バス番号（PCIのp）とスロット番号（Slotのs）がインターフェース名に使用されます。ファンクション番号は使用されません。

従来、一番最後に書かれているeth0やeth1のように認識された順番にインターフェース名がつけられていましたが、新たにネットワークインターフェースが追加されると順番が変わってしまいました。そこでハードウェア的な接続位置によってインターフェース名が設定されるようになりました。ただし、PCIスロットの位置を変えるとインターフェース名も変わり、それまでとの設定との整合性が取れなくなるので注意が必要です。

### インターフェース種別とインターフェース名
また、先頭についているenはイーサネット（EtherNet）から取られています。インターフェースの種別によって、以下のような名称が使われます。

| 記号 | 種類 |
| - | - |
| en | 有線イーサネット |
| wl | 無線LAN（Wi-Fi） |
| ww | WWAN（LTE/5Gなど） |

# インターフェースの詳細情報
使用できる状態のネットワークインターフェースは、ethtoolコマンドを実行することでカーネルモジュールなどの詳細情報を確認できます。

```
$ ethtool -i enp0s9

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
```

# ボンディングによるネットワーク冗長化
Linuxでサーバーを動作させていると、ネットワーク障害が発生するとサーバーに接続できなくなります。このような状態を「ネットワークが単一障害点」と言います。単一障害点はSPOF（Single Point of Failure）とも呼びます。

ネットワークをSPOFにしないために、ネットワークインターフェースを複数用意し、ボンディングすることでネットワークを冗長化してSPOFを解消できます。

## ボンディングの種類
ネットワークのボンディングには、その動作によっていくつかの種類があります。

| | 名称 | 負荷分散 | スイッチ対応 |
| - | - | - | - |
| 0 | balance-rr | ○ | 要 |
| 1 | active-backup | × | 不要 |
| 2 | balance-xor | ○ | 要 |
| 3 | broadcast | × | 要 |
| 4 | 802.3ad | ○ | 要 |
| 5 | balance-tlb | ○ | 不要 |
| 6 | balance-alb | ○ | 不要 |

## ボンディングの準備
ボンディングを行うためのネットワークインターフェースを仮想マシンに追加します。

仮想マシンをシャットダウン
仮想マシンの設定
ネットワークアダプター3、4を有効化
ホストオンリーネットワークに接続させること
ホストオンリーネットワークでDHCPサーバーを有効にしておくこと

## ボンディングの設定
仮想マシンに追加した2つのネットワークアダプターを使って、ボンディングを設定します。

### ボンディングデバイスの作成
まず最初にボンディングデバイスbond0を作成します。ボンディングモードはスイッチ側の設定が不要なbalance-tlbを指定します。

```
sudo nmcli connection add type bond con-name bond0 ifname bond0 bond.options "mode=balance-tlb"
```

### ネットワークインターフェースの確認
作成したボンディングデバイスおよび、仮想マシンに追加したネットワークインターフェースを確認します。確認には、nmcli device statusコマンド、およびnmcli conn showコマンドを実行します。

```
$ nmcli device status
DEVICE   TYPE      STATE                     CONNECTION
enp0s3   ethernet  接続済み                  enp0s3
enp0s8   ethernet  接続済み                  enp0s8
bond0    bond      接続中 (IP 設定を取得中)  bond0
lo       loopback  接続済み (外部)           lo
enp0s10  ethernet  切断済み                  --
enp0s9   ethernet  切断済み                  --
```

ボンディングデバイスと、追加した2つのネットワークインターフェースが確認できます。

```
$ nmcli conn show
NAME    UUID                                  TYPE      DEVICE
enp0s8  725e8ccb-77e5-3a8e-bbd9-70006c3f9aa6  ethernet  enp0s8
bond0   814fb650-f893-416c-ab07-dd7163c7f243  bond      bond0
lo      52c64e67-1cdb-42bb-9f59-fbdfea9be626  loopback  lo
enp0s3  e7bd8ac8-837b-34b2-930a-011778319496  ethernet  --
```

追加したネットワークインターフェースはまだどこにも接続されていない状態です。

### デバイスの追加
2つのネットワークインターフェースをボンディングデバイスに接続します。

```
$ udo nmcli conn add type ethernet slave-type bond con-name bond0-1 ifname enp0s9 master bond0
$ sudo nmcli conn add type ethernet slave-type bond con-name bond0-2 ifname enp0s10 master bond0
```

### ボンディングデバイスの有効化
ボンディングデバイスを有効にします。

sudo nmcli conn up bond0

### ボンディングデバイスの確認
ボンディングデバイスの状態を確認します。

```
$ nmcli dev status
```

```
$ nmcli conn show
```

### ボンディングデバイスの自動構成
ここまでの作業では手動でネットワークインターフェースをボンディングデバイスに接続しましたが、再起動をすると接続は行われません。自動的に接続が行われるようにボンディングデバイスのパラメータconnection.autoconnect-slavesの設定値を1（有効）に変更します。

```
sudo nmcli conn modify bond0 connection.autoconnect-slaves 1
```

一度ボンディングデバイスを無効化し、再度有効化してネットワークインターフェースがボンディングデバイスに自動接続することを確認します。

```
sudo nmcli conn down bond0
sudo nmcli conn up bond0
```

ボンディングデバイスの状態はprocファイルで確認することもできます。

```
$ cat /proc/net/bonding/bond0
```

## ボンディングの動作確認
作成したボンディングデバイスの動作を確認します。

まず、ボンディングデバイスに割り当てられたIPアドレスを確認します。

ip a

ホストからボンディングデバイスのIPアドレスに対して接続します。

ping xxx

ボンディングデバイスに接続された2つのネットワークインターフェースのうち、片方を無効化します。疑似的にネットワークインターフェース、あるいは接続されているスイッチのポートに障害が発生した状態にします。VirtualBoxでネットワークアダプター4を無効化します。

ボンディングデバイスの状態を確認します。

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

この状態で再度ボンディングデバイスのIPアドレスに接続できることを確認します。

# ブリッジ

# VLAN

