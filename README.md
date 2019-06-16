# Stand Alone DNS (S.A.D)

Steps for creating a Standalone DNS Server that simulate the whole DNS System with LXC containers.

Please follow step by step.

# Getting Started

## Host Machine Setup
---
Install Components
```
# apt install -y ifupdown dnsutils
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
# apt -y purge netplan.io
# rm -r /etc/netplan
# apt -y purge networkd-dispatcher
# apt -y autoremove
```

Setup ifupdown
```
# vim /etc/network/interfaces
```
```
auto enp0s3
iface enp0s3 inet dhcp
```

Restart network interface
```
# ifdown enp0s3
# ifup enp0s3
```

Added hostname to hosts file
```
# echo "127.0.0.1        sad" >> /etc/hosts
```

## LXC Setup
---
```
# lxd init
Would you like to use LXD clustering? (yes/no) [default=no]:
Do you want to configure a new storage pool? (yes/no) [default=yes]:
Name of the new storage pool [default=default]: sadPool
Name of the storage backend to use (btrfs, dir, lvm) [default=btrfs]: dir
Would you like to connect to a MAAS server? (yes/no) [default=no]:
Would you like to create a new local network bridge? (yes/no) [default=yes]:
What should the new bridge be called? [default=lxdbr0]:
What IPv4 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]:
What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: none
Would you like LXD to be available over the network? (yes/no) [default=no]:
Would you like stale cached images to be updated automatically? (yes/no) [default=yes] no
Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]: yes
```

### Create new Ubuntu LXC image
There are 2 (and more) ways to build a LXC image, choose the one you like.

#### Method 1 LXD
```
# lxc init ubuntu:18.04 rootSvr
```

