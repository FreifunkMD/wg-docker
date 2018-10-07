FROM alpine:3.8

# needs proper tagging!    
ARG INSTALL_TAG=install

RUN set -ex \
    && apk --no-cache add \
        ca-certificates \
        libmnl \

#COPY --from=${INSTALL_TAG} /usr/bin/wg /usr/bin/wg
#COPY --from=${INSTALL_TAG} /usr/share/man/man8/wg.8 /usr/share/man/man8/wg.8
#COPY --from=${INSTALL_TAG} /usr/bin/wg-quick /usr/bin/wg-quick
#COPY --from=${INSTALL_TAG} /usr/share/man/man8/wg-quick.8 /usr/share/man/man8/wg-quick.8
