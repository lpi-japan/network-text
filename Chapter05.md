# ルーティングとIPマスカレード
ルーティングは、インターネットの基本的な仕組みであるネットワーク間を接続するための仕組みです。遠く離れたネットワーク同士が通信できるのは、ルーティングによってパケットがルーターを経由して適切に転送されるためです。

IPマスカレードは、ローカルネットワークからグローバルネットワークにパケットを送り出す際にアドレスを変換するLinuxの仕組みです。別々のネットワークを接続する実習として、IPマスカレードの設定を解説します。


### IPマスカレードによるアドレス変換
アドレス変換は、パケットのIPアドレスやポート番号を書き換えて通信を行う仕組みです。

グローバルIPアドレスが枯渇しているため、すべてのノードに対してグローバルIPアドレスを割り当てることは困難です。そこで、1つのグローバルIPアドレスを複数のプライベートIPアドレスで共有する仕組みとしてアドレス変換が使われています。

# ルーティング
外部ネットワークとのやり取りを行う仕組みとして、ルーティングもあります。

ルーティングは、送信側が接続されているネットワークと異なるネットワークにIP通信を行う仕組みです。ルーターがルーティングを行いますが、受信側のネットワークが離れている場合、複数のルーターを介してルーティングが行われる場合もあります。

### ルーター
ルーターは、第2章で解説したように異なるネットワークとの間でIP通信を行うための機器です。

Linuxを使ってルーターを構成することもできます。販売されている家庭用のインターネット接続用のルーターには、内部的にLinuxを組み込んでいるものも多く存在しています。

ルーターの設定や、複数のルーターを介したルーティングなどは本教科書の想定範囲を越えるため説明は省略しますが、ネットワークについてより深く理解したい場合には学習してみてください。

### ルーターとL3スイッチの違い
ネットワーク機器にL3スイッチと呼ばれるものがあります。一般的なネットワークスイッチはL2スイッチ、すなわちイーサネットのレイヤーでスイッチングを行いますが、L3スイッチはIPのレイヤーでスイッチングを行います。L3スイッチに接続されているネットワーク同士をIPで接続するので、ルーターの一種といえます。オフィスなどで複数のIPネットワークに分割されているネットワークを相互に接続する場合などにL3スイッチは利用されます。

ルーターは主に外部と接続する機器、L3スイッチはLANの内部で接続する機器と考えておけばよいでしょう。

## アドレス変換
ルーティングはパケットを書き換えずにそのまま送信していくのに対して、アドレス変換はパケットの書き換えを伴う通信方法です。アドレス変換にもいくつかの方式があるので、それぞれの特長を解説します。

### NAT
NAT（Network Address Translation）は、IPアドレスのみを書き換えるアドレス変換方式です。送信元のIPアドレスと書き換え後のIPアドレスが1対1で対応するので、複数のノードからの送信書き換えには対応できません。

### NAPT
NAPT（Network Address Port Translation）は、IPアドレスとポート番号の両方を書き換えるアドレス変換方式です。ポート番号を含めることによって、複数のノードからの送信パケットを書き換えることができます。一般的なインターネットに接続するためのルーターは、インターネットプロバイダーから与えられた1個のグローバルIPアドレスを複数のノードで共用するためにNAPTによるアドレス変換を行っています。

NAPTはアドレス変換したIPアドレスとポート番号の組み合わせをすべて記録しておき、受信側からの応答パケットを逆方向に書き戻す必要があるので、沢山の通信が行われる場合には変換テーブルが溢れてしまって処理可能な量を超えてしまい、通信が行えなくなる場合があります。

### ポートフォワーディング
NATやNAPTは、LANからインターネットに出て行く場合のアドレス変換ですが、外部のインターネット側から内側のLANに入ってくる場合のアドレス変換がポートフォワーディングです。

ルーターに与えられたグローバルIPアドレスの特定のポートに外部からアクセスがあった場合、内部の特定のIPアドレスとポート番号に対するパケットとして書き換えを行い、転送する仕組みです。

VirtualBoxでは、「NATネットワーク」を構成することでポートフォワーディングを設定し、外部からのパケットを仮想マシンに転送することができます。

また、コンテナを外部ネットワークからアクセスできるようにする仕組みとしてもポートフォワーディングは利用されています。

## IPマスカレードの設定
IPマスカレードは、LinuxでNAPTを行うnftablesの機能です。NAPTの動作を確認するために、IPマスカレードを設定し、動作させてみましょう。

