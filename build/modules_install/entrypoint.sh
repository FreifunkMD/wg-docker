#!/bin/sh

set -ex
(
cd /wireguard/src/
echo "Building module..."
make module
echo "Installing module..."
make module-install
echo "Cleaning up..."
make clean
)
echo "Success!"

exec $@
