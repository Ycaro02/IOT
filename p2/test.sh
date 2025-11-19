#!/bin/bash


GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

function check_website_running() {
    local url=${1}
    local number=${2}

    curl ${url} 2>/dev/null | grep "app${number}" >/dev/null
    if [ $? -eq 0 ]; then
        echo -e ${GREEN}"[OK]${NC} Website ${number} via url ${url}."
    else
        echo -e ${RED}"[KO]${NC} Website ${number} via url ${url}!"
    fi
}

check_website_running "http://app1.com" 1
check_website_running "http://app2.com" 2
check_website_running "http://app3.com" 3
check_website_running "http://192.168.56.110" 3