#!/bin/bash

if [[ -z ${1}  ]]; then
    echo "Please prove bash log script path as first argument"
    exit 1
fi

if [[ ! -f ${1} ]]; then
    echo "Bash log script path ${1} not found"
    exit 1
fi

source "${1}"

function install_deps {

log I "Install dependencies..."
sudo apt update 2>&1
sudo apt install git zsh vim curl -y 2>&1

local docker_path=`whereis docker | awk -F ':' '{print $2}' | awk '{print $1}'`
if [ -z "${docker_path}" ]; then
    log I "Installing Docker..."
    sudo apt update && sudo apt install vim curl docker.io docker-compose docker-compose-v2 -y
else
    log I "Docker is already installed at ${docker_path}"
fi

local kubectl_path=`whereis kubectl | awk -F ':' '{print $2}' | tr -d ' '`
if [ -z "${kubectl_path}" ]; then
    log I "Installing kubectl..."
    curl -s -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    log I "kubectl is already installed at ${kubectl_path}"
fi


local k3d_path=`whereis k3d | awk -F ':' '{print $2}' | tr -d ' '`
if [ -z "${k3d_path}" ]; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    log I "k3d is already installed at ${k3d_path}"
fi
}

function loop_install_deps {
    local docker_path=`whereis docker | awk -F ':' '{print $2}' | awk '{print $1}'`
    local kubectl_path=`whereis kubectl | awk -F ':' '{print $2}' | tr -d ' '`
    local k3d_path=`whereis k3d | awk -F ':' '{print $2}' | tr -d ' '`
    if [ ! -z "${docker_path}" ] && [ ! -z "${kubectl_path}" ] && [ ! -z "${k3d_path}" ]; then
        log I "All dependencies installed successfully."
    else
        log W "Some dependencies are missing, retrying installation..."
        install_deps
        sleep 5
        loop_install_deps
    fi
}

function add_docker_groups {
    docker_groups=$(groups ${USER} | grep 'docker')
    if [ -z "${docker_groups}" ]; then
        log I "Adding user ${USER} to docker group..."
        sudo usermod -aG docker ${USER}
        log I "User ${USER} added to docker group. You may need to log out and log back in for the changes to take effect."
        exit 1
    fi
}

function wait_for_argo {
	# Wait first init then wait for argocd-server to be ready
	
    # sleep 5
	until kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-server -o jsonpath="{.items[0].status.containerStatuses[0].ready}" | grep -q true; do
    	log I "Waiting for argocd-server pod to be running..."
		sleep 5
	done
	log I "ArgoCD server is running, applying configuration..."
}


function add_etc_hosts_entry {
    entry_ip=${1}
    entry_host=${2}
    if ! grep -q "${entry_host}" /etc/hosts; then
        log I "Adding ${entry_ip} ${entry_host} to /etc/hosts"
        echo "${entry_ip} ${entry_host}" | sudo tee -a /etc/hosts > /dev/null
    else
        log I "/etc/hosts already contains an entry for ${entry_host}"
    fi
}