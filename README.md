# LXC Setup

## Create new Ubuntu 19.04 Disco Dingo 64-bit LXC containers

Root Server -- rootSvr

```sudo lxc-create -t download -n rootSvr -f rootSvr.conf -- --dist ubuntu --release disco --arch amd64```

.com Server -- comSvr

```sudo lxc-create -t download -n comSvr -- --dist ubuntu --release disco --arch amd64```

Team Server -- teamSvr

```sudo lxc-create -t download -n teamSvr -- --dist ubuntu --release disco --arch amd64```

Local Server -- localSvr

```sudo lxc-create -t download -n localSvr -- --dist ubuntu --release disco --arch amd64```

Attacker Server -- atkSvr

```sudo lxc-create -t download -n atkSvr -- --dist ubuntu --release disco --arch amd64```

## Network Setup




Start the container in daemon(default) mode

```sudo lxc-start --name rootSvr --daemon```


# Useful Commands

```
$ sudo lxc-ls --fancy
$ sudo lxc-start --name u1 --daemon
$ sudo lxc-info --name u1
$ sudo lxc-stop --name u1
$ sudo lxc-destroy --name
```


# Reference:

https://help.ubuntu.com/lts/serverguide/lxc.html

https://linuxcontainers.org/it/lxc/manpages/man5/lxc.container.conf.5.html

https://wiki.debian.org/LXC

# Ideas

Use Vagrant for fully automated deploy

https://www.vagrantup.com/intro/getting-started/

# DNS Setup

## Bind9 Config

Start Bind9 in ipv4 only mode
```
$ vim /etc/default/bind9
. . . 
OPTIONS="-u bind -4"
```