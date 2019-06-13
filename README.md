Commands for Creating root server, namely rootSvr:
Create a new Ubuntu 19.04 Disco Dingo 64-bit LXC container
```sudo lxc-create -t download -n rootSvr -- --dist ubuntu --release disco --arch amd64```

Start the container in daemon(default) mode
```sudo lxc-start --name rootSvr --daemon```

Reference:
https://help.ubuntu.com/lts/serverguide/lxc.html
