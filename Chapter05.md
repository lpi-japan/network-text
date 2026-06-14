# ルーターの役割
ルーターは、第2章で解説したように異なるネットワークとの間でIP通信を行うための機器です。

Linuxを使ってルーターを構成することもできます。販売されている家庭用のインターネット接続用のルーターには、内部的にLinuxを組み込んでいるものも多く存在しています。

外部との通信においてルーターは重要な役割を果たしているので、その役割と仕組みについて解説します。

# ルーティング
ルーティングは、送信側が接続されているネットワークと異なるネットワークにIP通信を行う仕組みです。ルーターがルーティングを行いますが、受信側のネットワークが離れている場合、複数のルーターを介してルーティングが行われる場合もあります。

ルーターの設定や、複数のルーターを介したルーティングなどは本教科書の想定している範疇を越えるため説明は省略しますが、ネットワークについてより深く理解したい場合には学習してみてください。

## L3スイッチとルーターの違い
ネットワーク機器にL3スイッチと呼ばれるものがあります。一般的なネットワークスイッチはL2スイッチ、すなわちイーサネットのレイヤーでスイッチングを行いますが、L3スイッチはIPのレイヤーでスイッチングを行います。L3スイッチに接続されているネットワーク同士をIPで接続するので、ルーターの一種といえます。オフィスなどで複数のIPネットワークに分割されているネットワークを相互に接続する場合などにL3スイッチは利用されます。

ルーターは主に外部と接続する機器、L3スイッチはLANの内部で接続する機器と考えておけばよいでしょう。

# アドレス変換
ルーティングはパケットをそのまま送信していくのに対して、アドレス変換はパケットの書き換えを伴うルーティング方法です。アドレス変換にもいくつかの方式があるので、それぞれの特長を解説します。

## NAT
NAT（Network Address Translation）は、IPアドレスのみを書き換えるアドレス変換方式です。送信元のIPアドレスと書き換え後のIPアドレスが1対1で対応するので、複数のノードからの送信書き換えには対応できません。

## NAPT
NAPT（Network Address Port Translation）は、IPアドレスとポート番号の両方を書き換えるアドレス変換方式です。ポート番号を含めることによって、複数のノードからの送信パケットを書き換えることができます。一般的なインターネットに接続するためのルーターは、インターネットプロバイダーから与えられた1個のグローバルIPアドレスを複数のノードで共用するためにNAPTによるアドレス変換を行っています。

NAPTはアドレス変換したIPアドレスとポート番号の組み合わせをすべて記録しておき、受信側からの応答パケットを逆方向に書き戻す必要があるので、沢山の通信が行われる場合には変換テーブルが溢れてしまったり、処理可能な量を超えてしまい通信が行えなくなってしまう場合があります。

## ポートフォワーディング
NATやNAPTは、LANからインターネットに出て行く場合のアドレス変換ですが、外部のインターネット側から内側のLANに入ってくる場合のアドレス変換がポートフォワーディングです。

ルーターに与えられたグローバルIPアドレスの特定のポートに外部からアクセスがあった場合、内部の特定のIPアドレスとポート番号に対するパケットとして書き換えを行い、転送する仕組みです。

VirtualBoxでは、NATネットワークを構成することでポートフォワーディングを設定し、外部からのパケットを仮想マシンに転送することができます。また、コンテナを外部ネットワークからアクセスできるようにする仕組みとしてもポートフォワーディングは利用されています。

# IPマスカレードの設定
IPマスカレードは、LinuxでNAPTを行うnftablesの機能です。NAPTの動作を確認するために、IPマスカレードを設定し、動作させてみましょう。

## システムの構成
IPマスカレードを行う仮想マシンを別途作成し、実習用の仮想マシンからインターネットに接続する際にIPマスカレードを経由させます。

## クライアント用仮想マシンを準備する
実習用仮想マシンにIPマスカレードを設定し、別途用意したクライアント用仮想マシンからの通信をIPマスカレードでインターネットにNAPTで変換してやり取りを行います。

実習用仮想マシンとクライアント用仮想マシンは、ホストオンリーネットワークで接続します。クライアント用仮想マシンにはNATによるインターネット接続は必要ありませんので、デフォルトで設定されたネットワークアダプター1をNATからホストオンリーネットワークに変更します。

## IPフォワーディングを有効にする
IPマスカレードを動作させるには、ネットワークインターフェースの間でパケットの受け渡しができるIPフォワーディングを有効にする必要があります。

IPフォワーディングの状態を確認します。

$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 0

値は0なので、IPフォワーディングは無効です。

値を1にして、IPフォワーディングを有効にします。

$ sudo sysctl -w net.ipv4.ip_forward=1
net.ipv4.ip_forward = 1
$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1

この設定はシステムを再起動すると再度無効になってしまうので、/etc/sysctl.conf、あるいは/etc/sysctl.d/99-sysctl.confに以下の設定を記述しておきます。

$ sudo vi /etc/sysctl.d/99-sysctl.conf

net.ipv4.ip_forward=1

システムを再起動して、IPフォワーディングが有効になっていることを確認します。

$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1

# IPマスカレードを設定する
IPマスカレードを設定します。

## ネットワークインターフェースを確認する
2つあるネットワークインターフェースがそれぞれネットワークの外側、内側のいずれに接続されているかを確認します。

$ ip a
（略）
2: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:11:34:97 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s8
（略）
3: enp0s9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:bb:3d:03 brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.51/24 brd 192.168.56.255 scope global noprefixroute enp0s9
（略）

