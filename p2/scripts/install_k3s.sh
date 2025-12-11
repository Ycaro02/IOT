#!/bin/sh
set -e

K3S_TOKEN="my_custom_token"

apk update
apk add --no-cache curl

curl -sfL https://get.k3s.io | K3S_TOKEN="$K3S_TOKEN" sh -s - server --write-kubeconfig-mode 644 --flannel-iface=eth1

