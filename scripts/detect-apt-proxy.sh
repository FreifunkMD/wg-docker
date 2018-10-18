#!/bin/bash

if [ -z $APT_PROXY_PORT ] ; then
  APT_PROXY_PORT=$1
fi
if [ -z "${HOST_IP}" ]; then
  HOST_IP=$(route -n | awk '/^0.0.0.0/ {print $2}')
fi
timeout 1 bash -c 'cat < /dev/null > /dev/tcp/${HOST_IP}/${APT_PROXY_PORT}'
if [ $? -eq 0 ]; then
    cat > /etc/apt/apt.conf.d/30proxy <<EOL
    Acquire::http::Proxy "http://$HOST_IP:$APT_PROXY_PORT";
    Acquire::http::Proxy::ppa.launchpad.net DIRECT;
EOL
    cat /etc/apt/apt.conf.d/30proxy
    echo "Using host's apt proxy"
else
    [[ -f /etc/apt/apt.conf.d/30proxy ]] && rm -f /etc/apt/apt.conf.d/30proxy
    echo "No apt proxy detected on Docker host"
fi
