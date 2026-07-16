# パケットフィルタリング
パケットフィルタリングは、IPアドレスやポート番号などを元にパケット通信の許可や拒否を行う仕組みです。

ネットワークのセキュリティを高める目的で、ファイアーウォールとして機能させることが多いので、しっかりとその原理を理解しておきましょう。

## Linuxのパケットフィルタリング機能nftables
Linuxのパケットフィルタリングは、Linuxカーネルの機能であるnftablesとして実装されています。nftablesに関連するカーネルモジュールを読み込ませることで利用できます。

nftablesはカーネルの機能ですが、その設定はコマンドなどで行う必要があります。基本的なツールとしてnftコマンドが用意されていますが、実習環境であるAlmaLinuxではfirewalldがフロントエンドとして採用されています。

### カーネルモジュールの確認
nftables関連のカーネルモジュールが読み込まれているかどうか確認してみましょう。


```
$ lsmod | grep nf
nft_fib_inet           12288  1
nft_fib_ipv4           12288  1 nft_fib_inet
nft_fib_ipv6           12288  1 nft_fib_inet
nft_fib                12288  3 nft_fib_ipv6,nft_fib_ipv4,nft_fib_inet
nft_reject_inet        12288  6
nf_reject_ipv4         16384  1 nft_reject_inet
nf_reject_ipv6         20480  1 nft_reject_inet
nft_reject             12288  1 nft_reject_inet
nft_ct                 24576  7
nft_chain_nat          12288  3
nf_nat                 65536  1 nft_chain_nat
nf_conntrack          225280  2 nf_nat,nft_ct
nf_defrag_ipv6         24576  1 nf_conntrack
nf_defrag_ipv4         12288  1 nf_conntrack
nf_tables             356352  235 nft_ct,nft_reject_inet,nft_fib_ipv6,nft_fib_ipv4,nft_chain_nat,nft_reject,nft_fib,nft_fib_inet
nfnetlink              20480  2 nf_tables
libcrc32c              12288  4 nf_conntrack,nf_nat,nf_tables,xfs
```

nf_tablesがnftablesの本体となるカーネルモジュールです。その他に様々なカーネルモジュールが読み込まれているのがわかります。

## firewalld
nftablesを操作するためのフロントエンドがfirewalldです。firewalldは、デーモンとして動作するサービスです。

### firewalldサービスの確認
firewalldが動作していることを確認しましょう。systemctlコマンドで確認できます。

```
$ sudo systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; preset>
     Active: active (running) since Mon 2026-07-06 14:15:01 JST; 6min ago
       Docs: man:firewalld(1)
   Main PID: 812 (firewalld)
      Tasks: 2 (limit: 10514)
     Memory: 44.3M (peak: 46.3M)
        CPU: 1.158s
     CGroup: /system.slice/firewalld.service
             └─812 /usr/bin/python3 -s /usr/sbin/firewalld --nofork --nopid

 7月 06 14:14:57 localhost systemd[1]: Starting firewalld - dynamic firewall da>
 7月 06 14:15:01 localhost systemd[1]: Started firewalld - dynamic firewall dae>
```

表示から、firewalldの実体はPythonで書かれたプログラムが動作していることが分かります。

### firewall-cmd
デーモンとして動作しているfirewalldに対して、様々な指示を出すのがfirewall-cmdコマンドです。

パケットフィルタリングの設定を変更して、外部からのパケットを受け入れる設定方法は『Linuxサーバー構築標準教科書』で解説していますが、設定の確認について補足として解説しておきます。

## パケットフィルタリングの設定を確認する
現在のfirewalldによるパケットフィルタリングの設定を確認するには、firewall-cmd --list-allコマンドを実行します。

```
$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: cockpit dhcpv6-client ssh
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

servicesで受け入れるパケットをサービス名で定義しています。たとえば、sshが定義されているので、外部からのSSH接続が受け入れられています。

### ゾーン
firewalldはゾーンという考え方でパケットフィルタリングを管理しています。特別な構成と設定が必要でない限り、表示されているpublicゾーンに対して設定を行えば、外部とのパケットのやり取りに対してフィルタが設定されます。

firewall-cmd --get-zonesコマンドで、定義されているゾーンの一覧が確認できます。

```
$ sudo firewall-cmd --get-zones
block dmz drop external home internal nm-shared public trusted work
```

publicの他、様々なゾーンが定義されているのが分かります。

firewall-cmd --get-default-zoneコマンドで、デフォルトに設定されているゾーンが確認できます。

```
$ sudo firewall-cmd --get-default-zone
public
```

publicがデフォルトのゾーンとして定義されています。外部とのパケットのやり取りは、デフォルトでpublicゾーンに入ってきて、定義されているルールによって処理されることになります。

### ターゲット
ターゲットは、そのゾーンに入ったパケットが設定されているルールにマッチしなかった場合、どのような処理を行うのかを定義しています。

ターゲットは以下の種類があります。

- ACCEPT
ルールで拒否されたパケット以外をすべて受け入れます。

- REJECT
ルールで許可されたパケット以外をすべて拒否します。拒否したことを送信元に通知します。

- DROP
ルールで許可されたパケット以外をすべて破棄します。破棄したことを送信元に通知しません。

- default
REJECT同様の振るまいをしますが、いくつかの違いがあります。pingコマンドなどで使われるICMPは通します。

確認した設定ではpublicゾーンのtargetはdefaultは設定されているので、ICMP以外のパケットはservicesなどのルールを設定して許可しない限り拒否されます。

```
$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: cockpit dhcpv6-client ssh
（略）
```

## ターゲットの変更
ターゲットを変更してみましょう。現在のdefaultからREJECT、DROPに変更して動作を確認してみます。

### ターゲットREJECTに設定
ターゲットをREJECTに設定してみます。

```
$ sudo firewall-cmd --zone=public --set-target=REJECT --permanent
```

設定を有効にするには、firewall-cmd --reloadコマンドを実行します。

```
$ sudo firewall-cmd --reload
success
```

設定を確認します。

```
$ sudo firewall-cmd --zone=public --get-target --permanent
REJECT
```

動作を確認するため、ホストOSからpingコマンドを実行します。

```
C:\Users\LinuC>ping 192.168.56.101

