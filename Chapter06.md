# ネットワークインターフェースとは
ネットワークインターフェースは、Linuxが動作するハードウェアに備えられているネットワーク機能を指します。接続方式として有線LANや無線LAN、物理的な形状としてオンボードにネットワークカード、USB接続など、様々な種類があります。

## オンボード
ハードウェアの中心基盤であるマザーボード上に最初から備えられているネットワークインターフェース。

## ネットワークカード（NIC）
ハードウェアのPCI（Peripheral Component Interconnect）拡張スロットに挿すボード形状のネットワークインターフェース。この形式が最も一般的なため、形式に関係なくネットワークインターフェース全般をNIC（Network Interface Card）と呼ぶことがある。

## USB接続
オンボードもPCI拡張スロットも無い場合、USB接続のネットワークインターフェースが使用できます。

## 無線LAN
Linuxでは無線LAN（Wi-Fi）も使用できます。有線LAN同様、オンボードやUSB接続など、様々な種類があります。

## 実習環境のネットワークインターフェース
実習環境は仮想マシンで用意された仮想ネットワークインターフェースです。ゲストOSのLinuxでは、PCIに接続された有線LANのネットワークカードとして扱われています。

# インターフェース名の命名規則
ネットワークインターフェースは、命名規則に従ってインターフェース名がつけられています。

実習環境で使用しているネットワークインターフェースを例に、命名規則を確認してみましょう。

まず、Linux起動時のログをdmesgコマンドで確認し、ネットワークインターフェースの情報を確認します。

$ sudo dmesg | grep enp
[    1.496721] e1000 0000:00:09.0 enp0s9: renamed from eth1
[    1.545818] e1000 0000:00:08.0 enp0s8: renamed from eth0
[   13.769478] e1000: enp0s9 NIC Link is Up 1000 Mbps Full Duplex, Flow Control: RX
[   13.769757] e1000: enp0s8 NIC Link is Up 1000 Mbps Full Duplex, Flow Control: RX

## インターフェース名の意味
e1000はカーネルモジュールとして読み込まれたネットワークインターフェース用のデバイスドライバーです。その後ろがPCIデバイスとしての番号です。頭についている0000:は無視して、00:09.0の部分だけを参照します。それぞれの意味は以下の通りです。

| 値 | 意味 |
| - | - |
| 00 | PCIバス番号 |
| 09 | デバイス番号（スロット番号） |
| 0 | ファンクション番号 |

これらのうち、バス番号（PCIのp）とスロット番号（Slotのs）がインターフェース名に使用されます。ファンクション番号は使用されません。

従来、一番最後に書かれているeth0やeth1のように認識された順番にインターフェース名がつけられていましたが、新たにネットワークインターフェースが追加されると順番が変わってしまいました。そこでハードウェア的な接続位置によってインターフェース名が設定されるようになりました。ただし、PCIスロットの位置を変えるとインターフェース名も変わり、それまでの設定との整合性が取れなくなるので注意が必要です。

### インターフェース種別とインターフェース名
また、先頭についているenはイーサネット（EtherNet）から取られています。インターフェースの種別によって、以下のような名称が使われます。

| 記号 | 種類 |
| - | - |
| en | 有線イーサネット |
| wl | 無線LAN（Wi-Fi） |
| ww | WWAN（LTE/5Gなど） |

# インターフェースの詳細情報
使用できる状態のネットワークインターフェースは、ethtoolコマンドを実行することでカーネルモジュールなどの詳細情報を確認できます。

$ ethtool -i enp0s9
driver: e1000
version: 5.14.0-611.49.2.el9_7.aarch64
firmware-version:
expansion-rom-version:
bus-info: 0000:00:09.0
supports-statistics: yes
supports-test: yes
supports-eeprom-access: yes
supports-register-dump: yes
supports-priv-flags: no

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

### 負荷分散
冗長化した複数のネットワークインターフェースを使って、ネットワークの帯域を増やして、より沢山の通信が行えるようにします。

### スイッチ対応
ネットワークインターフェースが接続されているスイッチ側に設定が必要です。ボンディングの種類によって、LAGやLACPなど設定が異なります。

# ボンディングの準備
ボンディングを行うためのネットワークインターフェースを仮想マシンに追加します。

1. 仮想マシンをシャットダウンします。
2. Oracle VirtualBox マネージャーで仮想マシンの設定を呼び出します。
3. ネットワークアダプター3を有効化します。
4. ホストオンリーネットワークに割り当てます。
5. ネットワークアダプター4を有効化します。
6. ホストオンリーネットワークに割り当てます。
7. 仮想マシンを起動します。
8. 追加した2つのネットワークインターフェースが認識されていることを確認します。

ip a
（略）
4: enp0s10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:1e:cc:4d brd ff:ff:ff:ff:ff:ff
5: enp0s11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:06:64:53 brd ff:ff:ff:ff:ff:ff

# ボンディングの設定
仮想マシンに追加した2つのネットワークアダプターを使って、ボンディングを設定します。

### ボンディングデバイスの作成
まず最初にボンディングデバイスbond0を作成します。ボンディングモードはスイッチ側の設定が不要なbalance-tlbを指定します。

sudo nmcli connection add type bond con-name bond0 ifname bond0 bond.options "mode=balance-tlb"
接続 'bond0' (18203844-95a2-422b-8b97-d60fef859f9a) が正常に追加されました。

## ネットワークインターフェースの確認
作成したボンディングデバイスおよび、仮想マシンに追加したネットワークインターフェースを確認します。確認には、nmcli device statusコマンド、およびnmcli conn showコマンドを実行します。

