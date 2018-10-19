#!/bin/bash

WIREGUARD_VERSION='0.0.20181007'

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Make sure dkms is installed
command -v dkms >/dev/null 2>&1 || { echo >&2 "dkms is required but not installed.  Aborting."; exit 1; }

echo 'downloading source...'
curl "https://git.zx2c4.com/WireGuard/snapshot/WireGuard-${WIREGUARD_VERSION}.tar.xz" > "/tmp/wireguard-${WIREGUARD_VERSION}.tar.xz"

echo 'extracting...'
(
    mkdir "/tmp/wireguard-${WIREGUARD_VERSION}"
    tar xvf "/tmp/wireguard-${WIREGUARD_VERSION}.tar.xz" -C "/tmp/wireguard-${WIREGUARD_VERSION}" --strip-components 1
    mv "/tmp/wireguard-${WIREGUARD_VERSION}/src" "/usr/src/wireguard-${WIREGUARD_VERSION}"
)
echo 'creating dkms config file...'
(
    cat << EOF > "/usr/src/wireguard-${WIREGUARD_VERSION}/dkms.conf"
PACKAGE_NAME="wireguard"
PACKAGE_VERSION="${WIREGUARD_VERSION}"
BUILT_MODULE_NAME[0]="wireguard"
DEST_MODULE_LOCATION[0]="/kernel/drivers/misc"
AUTOINSTALL="yes"
EOF
)
echo 'building and installing...'
(
    dkms add "wireguard/${WIREGUARD_VERSION}"
    dkms build "wireguard/${WIREGUARD_VERSION}"
    dkms install "wireguard/${WIREGUARD_VERSION}"
    modprobe wireguard
)
echo 'clean up...'
(
    rm "/tmp/wireguard-${WIREGUARD_VERSION}.tar.xz"
    rm -rf "/tmp/wireguard-${WIREGUARD_VERSION}"
)
echo 'done!'
