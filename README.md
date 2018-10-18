# wg-docker
Docker Container running a Freifunk Gateway. It contains the following components

* wireguard
* Wireguard-broker
* babeld
* mmfd
* l3roamd

The image can be pulled from dockerhub:
```
docker pull klausdieter371/wg-docker
```

# Building the Image
The build can make use of an apt cache.
```
docker build . \
--tag wireguard:latest \
--build-arg APT_PROXY_PORT=3142 \
--build-arg HOST_IP=192.168.13.9
```
Will start a build relying on a cache on 192.168.13.9 that is reachable on port 3142

# Running a container

The image will require some variables and parameters to be set in order to run:

It is designed to be run like this when in interactive mode:
```
docker run -a stdin -a stdout -a stderr -it --rm --name wg \
--network host \
--cap-add=NET_ADMIN \
--device /dev/net/tun:/dev/net/tun \
--env-file ./env-file \
--sysctl net.ipv6.conf.all.forwarding=1 \
--sysctl net.ipv6.conf.all.accept_redirects=0 \
--sysctl net.ipv4.conf.all.rp_filter=0 klausdieter371/wg-docker
```

The required settings are:

* sysctls as babeld will require them: net.ipv6.conf.all.accept_redirects=0, net.ipv4.conf.all.rp_filter=0, net.ipv6.conf.all.forwarding=1
* tun device: l3roamd and mmfd will require it: --device /dev/net/tun:/dev/net/tun
* the NET_ADMIN capability is required by mmfd, l3roamd, babeld
* The env-file specifies variables to run. Rename env-file.example and start from there.

When running with strace, the following capabilities should be added:
```
 --cap-add sys_admin --cap-add sys_ptrace 
```

