# this is the build container for building wireguard, babeld and any other necessary programs
FROM alpine:latest AS build

LABEL maintainer="Jasper Orschulko <jasper@fancydomain.eu>"

ARG WIREGUARD_VER=
ARG BABELD_VER=

RUN set -ex \
    # install build tools and dependencies for wireguard
    && apk --no-cache add \
        ca-certificates \
        build-base \
        linux-vanilla-dev \
        libmnl-dev git \
    # grab desired wireguard version
    && wget https://git.zx2c4.com/WireGuard/snapshot/WireGuard-${WIREGUARD_VER}.tar.xz -O /wireguard.tar.xz \
    # extract with custom folder name
    && mkdir /wireguard \
    && tar -xvf /wireguard.tar.xz -C /wireguard --strip-components=1 \
    # only build wg-tools, kernel module has to be installed on host
    && make -C /wireguard/src tools \
    && make -C /wireguard/src/tools install \
    && make -C /wireguard/src/tools clean \
    # grab the desired babeld version 
    && wget https://www.irif.fr/~jch/software/files/babeld-${BABELD_VER}.tar.gz -O /babeld.tar.gz \
    # extract with custom folder name
    && mkdir /babeld \
    && tar -xvf /babeld.tar.gz -C /babeld --strip-components=1 \
    # make babeld
    && make -C /babeld \
    && make -C /babeld install \
    # grab and build wg-broker
    && git clone https://github.com/christf/wg-broker.git /wg-broker \
    && make -C /wg-broker \
    && make -C /wg-broker install \
    # install dependencies for building l3roamd
    && apk --no-cache add \
        libnl3-dev \
        json-c-dev \
        cmake \
    # grab and build l3roamd
    && git clone https://github.com/freifunk-gluon/l3roamd.git /l3roamd \
    && mkdir /l3roamd/build \
    && cmake -B/l3roamd/build -H/l3roamd \
    && make -C /l3roamd/build \
    && make -C /l3roamd/build install \
    # grab and build libbabel (mmfd dependency)
    && git clone https://github.com/christf/libbabelhelper.git /libbabelhelper \
    && mkdir /libbabelhelper/build \
    && cmake -B/libbabelhelper/build -H/libbabelhelper \
    && make -C /libbabelhelper/build \
    && make -C /libbabelhelper/build install \
    # grab and build mmfd
    && git clone https://github.com/freifunk-gluon/mmfd /mmfd \
    && mkdir /mmfd/build \
    && cmake -B/mmfd/build -H/mmfd \
    && make -C /mmfd/build \
    && make -C /mmfd/build install 

# this is the run container. It copies the built binaries from the build container and only adds the necessary packages to run these. This drastically decreases container size 
FROM alpine:latest

LABEL maintainer="Jasper Orschulko <jasper@fancydomain.eu>"

ARG HOST_IP=

COPY scripts /scripts

RUN set -ex \
    # install run dependencies
    && apk --no-cache add \
        ca-certificates \
        libnl3 \
        json-c \
        libmnl \
        iptables \
    && mkdir /etc/wg-broker

# copy scripts to container
COPY scripts /scripts

# copy built binaries from build container
COPY --from=build /usr/bin/wg /usr/bin/wg
COPY --from=build /usr/share/man/man8/wg.8 /usr/share/man/man8/wg.8
COPY --from=build /usr/bin/wg-quick /usr/bin/wg-quick
COPY --from=build /usr/share/man/man8/wg-quick.8 /usr/share/man/man8/wg-quick.8
COPY --from=build /usr/local/bin/babeld /usr/bin/babeld
COPY --from=build /usr/local/share/man/man8/babeld.8 /usr/share/man/man8/babeld.8
COPY --from=build /usr/sbin/wg-broker-server /usr/bin/wg-broker-server
COPY --from=build /etc/wg-broker/config /etc/wg-broker/config
COPY --from=build /usr/local/bin/l3roamd /usr/bin/l3roamd
# TODO: copy all .so files, .h and pkgconfig files or is this sufficient? Do we even need libbabelhelper after building?
COPY --from=build /usr/local/lib/libbabelhelper.so /usr/lib/libbabelhelper.so
COPY --from=build /usr/local/bin/mmfd /usr/bin/mmfd

ENTRYPOINT ["/scripts/run.sh"]
CMD []