192.168.56.101 に ping を送信しています 32 バイトのデータ:
192.168.56.101 からの応答: 宛先ネットワークに到達できません。
192.168.56.101 からの応答: 宛先ネットワークに到達できません。
192.168.56.101 からの応答: 宛先ネットワークに到達できません。

192.168.56.101 の ping 統計:
    パケット数: 送信 = 3、受信 = 3、損失 = 0 (0% の損失)、
Ctrl+C
^C
```

ターゲットをREJECTにすると、nftablesはパケットを拒否したことを通知します。そのため、pingコマンドは拒否されたことを表示します。パケットの拒否の通知もICMPによって行われます。

### ターゲットDROPに設定
ターゲットをDROPに設定してみます。

```
$ sudo firewall-cmd --zone=public --set-target=DROP --permanent
```

設定を有効にするには、firewall-cmd --reloadコマンドを実行します。

```
$ sudo firewall-cmd --reload
success
```

設定を確認します。

```
$ sudo firewall-cmd --zone=public --get-target --permanent
DROP
```

動作を確認するため、ホストOSからpingコマンドを実行します。

```
C:\Users\LinuC>ping 192.168.56.101

192.168.56.101 に ping を送信しています 32 バイトのデータ:
要求がタイムアウトしました。
要求がタイムアウトしました。
要求がタイムアウトしました。
要求がタイムアウトしました。

192.168.56.101 の ping 統計:
    パケット数: 送信 = 4、受信 = 0、損失 = 4 (100% の損失)、
```

ターゲットをDROPにすると、nftablesはパケットを拒否したことを通知しません。そのため、pingコマンドはEcho requestに対するEcho replyが返って来ず、タイムアウトしたことを表示します。

## ICMPの扱い
ターゲットがdefaultの時、ICMPは受け入れますが、細かい扱いは別途設定されています。

icmp-block-inversionをnoに設定すると、icmp-blocksで設定したICMPを拒否します。yesに設定すると、icmp-blocksで設定したICMPを受け入れます。

### ターゲットをdefaultに設定
ターゲットをdefaultに設定します。

```
$ sudo firewall-cmd --zone=public --set-target=default --permanent
success
$ sudo firewall-cmd --reload
```

```
$ sudo firewall-cmd --zone=public --query-icmp-block-inversion
no
$ sudo firewall-cmd --list-icmp-blocks

```

icmp-block-inversionはnoなのでicmp-blocksで設定したICMPを拒否しますが、icmp-blocksには何も設定されていないので何も拒否しません。

ホストOSからpingコマンドを実行すると、応答が返ってきます。

```
C:\Users\LinuC>ping 192.168.56.101

192.168.56.101 に ping を送信しています 32 バイトのデータ:
192.168.56.101 からの応答: バイト数 =32 時間 =1ms TTL=64
192.168.56.101 からの応答: バイト数 =32 時間 =1ms TTL=64
192.168.56.101 からの応答: バイト数 =32 時間 =1ms TTL=64

192.168.56.101 の ping 統計:
    パケット数: 送信 = 3、受信 = 3、損失 = 0 (0% の損失)、
ラウンド トリップの概算時間 (ミリ秒):
    最小 = 1ms、最大 = 1ms、平均 = 1ms
Ctrl+C
^C
```

### icmp-block-inversionの設定
icmp-block-inversionをyesに設定するためには、firewall-cmd --add-icmp-block-inversionコマンドを実行します。

```
$ sudo firewall-cmd --zone=public --add-icmp-block-inversion
success
$ sudo firewall-cmd --zone=public --query-icmp-block-inversion
yes
```

ホストOSからpingコマンドを実行すると、エラー応答が返ってきます。

```
C:\Users\LinuC>ping 192.168.56.101

192.168.56.101 に ping を送信しています 32 バイトのデータ:
192.168.56.101 からの応答: 宛先ネットワークに到達できません。
192.168.56.101 からの応答: 宛先ネットワークに到達できません。
192.168.56.101 からの応答: 宛先ネットワークに到達できません。
192.168.56.101 からの応答: 宛先ネットワークに到達できません。

192.168.56.101 の ping 統計:
    パケット数: 送信 = 4、受信 = 4、損失 = 0 (0% の損失)、
```

### icmp-block-inversionの設定を元に戻す
icmp-block-inversionをnoに戻すには、firewall-cmd --remove-icmp-block-inversionコマンドを実行します。

```
$ sudo firewall-cmd --remove-icmp-block-inversion
success
$ sudo firewall-cmd --zone=public --query-icmp-block-inversion
no
```