#### Method 2 DistroBuilder
Follow [DistroBuilder](https://github.com/lxc/distrobuilder)

Replace `cosmic` with `dingo` in `ubuntu.yaml`
```
# lxc image import lxd.tar.xz rootfs.squashfs --alias dingo
# lxc init dingo rootSvr
```

### LXC Network Config
Configure the internal network the containers are in.
```
# lxc network edit lxdbr0
```
```
. . .
config:
  ipv4.address: 10.0.10.1/24
  ipv4.dhcp: "true"
  ipv4.nat: "true"
  ipv6.address: none
description: "SAD Network"
name: lxdbr0
type: bridge
used_by:
- /1.0/containers/rootSvr
managed: true
status: Created
locations:
- none
```

Allow the Containers to access Internet
```
# iptables -A POSTROUTING -t nat -j MASQUERADE
```


## Root Server
---

### Host Setup
Create the root server and assign it an IP address
```
# lxc network attach lxdbr0 rootSvr eth0
# lxc config device set rootSvr eth0 ipv4.address 10.0.10.10
```

Start and Attach the Root Server
```
# lxc start rootSvr
# lxc exec rootSvr -- /bin/bash
```

### Guest Setup
Give root password (**_Not Safe_**)
```
# passwd
New password: toor
Retype new password: toor
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
# apt purge -y netplan.io
# rm -r /etc/netplan
# apt purge -y networkd-dispatcher
# apt -y autoremove
```

Setup ifupdown
```
# vim /etc/network/interfaces
```
```
auto eth0
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
# dig @10.0.10.10 seed.com
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

## Generate Custom LXC Image
Publish the root server as a image for future containers
```
# lxc publish rootSvr --alias=sadImg --force
```
Check the fingerprint of the vanilla ubuntu image
```
lxc image list
```
Remove the vanilla ubuntu image
```
lxc image delete <fingerprint>
```

## .com Server
---
### Host Setup
Create the .com server and assign it an IP address
```
# lxc init sadImg comSvr
# lxc network attach lxdbr0 comSvr eth0
# lxc config device set comSvr eth0 ipv4.address 10.0.10.11
```

Start and Attach the .com Server
```
# lxc start comSvr
# lxc exec comSvr -- /bin/bash
```

### Guest Setup
Give root password (**_Not Safe_**)
```
# passwd
New password: toor
Retype new password: toor
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
# dig @10.0.10.11 www.team00.com
```
```
; <<>> DiG 9.11.3-1ubuntu1.7-Ubuntu <<>> @10.0.10.11 www.team00.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 26696
;; flags: qr rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 987751af326de166b7a877d55d05e18df330d864ae20902e (good)
;; QUESTION SECTION:
;www.team00.com.                        IN      A

;; AUTHORITY SECTION:
team00.com.             60      IN      NS      ns.team00.com.

;; ADDITIONAL SECTION:
ns.team00.com.          60      IN      A       10.0.10.12

;; Query time: 0 msec
;; SERVER: 10.0.10.11#53(10.0.10.11)
;; WHEN: Sun Jun 16 06:28:29 UTC 2019
;; MSG SIZE  rcvd: 104
```

## LXC Setup Continued
---
### Network Setup
Create the team server and assign it an IP address
```
# lxc init sadImg teamSvr
# lxc network attach lxdbr0 teamSvr eth0
# lxc config device set teamSvr eth0 ipv4.address 10.0.10.12
```

## team Server
---
### Environment Setup

Start and Attach the team Server
```
# lxc start teamSvr
# lxc exec teamSvr -- /bin/bash
```

Give root password (**_Not Safe_**)
```
# passwd
New password: toor
Retype new password: toor
```

### Bind9 Config

Host team Zone (File Content in bind9.conf.d)
```
# mkdir /etc/bind/zones
# vim /etc/bind/db.10.0.10
# vim /etc/bind/zones/team00.com
# vim /etc/bind/named.conf.team-zones
# vim /etc/bind/named.conf.default-zones
# vim /etc/bind/named.conf.options
# echo 'include "/etc/bind/named.conf.team-zones";' >> /etc/bind/named.conf
```

Restart bind9 and dig result
```
# service bind9 restart
# dig @10.0.10.12 www.team00.com
```
```
; <<>> DiG 9.11.3-1ubuntu1.7-Ubuntu <<>> @10.0.10.12 www.team00.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62817
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 84aabe9cd4392db49c76fcf15d05d6a4bf91ae842b91c4d0 (good)
;; QUESTION SECTION:
;www.team00.com.                        IN      A

;; ANSWER SECTION:
www.team00.com.         60      IN      A       10.0.10.12

;; AUTHORITY SECTION:
team00.com.             60      IN      NS      ns.team00.com.

;; ADDITIONAL SECTION:
ns.team00.com.          60      IN      A       10.0.10.12

;; Query time: 0 msec
;; SERVER: 10.0.10.12#53(10.0.10.12)
;; WHEN: Sun Jun 16 05:41:56 UTC 2019
;; MSG SIZE  rcvd: 120
```

## Local Server
---

### Host Setup
Create the local server and assign it an IP address
```
# lxc init sadImg locSvr
# lxc network attach lxdbr0 locSvr eth0
# lxc config device set locSvr eth0 ipv4.address 10.0.10.13
```

Start and Attach the local Server
```
# lxc start locSvr
# lxc exec locSvr -- /bin/bash
```

### Guest Setup
Give root password (**_Not Safe_**)
```
# passwd
New password: toor
Retype new password: toor
```

### Bind9 Config

Host local Zone (File Content in bind9.conf.d)
```
# vim /etc/bind/root.hint
# vim /etc/bind/named.conf.default-zones
# vim /etc/bind/named.conf.options
```

Restart bind9 and dig result
```
# service bind9 restart
# dig @10.0.10.13 www.team00.com
```
```
; <<>> DiG 9.11.3-1ubuntu1.7-Ubuntu <<>> @10.0.10.13 www.team00.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 35881
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: f032e4c0f92d6f80f22195125d05d942a3b657deb8a8a4a0 (good)
;; QUESTION SECTION:
;www.team00.com.                        IN      A

;; ANSWER SECTION:
www.team00.com.         60      IN      A       10.0.10.12

;; AUTHORITY SECTION:
team00.com.             60      IN      NS      ns.team00.com.

;; Query time: 2 msec
;; SERVER: 10.0.10.13#53(10.0.10.13)
;; WHEN: Sun Jun 16 05:53:06 UTC 2019
;; MSG SIZE  rcvd: 104
```


## Attacker Server
---

### Host Setup
Create the attacker server and assign it an IP address
```
# lxc init sadImg atkSvr
# lxc network attach lxdbr0 atkSvr eth0
# lxc config device set atkSvr eth0 ipv4.address 10.0.10.14
```

Start and Attach the attacker Server
```
# lxc start atkSvr
# lxc exec atkSvr -- /bin/bash
```

### Guest Setup
Give root password (**_Not Safe_**)
```
# passwd
# New password: toor
# Retype new password: toor
```

### Bind9 Config

Host local Zone (File Content in bind9.conf.d)
```
# mkdir /etc/bind/zones
# vim /etc/bind/db.attack
# vim /etc/bind/zones/team00.com
# vim /etc/bind/named.conf.team-zones
# vim /etc/bind/named.conf.default-zones
# vim /etc/bind/named.conf.options
# echo 'include "/etc/bind/named.conf.team-zones";' >> /etc/bind/named.conf
```

Restart bind9 and dig result
```
# service bind9 restart
# dig @10.0.10.14 www.team00.com
```
```
; <<>> DiG 9.11.3-1ubuntu1.7-Ubuntu <<>> @10.0.10.14 www.team00.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 56207
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 30ea5733824537d90383d1e85d05de6ca382e5a5bf804da9 (good)
;; QUESTION SECTION:
;www.team00.com.                        IN      A

;; ANSWER SECTION:
www.team00.com.         60      IN      A       10.0.10.14

;; AUTHORITY SECTION:
team00.com.             60      IN      NS      ns.attacker32.com.

;; ADDITIONAL SECTION:
ns.attacker32.com.      60      IN      A       10.0.10.14

;; Query time: 0 msec
;; SERVER: 10.0.10.14#53(10.0.10.14)
;; WHEN: Sun Jun 16 06:15:08 UTC 2019
;; MSG SIZE  rcvd: 131
```

## Vagrant
The following command happens on the same level with VirtualBox

### Vagrant Packaging
Create a Vagrant Box
```
$ vagrant package --base <VM Name>
```

Generate Vagrantfile
```
$ vagrant init
```
Edit the generated Vagrantfile
```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box_url = "file://package.box"
  config.vm.box_check_update = false
    config.ssh.password = "dees"
  config.ssh.username = "seed"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "4096"
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 15551

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"



  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
```





# Useful Commands

Check bind9 status
```
# systemctl status bind9
```

LXC Operation
```
# lxc start --all
# lxc stop --all
```

Restart network interface
```
# ifdown eth0
# ifup eth0
```



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

Which address should be used for success attack?
