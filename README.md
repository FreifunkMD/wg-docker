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

Babeld is built from the 1.9 branch such that it is compatible with the openwrt 
package feed. This allows source-specific routes being transported properly.

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
modprobe ip6_tables
modprobe wireguard
docker run -a stdin -a stdout -a stderr -it --rm --name wg \
--network host \
--cap-add=NET_ADMIN \
--device /dev/net/tun:/dev/net/tun \
--env-file ./env-file \
--privileged \
--sysctl net.ipv6.conf.all.forwarding=1 \
--sysctl net.ipv6.conf.all.accept_redirects=0 \
--sysctl net.ipv4.conf.all.rp_filter=0 klausdieter371/wg-docker
```

The required settings are:

* sysctls as babeld will require them: net.ipv6.conf.all.accept_redirects=0, net.ipv4.conf.all.rp_filter=0, net.ipv6.conf.all.forwarding=1
* tun device: l3roamd and mmfd will require it: \
  --device /dev/net/tun:/dev/net/tun
* the NET_ADMIN capability is required by mmfd, l3roamd, babeld
* The env-file specifies variables to run. Rename env-file.example and start from there.
* privileged is used by babeld to set rp_filter on each new mesh device. Since those are generated on the fly, this cannot be set from the outside of the container. Babeld can be patched such that this setting is not required. The patch is raised as [PR 23](https://github.com/jech/babeld/pull/23).

babeld will distribute all routes that are added to routing tables 11 and 12 and it will export all routes to table 10.
L3roamd from within the container will fill table 11
If you want to distribute a default route in the network, run something like
```
Ip -6 r a fe80::1 dev eth0 proto bird table 12
```
on the docker host.




When running with strace, the following capabilities should be added:
```
 --cap-add sys_admin --cap-add sys_ptrace 
```

