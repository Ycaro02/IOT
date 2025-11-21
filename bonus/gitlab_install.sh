#!/bin/bash


# passwordless sudo
sudo su -c "echo \"$(id -un) ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/$(id -un)"
sudo su -c "chmod 0440 /etc/sudoers.d/$(id -un)"


sudo apt update
sudo apt install git zsh vim curl -y

docker_path=`whereis docker | awk -F ':' '{print $2}' | tr -d ' '`
if [ -z "$docker_path" ]; then
    # Add Docker's official GPG key:
    sudo apt install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
else
    echo "Docker is already installed at $docker_path"
fi

kubectl_path=`whereis kubectl | awk -F ':' '{print $2}' | tr -d ' '`
if [ -z "$kubectl_path" ]; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl is already installed at $kubectl_path"
fi


k3d_path=`whereis k3d | awk -F ':' '{print $2}' | tr -d ' '`
if [ -z "$k3d_path" ]; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "k3d is already installed at $k3d_path"
fi

docker_groups=$(groups $USER | grep 'docker')
if [ -z "$docker_groups" ]; then
    sudo usermod -aG docker $USER
    echo "Please log out and log back in to apply the Docker group changes."
    exit 1
fi


k3d cluster delete mycluster
k3d cluster create mycluster \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer"

helm_path=`whereis helm | awk -F ':' '{print $2}' | tr -d ' '`

if [ -z "$helm_path" ]; then
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
    chmod 700 get_helm.sh
    ./get_helm.sh
else
    echo "Helm is already installed at $helm_path"
fi

helm repo add gitlab https://charts.gitlab.io/
helm repo update


helm upgrade --install gitlab gitlab/gitlab \
  --set global.hosts.domain=localhost \
  --set global.hosts.externalIP=127.0.0.1 \
  --set global.ingress.configureCertmanager=false \
  --set global.hosts.https=false \
  --set global.ingress.tls.enabled=false \
  --set global.ingress.annotations."nginx\.ingress\.kubernetes\.io/force-ssl-redirect"="false" \
  --set global.edition=ce \
  --timeout 600s



kubectl apply -f gitlab-traefik.yaml