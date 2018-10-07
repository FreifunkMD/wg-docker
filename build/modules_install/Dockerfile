# https://www.wireguard.com/install/#compiling-from-source
# Since wireguard is a kernel module we have to install the module on the host.
# After building this package run docker run --rm -it -v /lib/modules:/lib/modules -v /usr/src:/usr/src:ro <CONTAINER_TAG> in order to install the module.

FROM alpine:3.8

ARG WIREGUARD_VERSION=0.0.20181007
ARG BABELD_VERSION=1.8.3

RUN set -ex \
    && apk add --no-cache \
        ca-certificates \
        build-base \
        linux-vanilla-dev \
        libmnl-dev \
    && wget https://git.zx2c4.com/WireGuard/snapshot/WireGuard-${WIREGUARD_VERSION}.tar.xz -O wireguard.tar.xz \
    && mkdir wireguard \
    && tar xvf wireguard.tar.xz -C wireguard --strip-components 1 \
    && rm wireguard.tar.xz \
    && cd wireguard/src \
    && make tools \
    && make -C tools install \
    && make -C tools clean \
    && cd / \
    && wget https://www.irif.fr/~jch/software/files/babeld-${BABELD_VERSION}.tar.gz -O /babeld.tar.gz \
    && mkdir babeld \
    && tar xvf babeld.tar.gz -C babeld --strip-components 1 \
    && cd babeld \
    && make \
    && make install

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
