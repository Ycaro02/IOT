#!/bin/sh
set -e

addgroup vagrant docker 2>/dev/null || true
addgroup vagrant k3s 2>/dev/null || true


rc-service docker restart || true
rc-service k3s restart || true

if ! command -v docker >/dev/null 2>&1; then
    apk add --no-cache docker
    rc-update add docker
    service docker start
    sleep 2
fi

cd /vagrant/app1
docker build -t app1:latest .

cd /vagrant/app2
docker build -t app2:latest .

cd /vagrant/app3
docker build -t app3:latest .

until kubectl get nodes >/dev/null 2>&1; do
    sleep 1
done

docker save app1:latest | k3s ctr images import -
docker save app2:latest | k3s ctr images import -
docker save app3:latest | k3s ctr images import -


kubectl apply -f /vagrant/confs/apps.yaml
kubectl apply -f /vagrant/confs/apps-ingress.yaml
