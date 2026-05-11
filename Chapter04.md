# nftablesとは

## カーネルモジュールの確認
$ lsmod | grep nf

nf_tablesが本体

# firewalld

$ sudo systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; preset>
     Active: active (running) since Tue 2026-05-05 12:10:14 JST; 3h 42min ago
       Docs: man:firewalld(1)
    Process: 849 ExecStartPost=/usr/bin/firewall-cmd --state (code=exited, stat>
   Main PID: 785 (firewalld)
      Tasks: 2 (limit: 10516)
     Memory: 7.1M (peak: 65.8M)
        CPU: 1.688s
     CGroup: /system.slice/firewalld.service
             └─785 /usr/bin/python3 -s /usr/sbin/firewalld --nofork --nopid

 5月 05 12:10:12 localhost systemd[1]: Starting firewalld - dynamic firewall da>
 5月 05 12:10:14 localhost systemd[1]: Started firewalld - dynamic firewall dae>

# firewall-cmd

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