### システムの構成
クライアント用仮想マシンを別途作成し、実習用の仮想マシンのIPマスカレードを経由してインターネットに接続させます。

実習用の仮想マシンはVirtualBoxのNATを経由して、さらにルーターのNAPTを経由してインターネットに接続しているので、多段のアドレス変換を行っていることになります。

※図を入れる

### ネットワークインターフェースを確認する
2つあるネットワークインターフェースがそれぞれネットワークの外側、内側のいずれに接続されているかを確認します。

```
$ ip a
（略）
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:91:bb:d1 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
（略）
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:f5:15:7b brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.101/24 brd 192.168.56.255 scope global dynamic noprefixroute enp0s8（略）
```

IPアドレスから、enp0s3がネットワークの外側（NAT）、enp0s8が内側（ホストオンリーネットワーク）に接続されていることが確認できます。

### ゾーンの確認
firewalldのゾーンとしてあらかじめ設定されているものを確認します。

```
$ firewall-cmd --get-zones
block dmz drop external home internal nm-shared public trusted work
```

ネットワークの外側としてexternalゾーン、内側としてinternalゾーンを使用することにします。

### 現在のゾーンの状態を確認
現在のゾーンの状態を確認します。

```
$ firewall-cmd --get-active-zone
public
  interfaces: enp0s3 enp0s8
```

デフォルトゾーンであるpublicゾーンのみが使用されており、2つのネットワークインターフェースがpublicゾーンに接続されています。

### ネットワークインターフェースの接続ゾーンの変更
2つのネットワークインターフェースをそれぞれexternalゾーンとinternalゾーンに接続します。設定の変更にはnmcliコマンドを使用します。

```
$ sudo nmcli connection modify enp0s3 connection.zone external
$ sudo nmcli connection modify enp0s8 connection.zone internal
```

ゾーンの状態を確認します。

```
$ firewall-cmd --get-active-zone
external
  interfaces: enp0s3
internal
  interfaces: enp0s8
```

各ネットワークインターフェースの接続ゾーンが変更されたことが確認できます。

### IPマスカレードの設定を確認
IPマスカレードが設定されていることを確認します。

まずexternalゾーンの設定を確認します。

```
$ sudo firewall-cmd --list-all --zone=external
external (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3
  sources:
  services: ssh
  ports:
  protocols:
  forward: yes
  masquerade: yes
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

externalゾーンは、forwardがyesになっているので、他のインターフェースとの間でのパケット転送が行われます。そして、masqueradeがyesになっているので、IPマスカレードでパケットの書き換えが行われます。

internalゾーンの設定も確認します。

```
$ sudo firewall-cmd --list-all --zone=internal
internal (active)
  target: ACCEPT
  icmp-block-inversion: no
  interfaces: enp0s8
  sources:
  services: cockpit dhcpv6-client mdns samba-client ssh
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

internalゾーンも、forwardがyesになっているので、他のインターフェースとの間でのパケット転送が行われます。しかし、masqueradeがnoになっているので、IPマスカレードでパケットの書き換えは行われません。

### internalゾーンのターゲットをACCEPTに変更する
デフォルトではinternalゾーンのターゲットがdefaultになっているため、クライアントから送られてきた転送すべきパケットをすべて落としてしまいます。internalゾーンのターゲットをACCEPTに変更します。

```
$ sudo firewall-cmd --zone=internal --set-target=ACCEPT --permanent
```

設定後--reloadオプションで読み込み直します。

```
$ sudo firewall-cmd --reload
```

targetの設定が変更されたことを確認します。

```
$ sudo firewall-cmd --zone=internal --list-all
internal (active)
  target: ACCEPT
（略）
```

internalゾーンのtargetがACCEPTになっていることが確認できます。

## IPマスカレードの動作の確認
クライアント用仮想マシンを用意して、IPマスカレードの動作を確認します。

### クライアント用仮想マシンを準備する
VirtualBoxでクライアント用の仮想マシンを作成し、AlmaLinuxをインストールします。

実習用仮想マシンとクライアント用仮想マシンは、ホストオンリーネットワークで接続します。クライアント用仮想マシンにはNATによるインターネット接続は必要ありませんので、デフォルトで設定されたネットワークアダプター1を「NAT」から「ホストオンリーネットワーク」に変更します。

### クライアント仮想マシンの参照DNSとデフォルトゲートウェイを変更する
クライアント用の仮想マシンに、参照DNSとデフォルトゲートウェイを設定します。

