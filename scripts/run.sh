#!/bin/bash

[[ $DEBUG == true ]] && set -x

if [[ -z $WGSECRET ]] || [[ -z $NEXTNODE ]] || [[ -z $CLIENTPREFIX ]] ||
  [[ -z $NODEPREFIX ]] || [[ -z $WHOLENET ]]  || [[ -z $PLATPREFIX ]] ||
  [[ -z $CLATPREFIX ]] || [[ -z $NODEPREFIX ]] || [[ -z $OWNIP ]] || 
  [[ -z $PRIVATEKEY ]]
then
  echo PRIVATEKEY WGSECRET, NEXTNODE, CLIENTPREFIX, NODEPREFIX, WHOLENET, CLATPREFIX, PLATPREFIX, NODEPREFIX, OWNIP must be defined. Check your env-file.
  exit
fi

# Install Wireguard. This has to be done dynamically since the kernel
# module depends on the host kernel version.
apt update
apt install -y linux-headers-$(uname -r)
apt install -y wireguard

/scripts/iprules $NODEPREFIX $CLIENTPREFIX $CLATPREFIX $PLATPREFIX


echo $WGSECRET >$PRIVATEKEY

babelifs=""
if [[ -z $MESHIFS ]] 
then
  babelifs=babeldummydne
else
  babelifs=$MESHIFS
fi

babeld -D -I "" -C "ipv6-subtrees true" \
  -C "reflect-kernel-metric true" \
  -C "export-table 10" \
  -C "import-table 11" \
  -C "import-table 12" \
  -C "local-port-readwrite 33123" \
  -C "default enable-timestamps true" \
  -C "default max-rtt-penalty 96" \
  -C "default rtt-min 25" \
  -C "out ip $NEXTNODE/128 deny" \
  -C "redistribute ip $NEXTNODE/128 deny" \
  -C "redistribute ip $CLIENTPREFIX eq 128 allow" \
  -C "redistribute ip $CLATPREFIX eq 96 allow" \
  -C "redistribute ip $PLATPREFIX eq 96 allow" \
  -C "redistribute ip $NODEPREFIX eq 128 allow" \
  -C "redistribute src-ip $WHOLENET ip 2000::/3 allow" \
  -C "redistribute ip ::/0 allow" \
  -C "redistribute ip 2000::/3 allow" \
  -C "install pref-src $OWNIP"  babeldummydne

for i in $babelifs
do
  (echo  "interface $i type wired rxcost 10 update-interval 60 "; sleep 0.1;  echo quit)  | nc ::1  33123
done

mmfdif=""
for i in $MESHIFS
do
  mmfdif="$mmfdif -i $i"
done
mmfd -s /var/run/mmfd.sock $mmfdif &

l3roamdif=""
for i in $MESHIFS
do
  l3roamdif="$l3roamdif -m $i"
done

/usr/local/bin/l3roamd -s /var/run/l3roamd.sock -p $NODEPREFIX -p $CLIENTPREFIX $l3roamdif -t 11 -a $OWNIP -4 0:0:0:0:0:ffff::/96 &

wg-broker-server &

# we wait until mmfd is up and then start routing respondd multicast traffic
# through the mmfd interface
sleep 1
ip -6 r add ff05::2:1001/128 dev mmfd0 table local

# Handle shutdown behavior
finish () {
    killall mmfd
    killall l3roamd
    killall babeld
    killall wg-broker-server
# TODO: how do we bring down all irrelevant interfaces
    echo "$(date): Shutting down Wireguard"
    wg-quick down $interface
    exit 0
}

trap finish SIGTERM SIGINT SIGQUIT

if [[ ! -n ${DEBUG} ]]; then
  sleep infinity &
  wait $!
else
  /bin/bash
fi

