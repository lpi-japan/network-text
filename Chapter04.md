# nftablesとは
Linuxのパケットフィルタリングは、Linuxカーネルの機能であるnftablesとして実装されています。関連するカーネルモジュールを読み込ませることで利用できます。

nftablesはカーネルの機能であるため、その設定はコマンドなどで行う必要があります。基本的なツールとしてnftコマンドが用意されていますが、実習環境であるAlmaLinuxではfirewalldがフロントエンドとして採用されています。

## カーネルモジュールの確認
nftables関連のカーネルモジュールが読み込まれているかどうか確認してみましょう。


```
$ lsmod | grep nf
nft_fib_inet           12288  1
nft_fib_ipv4           12288  1 nft_fib_inet
nft_fib_ipv6           12288  1 nft_fib_inet
nft_fib                12288  3 nft_fib_ipv6,nft_fib_ipv4,nft_fib_inet
nft_reject_inet        12288  6
nf_reject_ipv4         16384  1 nft_reject_inet
nf_reject_ipv6         24576  1 nft_reject_inet
nft_reject             16384  1 nft_reject_inet
nft_ct                 24576  7
nft_chain_nat          12288  3
nf_nat                 57344  1 nft_chain_nat
nf_conntrack          204800  2 nf_nat,nft_ct
nf_defrag_ipv6         24576  1 nf_conntrack
nf_defrag_ipv4         12288  1 nf_conntrack
nf_tables             258048  235 nft_ct,nft_reject_inet,nft_fib_ipv6,nft_fib_ipv4,nft_chain_nat,nft_reject,nft_fib,nft_fib_inet
nfnetlink              20480  2 nf_tables
libcrc32c              12288  4 nf_conntrack,nf_nat,nf_tables,xfs
```

様々なカーネルモジュールが読み込まれているのがわかりますが、nf_tablesがnftablesの本体となるカーネルモジュールです。

# firewalld
nftablesを操作するためのフロントエンドがfirewalldです。firewalldは、デーモンとして動作するサービスです。

## firewalldサービスの確認
firewalldが動作していることを確認しましょう。systemctlコマンドで確認できます。

```
$ sudo systemctl status firewalld
[sudo] linuc のパスワード:
● firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; preset>
     Active: active (running) since Sat 2026-05-30 15:59:58 JST; 7h ago
       Docs: man:firewalld(1)
   Main PID: 847 (firewalld)
      Tasks: 2 (limit: 9666)
     Memory: 44.8M (peak: 45.9M)
        CPU: 143ms
     CGroup: /system.slice/firewalld.service
             └─847 /usr/bin/python3 -s /usr/sbin/firewalld --nofork --nopid

 5月 30 15:59:58 localhost systemd[1]: Starting firewalld - dynamic firewall da>
 5月 30 15:59:58 localhost systemd[1]: Started firewalld - dynamic firewall dae>
```

表示から、firewalldの実体はPythonで書かれたプログラムが動作していることが分かります。

# firewall-cmd
デーモンとして動作しているfirewalldに対して、様々な指示を出すのがfirewall-cmdコマンドです。

パケットフィルタリングの設定を変更して外部からのパケットを受け入れる設定方法は『Linuxサーバー構築標準教科書』で解説していますが、設定の確認について補足として解説しておきます。

# パケットフィルタリングの設定を確認する
現在のfirewalldによるパケットフィルタリングの設定を確認するには、firewall-cmd --list-allコマンドを実行します。

```
$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s8 enp0s9
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

## ゾーン
firewalldはゾーンという考え方でパケットフィルタリングを管理しています。特別な構成と設定が必要でない限り、表示されているpublicゾーンに対して設定を行えば、外部とのパケットのやり取りに対してフィルタが設定されます。

firewall-cmd --get-zonesコマンドで、定義されているゾーンの一覧が確認できます。

```
$ sudo firewall-cmd --get-zones
block dmz drop external home internal nm-shared public trusted work
```

firewall-cmd --get-default-zoneコマンドで、デフォルトに設定されているゾーンが確認できます。

```
$ sudo firewall-cmd --get-default-zone
public
```

## ターゲット
ターゲットは、そのゾーンに入ったパケットが設定されているルールにマッチしなかった場合、どのような処理を行うのかを定義しています。

ターゲットは以下の種類があります。

- ACCEPT
ルールで拒否されたパケット以外をすべて受け入れます。

- REJECT
ルールで許可されたパケット以外をすべて拒否します。拒否したことを送信元に通知します。

- DROP
ルールで許可されたパケット以外をすべて破棄します。破棄したことを送信元に通知しません。

- default
REJECT同様の振るまいをしますが、いくつかの違いがあります。PINGなどで使われるICMPは通します。

確認した設定ではdefaultがターゲットになっているので、ICMP以外のパケットはルールで許可しない限り拒否されます。

## ICMPの扱い
ターゲットがdefaultの時、ICMPは受け入れますが、細かい扱いは別途設定されています。

- icmp-block-inversion
yesに設定すると、icmp-blocksで設定したICMPを受け入れます。noに設定すると、icmp-blocksで設定したICMPを拒否します。

icmp-blocksに設定できるICMPの種類は、firewall-cmd --get-icmptypesコマンドを実行します。

```
$ sudo firewall-cmd --get-icmptypes
[sudo] linuc のパスワード:
address-unreachable bad-header beyond-scope communication-prohibited destination-unreachable echo-reply echo-request
（略）
unknown-header-type unknown-option
```

たとえば、PINGで確認するのはecho-request、それに対する応答はecho-replyです。