IPアドレスは、VirtualBoxのホストオンリーネットワークに接続されているDHCPサーバーが自動的に設定してくれていますが、参照DNSとデフォルトゲートウェイは設定されていません。

参照DNSは、Google社がインターネット上に用意しているPublic DNSの「8.8.8.8」を指定します。

デフォルトゲートウェイは、実習用仮想マシンのホストオンリーネットワークに接続されているネットワークインターフェースのIPアドレスを調べて設定します。ここでは「192.168.56.101」を設定します。

GUIのネットワーク設定から、ネットワークインターフェースのIPv4設定を呼び出します。

「DNS」の「自動」のチェックを外し、テキストボックスに参照するDNSのIPアドレスを入力します。

「ルート」の「自動」のチェックを外し、テキストボックスにゲートウェイのIPアドレスを入力します。

| 設定項目 | 意味 | 設定値 |
| --- | --- | --- |
| アドレス | ルーティング先のネットワークアドレス | 0.0.0.0 |
| ネットマスク | ルーティング先のネットマスク（省略可能） | 省略 |
| ゲートウェイ | ルーターのIPアドレス | 192.168.56.101 |
| メトリック | 優先順位（省略可能） | 省略 |

アドレスはすべてを表す「0.0.0.0」、ゲートウェイはIPマスカレードを設定した仮想マシンのホストオンリーネットワークに接続されているIPアドレス「192.168.56.101」を指定します。

設定を行ったら、「適用」ボタンをクリックします。

設定をネットワークインターフェースに適用するためには、歯車ボタンの左にあるスイッチをクリックして一旦ネットワークインターフェースを無効にし、再度スイッチをクリックして有効にする必要があります。

### 設定の確認
正しく設定が行われたか、確認します。

GUIでも確認できますが、コマンドでも確認してみます。

※SS

名前解決の設定は、/etc/resolv.confに記述されます。

```
$ cat /etc/resolv.conf
# Generated by NetworkManager
nameserver 8.8.8.8
```

デフォルトゲートウェイの設定は、ip routeコマンドで確認します。

```
$ ip route
default via 192.168.56.101 dev enp0s3 proto static metric 100
192.168.56.0/24 dev enp0s3 proto kernel scope link src 192.168.56.102 metric 100
```

設定したアドレス「0.0.0.0」は、ルーティングテーブルではdefaultとして扱われます。

## 名前会越できることを確認
クライアント用仮想マシンで、名前解決やWebサーバーへのアクセスができることを確認します。

```
$ dig linuc.org

; <<>> DiG 9.16.23-RH <<>> linuc.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 34053
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 4, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;linuc.org.			IN	A

;; ANSWER SECTION:
linuc.org.		3600	IN	A	219.94.236.161

;; AUTHORITY SECTION:
linuc.org.		73654	IN	NS	02.dnsv.jp.
linuc.org.		73654	IN	NS	03.dnsv.jp.
linuc.org.		73654	IN	NS	04.dnsv.jp.
linuc.org.		73654	IN	NS	01.dnsv.jp.

;; Query time: 15 msec
;; SERVER: 192.168.11.1#53(192.168.11.1)
;; WHEN: Mon Jul 06 18:36:02 JST 2026
;; MSG SIZE  rcvd: 129
```

### Webサーバーに接続できることを確認
HTTPでもアクセスしてみます。

```
$ curl linuc.org
<html>
<head><title>302 Found</title></head>
<body>
<center><h1>302 Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

HTTPのため、正しくページが表示されていない旨のメッセージが返って来ていますが、きちんとインターネット上のWebサーバーと通信が行えていることがわかります。

クライアント用仮想マシンでWebブラウザを起動して、いろいろなサイトにアクセスしてみてください。

## WiresharkでIPマスカレードを見てみる
IPマスカレードでパケットの書き換えが起きていることを確認します。

Wiresharkを起動し、enp0s3とenp0s8の両方のネットワークインターフェースのパケットをキャプチャしてみます。複数のネットワークインターフェースを選択するには、Ctrlキーを押しながらネットワークインターフェースを選択します。

キャプチャした状態でdigコマンドで名前解決を行い、パケットが書き換えられる様子を確認してみます。絞り込み条件で「dns」を設定すると、名前解決のパケットのみが表示されます。

※SS

実行例では、4つのパケットがキャプチャされています。非常に高速な処理な為、Timeの表示が丸められてしまっていますが、リスト表示のTimeをクリックすると時間順にソート表示されます。そして順番に送信元が書き換えられ、戻って来たパケットの返信先が書き換えられているのがわかります。

## IPマスカレードを解除する
IPマスカレードを解除するには、ネットワークインターフェースをpublicゾーンに接続します。

```
$ sudo nmcli connection modify enp0s3 connection.zone public
$ sudo nmcli connection modify enp0s8 connection.zone public
```

インターフェーズの接続がpublicゾーンに戻ったことを確認します。

```
$ firewall-cmd --get-active-zone
public
  interfaces: enp0s3 enp0s8
