# wg-docker
Docker Container running a Freifunk Gateway. It contains the following components

* wireguard
* Wireguard-broker
* babeld
* mmfd
* l3roamd

An image can be pulled from dockerhub:
```
docker pull ffmd/wg-docker
```

# Building the Image

```
docker build . \
--tag wireguard:latest
```
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
ffmd/wg-docker
```

The required settings are:

* sysctls as babeld will require them:
  * `net.ipv6.conf.all.accept_redirects=0`
  * `net.ipv4.conf.all.rp_filter=0`
  * `net.ipv6.conf.all.forwarding=1`
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


# runtime environment

When running the container a bit of environment setup must happen:

* set up ip address for main interface
* Set up routing rules for the whole net
* Allowing traffic for mmfd, babeld and l3roamd
* MSS Clamping to compensate pmtu breakage in the own net and on the internet

```
#!/bin/bash
ip -6 r d default
ip -6 r a default via fe80::1 dev eth0 src 2a01:4f8:1c1c:71b5::1

# lookup clat prefix in freifunk routing table
ip -6 ru a to fdff:ffff:ffff::/48 lookup 10
ip -6 ru a to fdff:ffff:fffe::/48 lookup 10

# reach the rest of the batman network
ip -6 r a fda9:26e:5805::/64 dev backend-gw2 proto static

ip -6 a a fda9:26e:5805:bab1:aaaa::1/64 dev eth0
ip -6 r a fda9:26e:5805::2 dev backend-gw2 proto static t 12
ip -6 r a fda9:26e:5805::2 dev backend-gw2 proto static t 10
ip -6 r a 2000::/3 from fda9:26e:5805::/48 dev backend-gw2 proto static t 10
ip -6 r a 2000::/3 from fda9:26e:5805::/48 dev backend-gw2 proto static t 12
ip -6 r a fda9:26e:5805::/48 dev backend-gw2 proto static t 10
ip -6 r a fda9:26e:5805::/48 dev backend-gw2 proto static t 12

meshifs="babel-wg-+ backend-bab+"
for i in $meshifs
do
ip6tables -I INPUT 1 -i $i -s fe80::/64  -p udp -m udp --dport 6696  -j ACCEPT
ip6tables -I INPUT 1 -i $i -s fe80::/64  -p udp -m udp --dport 27275  -j ACCEPT
ip6tables -I INPUT 1 -i $i -s fda9:026e:5805:bab1::/64  -p udp -m udp --dport 6696  -j ACCEPT
ip6tables -I INPUT 1 -i $i -s fda9:026e:5805:bab1::/64  -p udp -m udp --dport 27275  -j ACCEPT
ip6tables -I INPUT 1 -i $i -p udp -m udp --dport 5523  -j ACCEPT

# MSS Clamping
ip6tables -t mangle -A FORWARD -o $i -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -t mangle -A FORWARD -o $i -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
ip6tables -t mangle -A OUTPUT -o $i -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -t mangle -A OUTPUT -o $i -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

done

exit 0
```


