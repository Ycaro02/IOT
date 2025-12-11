#!/bin/sh
set -e

LOCAL_K3S_TOKEN="nsdhajFGHHSAD52pfskjm&nfdsjhk"

apk update
apk add --no-cache curl

echo ARGS: $@

if [ "$1" == "server" ]; then
   curl -sfL https://get.k3s.io | K3S_TOKEN=${LOCAL_K3S_TOKEN} sh -s - server --write-kubeconfig-mode 644 --node-ip 192.168.56.110 --flannel-iface eth1
elif [ "$1" == "agent" ]; then
    curl -sfL https://get.k3s.io | K3S_TOKEN=${LOCAL_K3S_TOKEN} K3S_URL=https://192.168.56.110:6443 sh -s - agent --node-ip 192.168.56.111 --flannel-iface eth1
else
    echo "Unknown argument: $1"
    exit 1
fi