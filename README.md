# Stand Alone DNS (S.A.D)

Steps for creating a Standalone DNS Server that simulate the whole DNS System with LXC containers.

Please follow step by step.

# Getting Started

## LXC Setup
---

### Create new Ubuntu LXC image
Follow [DistroBuilder](https://github.com/lxc/distrobuilder)

Replace `cosmic` with `dingo` in `ubuntu.yaml`
```
lxc image import lxd.tar.xz rootfs.squashfs --alias dingo
```
### LXC Network Config
Configure the internal network the containers are in.
```
# lxc network edit lxdbr0
```
```
config:
  ipv4.address: 10.0.10.1/24
  ipv4.dhcp: "true"
  ipv4.nat: "true"
  ipv6.address: none
description: ""
name: lxdbr0
type: bridge
used_by:
- /1.0/containers/rootSvr
managed: true
status: Created
locations:
- none
```

Create the root server and assign it an IP address
```
# lxc init dingo rootSvr
# lxc network attach lxdbr0 rootSvr eth0
# lxc config device set rootSvr eth0 ipv4.address 10.0.10.10
```
Allow the Containers to access Internet
```
# iptables -A POSTROUTING -t nat -j MASQUERADE
```

## Root Server
---
### Environment Setup
Start and Attach the Root Server
```
# lxc start rootSvr
# lxc exec rootSvr -- /bin/bash
```

Give root password (**_Not Safe_**)
```
# passwd
# toor
```

Install Components
```
# apt install -y bind9 ifupdown dnsutils
```

Disable systemd-resolved.service
```
# systemctl disable systemd-resolved.service
# systemctl stop systemd-resolved
# rm /etc/resolv.conf
# echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

Remove Ubuntu Crap
```
# apt purge netplan.io
# apt purge networkd-dispatcher
Maybe Netplan also needs to be removed?
```

Setup ifupdown
```
# vim /etc/network/interfaces
```
```
source-directory /etc/network/interfaces.d

allow-hotpulg eth0
iface eth0 inet dhcp
```
Restart network interface
```
# ifdown eth0
# ifup eth0
```

### Bind9 Config

Start Bind9 in ipv4 only mode
```
# vim /etc/default/bind9
```
```
. . . 
OPTIONS="-u bind -4"
```

Host Root Zone (File Content in bind9.conf.d)
```
# vim /etc/bind/db.root
# vim /etc/bind/named.conf.default-zones
# vim /etc/bind/named.conf.options
```

Check error in named.conf
```
# named-checkconf
```

Restart Bind9 and check result
```
# service bind9 restart
# dig @ 10.0.10.10 seed.com
```
```
; <<>> DiG 9.11.5-P1-1ubuntu2.4-Ubuntu <<>> @10.0.10.10 seed.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 20735
;; flags: qr rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: e38303744d25811a9aa3fb885d0437013b3c7b8954f376be (good)
;; QUESTION SECTION:
;seed.com.                      IN      A

;; AUTHORITY SECTION:
com.                    60      IN      NS      a.gtld-seed.com.

;; ADDITIONAL SECTION:
a.gtld-seed.com.        60      IN      A       10.0.10.11

;; Query time: 0 msec
;; SERVER: 10.0.10.10#53(10.0.10.10)
;; WHEN: Sat Jun 15 00:08:33 UTC 2019
;; MSG SIZE  rcvd: 107
```

### Query Redirect (TBD)

## LXC Setup Continued
### Generate Image
Publish the root server as a image for future containers
```
# lxc publish rootSvr --alias=sadImg --force
```
### Network Setup
Create the .com server and assign it an IP address
```
# lxc init sadImg comSvr
# lxc network attach lxdbr0 comSvr eth0
# lxc config device set comSvr eth0 ipv4.address 10.0.10.11
```

## .com Server
---
### Environment Setup

Start and Attach the .com Server
```
# lxc start comSvr
# lxc exec comSvr -- /bin/bash
```

Give root password (**_Not Safe_**)
```
# passwd
# New password: toor
# Retype new password: toor
```

Restart network interface
```
# ifdown eth0
# ifup eth0
```

### Bind9 Config

Host .com Zone (File Content in bind9.conf.d)
```
# vim /etc/bind/db.com
# vim /etc/bind/db.10.0.10
# vim /etc/bind/named.conf.default-zones
# vim /etc/bind/named.conf.options
```

Restart bind9 and dig result
```
# service bind9 restart
# dig @10.0.10.11 aaa.team01.com
```
```
; <<>> DiG 9.11.5-P1-1ubuntu2.4-Ubuntu <<>> @10.0.10.11 aaa.team01.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 5522
;; flags: qr rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 787cd1b368e3da571956de515d04529ecf6e344a677cd7dd (good)
;; QUESTION SECTION:
;aaa.team01.com.                        IN      A

;; AUTHORITY SECTION:
team01.com.             60      IN      NS      ns.team01.com.

;; ADDITIONAL SECTION:
ns.team01.com.          60      IN      A       10.0.10.12

;; Query time: 0 msec
;; SERVER: 10.0.10.11#53(10.0.10.11)
;; WHEN: Sat Jun 15 02:06:22 UTC 2019
;; MSG SIZE  rcvd: 104
```



# Useful Commands

Check bind9 status
```
# systemctl status bind9
```





**DELETE dingo image after finish**

**REMOVE iptables masqurade after finish**

# Reference

[DistroBuilder](https://github.com/lxc/distrobuilder)

[Setting up LXC network](https://stgraber.org/2016/10/27/network-management-with-lxd-2-3/)

[Disable systemd-resolved.service](https://askubuntu.com/a/907249)

[Configure Bind9](https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-14-04)

https://help.ubuntu.com/lts/serverguide/lxc.html

https://linuxcontainers.org/it/lxc/manpages/man5/lxc.container.conf.5.html

https://wiki.debian.org/LXC

# Ideas

Use Vagrant for fully automated deploy

https://www.vagrantup.com/intro/getting-started/

