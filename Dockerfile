FROM debian:bullseye as build

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential cmake \
    git-core \
    pkg-config \
    # For l3roamd
    libnl-3-dev libnl-genl-3-dev libjson-c-dev
# No need to clear the cache here


FROM build as babeld

RUN git clone --branch docker https://github.com/christf/babeld.git /babeld
RUN make -j$(nproc) -C /babeld
RUN TARGET=/babeld-install make -C /babeld install.minimal


FROM build as wg-broker

RUN git clone https://github.com/christf/wg-broker.git /wg-broker
RUN make -j$(nproc) -C /wg-broker
RUN DESTDIR=/wg-broker-install make -C /wg-broker install


FROM build as l3roamd

RUN git clone https://github.com/freifunk-gluon/l3roamd.git /l3roamd
RUN mkdir /l3roamd/build
RUN cmake -B/l3roamd/build -H/l3roamd
RUN make -j$(nproc) -C /l3roamd/build
RUN DESTDIR=/l3roamd-install make -C /l3roamd/build install


FROM build as mmfd

# grab and build libbabel (mmfd dependency)
RUN git clone https://github.com/christf/libbabelhelper.git /libbabelhelper
RUN mkdir /libbabelhelper/build
RUN cmake -B/libbabelhelper/build -H/libbabelhelper
RUN make -j$(nproc) -C /libbabelhelper/build
# This is installed as a static library, so no need to copy it later
RUN make -C /libbabelhelper/build install

# grab and build mmfd
RUN git clone https://github.com/freifunk-gluon/mmfd /mmfd
RUN mkdir /mmfd/build
RUN cmake -B/mmfd/build -H/mmfd
RUN make -j$(nproc) -C /mmfd/build
RUN DESTDIR=/mmfd-install make -C /mmfd/build install


FROM debian:bullseye

# Thanks to https://nbsoftsolutions.com/blog/routing-select-docker-containers-through-wireguard-vpn

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    iptables curl iproute2 ifupdown iputils-ping \
    netcat-openbsd jq \
    # for l3roamd
    libnl-3-200 libnl-genl-3-200 libjson-c5 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=babeld /babeld-install /
COPY --from=wg-broker /wg-broker-install /
COPY --from=l3roamd /l3roamd-install /
COPY --from=mmfd /mmfd-install /

COPY scripts /scripts

RUN mkdir /mnt/config && \
    mkdir -p /etc/iproute2/rt_tables.d && \
    mkdir -p /etc/wg-broker && \
    echo "10    netz" > /etc/iproute2/rt_tables.d/babel.conf && \
    echo "11    l3roamd" >> /etc/iproute2/rt_tables.d/babel.conf && \
    echo "12    babeld" >> /etc/iproute2/rt_tables.d/babel.conf

ENTRYPOINT ["/scripts/run.sh"]
CMD []
