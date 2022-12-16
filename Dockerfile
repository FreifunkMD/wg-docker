FROM debian:latest

# Thanks to https://nbsoftsolutions.com/blog/routing-select-docker-containers-through-wireguard-vpn
# use apt proxy if given as argument
ARG APT_PROXY_PORT=
ARG HOST_IP=
COPY scripts /scripts

RUN /scripts/detect-apt-proxy.sh $APT_PROXY_PORT && \
apt-get update -y && \
mkdir /mnt/config && \
apt-get install -y software-properties-common iptables curl iproute2 ifupdown iputils-ping git apt-transport-https gnupg2 && \
echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list && \
echo "deb http://dl.ffm.freifunk.net/debian-packages/ sid main" > /etc/apt/sources.list.d/ffffm_babel.list && \
printf 'Package: babeld \nPin: release a=sid\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-babeld_ffffm_sid && \
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable && \
curl -L https://dl.ffm.freifunk.net/info@wifi-frankfurt.de.gpg.pub -o /etc/apt/trusted.gpg.d/info@wifi-frankfurt.de.gpg && \
apt-get update -y && \
apt-get install -y wireguard babeld wg-broker l3roamd mmfd && \
mkdir -p /etc/iproute2/rt_tables.d && \
mkdir -p /etc/wg-broker && \
echo "10    netz" > /etc/iproute2/rt_tables.d/babel.conf && \
echo "11    l3roamd" >> /etc/iproute2/rt_tables.d/babel.conf && \
echo "12    babeld" >> /etc/iproute2/rt_tables.d/babel.conf && \
apt-get install -y strace libjson-c3


ENTRYPOINT ["/scripts/run.sh"]
CMD []
