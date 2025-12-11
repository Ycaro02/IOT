#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

function check_website_running() {
    local domain=${1}
    local number=${2}

    curl 192.168.56.110 -H "host: ${domain}" 2>/dev/null | grep "Je suis l'application ${number}" >/dev/null
    if [ $? -eq 0 ]; then
        echo -e ${GREEN}"[OK]${NC} Website ${number} via domain ${domain}."
    else
        echo -e ${RED}"[KO]${NC} Website ${number} via domain ${domain}!"
    fi
}

check_website_running "app1.com" 1
check_website_running "app2.com" 2
check_website_running "app3.com" 3
check_website_running "192.168.56.110" 3