$ nmcli device status
DEVICE   TYPE      STATE                     CONNECTION
enp0s8   ethernet  接続済み                  enp0s8
enp0s9   ethernet  接続済み                  enp0s9
bond0    bond      接続中 (IP 設定を取得中)  bond0
lo       loopback  接続済み (外部)           lo
enp0s10  ethernet  切断済み                  --
enp0s11  ethernet  切断済み                  --

ボンディングデバイスと、追加した2つのネットワークインターフェースが確認できます。

$ nmcli conn show
NAME    UUID                                  TYPE      DEVICE
enp0s8  7923bf5f-a529-3b97-929c-989c7cbdb251  ethernet  enp0s8
enp0s9  427178ab-8dc1-4a5f-9291-e03412917c39  ethernet  enp0s9
bond0   18203844-95a2-422b-8b97-d60fef859f9a  bond      bond0
lo      cc0aaf70-128d-49f9-9814-affa4f920e3c  loopback  lo

追加したネットワークインターフェースは、まだ接続されていない状態です。

## デバイスの追加
2つのネットワークインターフェースをボンディングデバイスに接続します。

$ sudo nmcli conn add type ethernet slave-type bond con-name bond0-1 ifname enp0s10 master bond0
接続 'bond0-1' (4f78bed6-bf01-4c54-bee3-6bc6b782857f) が正常に追加されました。
$ sudo nmcli conn add type ethernet slave-type bond con-name bond0-2 ifname enp0s11 master bond0
接続 'bond0-2' (fc537992-53b3-4550-901d-4688f71bfa1b) が正常に追加されました。

## ボンディングデバイスの有効化
ボンディングデバイスを有効にします。

sudo nmcli conn up bond0
接続が正常にアクティベートされました (controller waiting for ports) (D-Bus アクティブパス: /org/freedesktop/NetworkManager/ActiveConnection/6)

## ボンディングデバイスの確認
ボンディングデバイスの状態を確認します。

$ nmcli dev status
DEVICE   TYPE      STATE            CONNECTION
enp0s8   ethernet  接続済み         enp0s8
bond0    bond      接続済み         bond0
enp0s9   ethernet  接続済み         enp0s9
enp0s10  ethernet  接続済み         bond0-2
lo       loopback  接続済み (外部)  lo
enp0s11  ethernet  切断済み         --

$ nmcli conn show
NAME     UUID                                  TYPE      DEVICE
enp0s8   22a592c6-1384-3371-879d-17d61b718739  ethernet  enp0s8
bond0    08baa02c-5629-45c5-93bb-963789a9b14f  bond      bond0
enp0s9   9aff7784-e7e1-3812-8492-de165c7d5817  ethernet  enp0s9
bond0-1  c234b6f4-32e5-44cc-a56c-5758b03f24c2  ethernet  enp0s10
bond0-2  c4d930e7-67c5-47c2-9c77-d920f189af1a  ethernet  enp0s11
lo       cb9cdcc0-16eb-449c-a046-46a828efe57f  loopback  lo


## ボンディングデバイスの自動構成
ここまでの作業では手動でネットワークインターフェースをボンディングデバイスに接続しましたが、再起動をすると接続は行われません。自動的に接続が行われるようにボンディングデバイスのパラメータconnection.autoconnect-slavesの設定値を1（有効）に変更します。

sudo nmcli conn modify bond0 connection.autoconnect-slaves 1

一度ボンディングデバイスを無効化し、再度有効化してネットワークインターフェースがボンディングデバイスに自動接続することを確認します。

sudo nmcli conn down bond0
sudo nmcli conn up bond0

ボンディングデバイスの状態はprocファイルで確認することもできます。

$ cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v5.14.0-687.15.1.el9_8.aarch64

Bonding Mode: transmit load balancing
Primary Slave: None
Currently Active Slave: enp0s10
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

Slave Interface: enp0s10
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:1e:cc:4d
Slave queue ID: 0

Slave Interface: enp0s11
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:06:64:53
Slave queue ID: 0

## ボンディングの動作確認
作成したボンディングデバイスの動作を確認します。

まず、ボンディングデバイスに割り当てられたIPアドレスを確認します。

ip a
（略）
7: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:0a:4a:1d brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.106/24 brd 192.168.56.255 scope global dynamic noprefixroute bond0
       valid_lft 3591sec preferred_lft 3591sec
    inet6 fe80::2530:71d1:b0fc:16de/64 scope link noprefixroute
       valid_lft forever preferred_lft forever

ホストOSからボンディングデバイスのIPアドレスに対してsshコマンドでリモートログインを実行してみます。

ssh linuc@192.168.56.106

初めての接続の場合、接続するまでに少し時間がかかる場合があります。

### 最初のpingは通らない？
VirtualBoxで検証していたところ、初めてアクセスする場合はpingコマンドでの応答は行われませんでした。Wiresharkで確認したところ、初めての通信の際にはEthernetのレベルでボンディングデバイスをすぐに見つけられなかったのが理由な様です。この処理にはARP（Address Resolution Protocol）というプロトコルが使われています。

同様の理由で、sshコマンドによる接続も少し待たされるようです。一度接続すれば、pingコマンドにも応答するようになります。

## ボンディングデバイスの冗長化テストを行う
ボンディングデバイスに接続された2つのネットワークインターフェースのうち、片方を無効化します。疑似的にネットワークインターフェース、あるいは接続されているスイッチのポートに障害が発生した状態にします。

VirtualBoxでネットワークアダプター4を無効化します。仮想マシンのウインドウの右下にあるネットワークアイコン（左から4番目）をクリックして「Connect Network Adapter 4」のチェックを外します。仮想マシンの設定画面から、ネットワークアダプター4の「仮想ケーブル接続」のチェックを外しても同様です。

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

片方のネットワークインターフェースのMII Statusがdownになっているのがわかります。

この状態で再度ボンディングデバイスのIPアドレスに接続できることを確認します。