```

internalゾーンのtargetもdefaultに戻しておきます。

```
$ sudo firewall-cmd --zone=internal --set-target=default --permanent
```

設定後、firewall-cmd --reloadコマンドで読み込み直します。

```
$ sudo firewall-cmd --reload
```

internalゾーンの設定を確認します。

```
$ sudo firewall-cmd --list-all --zone=internal
internal
  target: default
  icmp-block-inversion: no
  interfaces:
（略）
```

targetがdefaultに戻っていることが確認できます。

## プロキシーの設定
プロキシーは、特定の通信プロトコルを中継する仕組みです。主にWebアクセスで利用されており、アクセスログを取得したり、許可されてないWebサイトへのアクセスを禁止したりすることに使われています。

AlmaLinuxではSquidを使うことでプロキシーを実行できます。

### Squidのインストール
dnfコマンドでSquidをインストールします。

```
$ sudo dnf install squid
```

### Squidの起動
Squidを起動します。また、システム起動時に自動的に起動するように設定します。

```
$ sudo systemctl start squid
$ sudo systemctl enable squid
Created symlink /etc/systemd/system/multi-user.target.wants/squid.service → /usr/lib/systemd/system/squid.service.
```

### ポートの待ち受け状況の確認
ポートの待ち受け状況を確認します。

```
$ sudo lsof -i -P | grep squid
squid     25084  squid    7u  IPv6  62718      0t0  UDP *:45065
squid     25084  squid    8u  IPv4  62719      0t0  UDP *:33449
squid     25084  squid   11u  IPv6  63515      0t0  TCP *:3128 (LISTEN)
```

TCPのポート番号3128で待ち受けています。UDPのポートがあるのは、プロキシーが名前解決を行うための処理をポート固定で行っているためです。

## クライアントのプロキシ設定
クライアントのプロキシ設定は、GUIの設定アプリで設定可能です。

「設定」アプリを起動して「ネットワーク」を選択します。「ネットワーク」プロキシの歯車ボタンをクリックします。

「ネットワークプロキシ」ダイアログが表示されるので「手動」を選択し、「HTTPプロキシ」「HTTPSプロキシ」を設定します。IPアドレスはSquidをインストールした実習用仮想マシンのホストオンリーネットワークに接続されたIPアドレス「192.168.56.101」、ポート番号は3128番をそれぞれ設定します。ダイアログ右上の「X」をクリックして、ダイアログを閉じます。

プロキシの設定は環境変数として設定されるので、「端末」を起動し、envコマンドで確認します。環境変数「NO_PROXY」、「HTTPS_PROXY」、「HTTP_PROXY」が設定されていることを確認します。環境変数が設定されていない場合、一度「端末」を終了して、再度「端末」を起動してみてください。

```
$ env | sort
（略）
HTTPS_PROXY=http://192.168.56.101:3128/
HTTP_PROXY=http://192.168.56.101:3128/
（略）
NO_PROXY=localhost,127.0.0.0/8,::1
（略）
http_proxy=http://192.168.56.101:3128/
https_proxy=http://192.168.56.101:3128/
no_proxy=localhost,127.0.0.0/8,::1
（略）
```

## プロキシ経由でアクセスする
準備ができたら、クライアントからプロキシ経由でインターネットのWebサーバーにアクセスします。

### Squidのアクセスログ確認
Squidがプロキシとして動作していることを確認するために、Squidのアクセスログを表示します。

```
$ sudo tail -f /var/log/squid/access.log
```

### プロキシ経由でWebサーバーにアクセス
クライアントでWebブラウザからインターネット上のサイトにアクセスします。

以下のようなログが表示されたら、プロキシが機能していることが確認できます。

```
1783427785.546   6790 192.168.56.102 TCP_TUNNEL/200 15772 CONNECT linuc.org:443 - HIER_DIRECT/219.94.236.161 -
```