IPアドレスから、enp0s8がネットワークの外側（NAT）、enp0s9が内側（ホストオンリーネットワーク）に接続されていることが確認できます。

## ゾーンの確認
firewalldのゾーンとしてあらかじめ設定されているものを確認します。

$ firewall-cmd --get-zones
block dmz drop external home internal nm-shared public trusted work

ネットワークの外側としてexternalゾーン、内側としてinternalゾーンを使用することにします。

## 現在のゾーンの確認
現在のゾーンの状態を確認します。

$ firewall-cmd --get-active-zone
public
  interfaces: enp0s9 enp0s8

デフォルトゾーンであるpublicゾーンのみが使用されており、2つのネットワークインターフェースがpublicゾーンに接続されています。

## ネットワークインターフェースの接続ゾーンの変更
2つのネットワークインターフェースをそれぞれexternalゾーンとinternalゾーンに接続します。設定の変更にはnmcliコマンドを使用します。

sudo nmcli connection modify enp0s8 connection.zone external 
sudo nmcli connection modify enp0s9 connection.zone internal

ゾーンの状態を確認します。

$ firewall-cmd --get-active-zone
external
  interfaces: enp0s8
internal
  interfaces: enp0s9

各ネットワークインターフェースの接続ゾーンが変更されたことが確認できます。

## IPマスカレードを設定する
internalゾーンにIPマスカレードを設定します。設定にはfirewall-cmd --add-masqueradeコマンドを使用します。

$ sudo firewall-cmd --zone=internal --add-masquerade --permanent
success

さらにルールを追加します。


sudo firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -o enp0s8 -j MASQUERADE --permanent
sudo firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i enp0s9 -o enp0s8 -j ACCEPT --permanent
sudo firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i enp0s8 -o enp0s9 -m state --state RELATED,ESTABLISHED -j ACCEPT --permanent


1つ目のルールは、外側のネットワークに出て行く際に、IPアドレスを書き換えるIPマスカレードを実行します。
2つ目のルールは、内側から外側に出るパケットは、すべてACCEPTします。
3つ目のルールは、外側から内側に入るパケットは、外側に出て行ったパケットに関係する（RELATED）か、TCPセッションが確立している（ESTABLISHED）パケットのみACCEPTします。

設定後--reloadオプションで読み込み直します。

$ sudo firewall-cmd --reload

## クライアント仮想マシンの参照DNSとデフォルトゲートウェイを変更する
クライアント用の仮想マシンに、参照DNSとデフォルトゲートウェイを設定します。

IPアドレスは、VirtualBoxのホストオンリーネットワークに接続されているDHCPサーバーが自動的に設定してくれていますが、参照DNSとデフォルトゲートウェイは設定されていません。

GUIのネットワーク設定から、ネットワークインターフェースのIPv4設定を呼び出します。

「DNS」の「自動」のチェックを外し、テキストボックスに参照するDNSのIPアドレスを入力します。

「ルート」の「自動」のチェックを外し、テキストボックスにゲートウェイのIPアドレスを入力します。

アドレス ルーティング先のネットワークアドレス
ネットマスク ルーティング先のネットマスク（省略可能）
ゲートウェイ ルーターのIPアドレス
メトリック 優先順位（省略可能）

アドレスはすべてを表す「0.0.0.0」、ゲートウェイはIPマスカレードを設定した仮想マシンのホストオンリーネットワークに接続されているIPアドレスを指定します。

設定を行ったら、「適用」ボタンをクリックします。

正しく設定が行われたか、確認します。

$ cat /etc/resolv.conf
# Generated by NetworkManager
nameserver 8.8.8.8

$ ip route
default via 192.168.56.101 dev enp0s9 proto static metric 100
192.168.56.0/24 dev enp0s9 proto kernel scope link src 192.168.56.103 metric 100

0.0.0.0はルーティングテーブルではdefaultとして扱われます。

## インターネットに接続できることを確認する
クライアント用仮想マシンで、名前解決やWebサーバーへのアクセスができることを確認します。

$ dig linuc.org

; <<>> DiG 9.16.23-RH <<>> linuc.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 58694
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;linuc.org.			IN	A

;; ANSWER SECTION:
linuc.org.		3600	IN	A	219.94.236.161

;; Query time: 20 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Sun Jun 14 14:26:55 JST 2026
;; MSG SIZE  rcvd: 54

$ curl linuc.org
<html>
<head><title>302 Found</title></head>
<body>
<center><h1>302 Found</h1></center>
<hr><center>nginx</center>
</body>
</html>


## IPマスカレードを解除する

$ sudo nmcli connection modify enp0s8 connection.zone public
$ sudo nmcli connection modify enp0s9 connection.zone public

$ firewall-cmd --get-active-zone
public
  interfaces: enp0s9 enp0s8

sudo firewall-cmd --list-all

sudo firewall-cmd --direct --get-all-rules

# プロキシー
プロキシーは、特定の通信プロトコルを中継する仕組みです。主にWebアクセスで利用されており、アクセスログを取得したり、許可されてないWebサイトへのアクセスを禁止したりすることに使われています。

AlmaLinuxではSquidを使うことでプロキシーを実行できます。

## Squidのインストール
sudo dnf install squid

## Squidの起動
sudo systemctl start squied

sudo systemctl enable squied

## クライアントのプロキシ設定
ネットワークの設定で設定可能

環境変数として設定されるので、確認
env

## Squidのアクセスログ確認

sudo tail -f /var/log/squid/access.log





