# TCPとは
TCP（Transmission Control Protocol）は、IPを使ったネットワーク通信上で様々な通信制御を行うプロトコルです。IPと組み合わせて使用されるため、TCP/IPと呼ばれることもあります。

## 3wayハンドシェイク
TCPは、通信を開始する際に3wayハンドシェイクと呼ばれる方法でセッションを確立します。

1. 送信側は、通信を開始するためにSYN（Synchronize・同期）フラグを設定したパケットを受信側に送信します。
2. 受信側は、送られてきたSYNフラグに対してACK（Acknowledgement・了承）フラグと、自分の側からのSYNフラグを設定したパケット、すなわちSYN＋ACKフラグのパケットを送信側に送信します。
3. 送信側は、受信側からのSYNフラグに応答するACKフラグを設定したパケットを受信側に送信します。

※図入れる

この3つのやり取りで3wayハンドシェイクは完了し、通信のためのセッションが確立します。

## シーケンス番号と再送信要求
3wayハンドシェイクのやり取りでは、お互いのシーケンス番号を交換しています。

送信側は、データを送信する際にパケットに自分のシーケンス番号を設定し、パケットで送信するデータのサイズ分だけ自分のシーケンス番号を加算します。受信側も、受け取ったデータのサイズ分だけ相手のシーケンス番号を加算します。パケットを送受信する度に、同様のことを繰り返します。

もしパケットが途中の通信経路で失われてしまうと、受信側は自分の持っている相手側のシーケンス番号と、送られてきたパケットのシーケンス番号が異なっているため、パケットが失われたことが分かります。その際には、失われたシーケンス番号のパケットを再送信するように送信側に要求します。

※図入れる

このようにして、TCPは通信パケットが失われないようにすることを保証しています。

# UDPとは
UDP（User Datagram Protocol）は、TCP同様にIPネットワークでデータ通信を行うためのプロトコルです。TCPと異なり、3wayハンドシェイクやシーケンス番号による通信の保証を行わない、軽量な通信プロトコルです。

UDPが使われている代表的な通信プロトコルとして、DNSに対する名前解決の問い合わせがあります。

## UDPはセッションレスプロトコル
TCPが通信のためのセッションを確立してから通信を行うのに対して、UDPはセッションの無いセッションレスのプロトコルです。そのため、通信パケットが通信経路の途中で失われても分からないため、再送要求は行われません。

UDPを利用するアプリケーションは、自分の送信したUDPパケットに対する返信が無い場合には、一定時間待った後にタイムアウトさせて、必要に応じて再度UDPパケットを送信するなどの処理が必要です。

# ポート番号とは
ポート番号は、TCPやUDPが使う送信側や受信側を識別するための値です。IPアドレスがネットワークに接続されたノードに紐付けられるのに対して、ポート番号は通信を行うプロセスに紐付けられます。

たとえば、HTTPSでWebサーバーに対して通信を行う場合、ポート番号443番に対して通信を行います。Webサーバー側では、Webサーバーのプロセスがポート番号443番に対する通信を待ち受け（LISTEN）、リクエストが送られてくると処理を行い、返信します。

## Well-Knownポート
ポート番号のうち、主要なプロトコルに対応付けられているポート番号0番から1023番までをWell-Knownポートと呼びます。

Linuxでは、Well-Knownポートを使用するにはroot権限が必要です。

## Registerdポート
ポート番号のうち、1024番から49151番までをRegisterdポートと呼びます。インターネットに関わる様々な事柄を管理する組織であるIANA（Internet Assigned Numbers Authority）に申請を行い、登録される（Registerd）ことで他のプロトコルとポート番号が重複しないようにしています。

## ハイポート
プロセスが自由に使えるポート番号です。IANAが管理しているWell-KnownポートとRegisterdポートよりも上の番号なのでハイ（High）ポートと呼ばれます。

ハイポートは、通信を行うクライアントが使用してサーバーからの返信を受け取るために使用したり、一部は特定のソフトウェアがIANAに未登録で使用しています。前者は、使用していたプロセスが終了すると解放されるため、エフェメラルポート（一時的なポート）と呼ばれます。

IANAの定義では49152番から65535番ですが、Linuxでは異なっています。実際にエフェメラルポートとして使われるポート番号は/proc/sys/net/ipv4/ip_local_port_rangeを参照すると確認できます。

```
$ cat /proc/sys/net/ipv4/ip_local_port_range
32768	60999
```

エフェメラルポートとして、32768番から60999番が使用されることが分かります。

## /etc/servicesを参照する
ポート番号は、/etc/servicesに名称との対応が記述されているので確認してみましょう。

```
$ tail /etc/services
aigairserver    21221/tcp               # Services for Air Server
ka-kdp          31016/udp               # Kollective Agent Kollective Delivery
ka-sddp         31016/tcp               # Kollective Agent Secure Distributed Delivery
edi_service     34567/udp               # dhanalakshmi.org EDI Service
axio-disc       35100/tcp               # Axiomatic discovery protocol
axio-disc       35100/udp               # Axiomatic discovery protocol
pmwebapi        44323/tcp               # Performance Co-Pilot client HTTP API
cloudcheck-ping 45514/udp               # ASSIA CloudCheck WiFi Management keepalive
cloudcheck      45514/tcp               # ASSIA CloudCheck WiFi Management System
spremotetablet  46998/tcp               # Capture handwritten signatures
```

Linuxのハイポートは32768番からなので、34567番のedi_service以降は重複しています。もちろん、先にプロセスが起動してそのポート番号を使用し始めた場合、同じポート番号は使用されません。

# TCPの通信をWiresharkで見てみよう

※後で書く

# UDPの通信をWiresharkで見てみよう

※後で書く
