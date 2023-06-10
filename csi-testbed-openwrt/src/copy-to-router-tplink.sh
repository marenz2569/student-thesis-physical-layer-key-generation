#!/usr/bin/env bash

if [ $# -ne 1 ]; then
	echo "Usage $0 host"
	exit 1
fi

host=$1

docker build -t csi-testbed-openwrt -f Dockerfile.tlwr1043ndv2 .
CID=$(docker create csi-testbed-openwrt)
docker cp ${CID}:/root/openwrt/bin/targets/ath79/generic/openwrt-ath79-generic-tplink_tl-wr1043nd-v2-squashfs-sysupgrade.bin sysupgrade.bin
docker rm ${CID}

ssh $host 'cat > /tmp/sysupgrade.bin' < sysupgrade.bin
# -n do not save current configuration
ssh $host 'sysupgrade -v -n /tmp/sysupgrade.bin' || true

ping $host
