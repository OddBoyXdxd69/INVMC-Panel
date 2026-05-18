#!/bin/bash
# INVMC PANEL ULTIMATE MANAGER | Author: OddBoyXD
silent() { "$@" > /dev/null 2>&1; }
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

install_panel() {
    clear
    echo -e "${BLUE}🚀 INVMC PANEL SETUP${NC}"
    IP=$(curl -s ifconfig.me || echo "localhost")
    read -p "Domain/IP [$IP]: " u_dom </dev/tty
    raw_domain=${u_dom:-$IP}
    read -p "Web Port [3000]: " u_port </dev/tty
    panel_port=${u_port:-3000}
    
    mkdir -p /root/invmc-panel
    cd /root || exit
    rm -rf /root/invmc_temp
    git clone https://github.com/OddBoyXdxd69/INVMC-Panel /root/invmc_temp
    cp -r /root/invmc_temp/panel/* /root/invmc-panel/
    
    cd /root/invmc-panel || exit
    npm install; npm run seed
    npm run createUser </dev/tty
    pm2 start index.js --name "invmc-panel"
}

install_daemon() {
    local cfg_cmd="$1"
    if [[ -z "$cfg_cmd" ]]; then
        clear
        echo -e "${BLUE}🐉 INVMC DAEMON SETUP${NC}"
        read -p "Config Command: " cfg_cmd </dev/tty
    fi
    
    mkdir -p /root/invmc-daemon
    cd /root || exit
    rm -rf /root/invmc_daemon_temp
    git clone https://github.com/OddBoyXdxd69/INVMC-Panel /root/invmc_daemon_temp
    cp -r /root/invmc_daemon_temp/daemon/* /root/invmc-daemon/
    
    cd /root/invmc-daemon || exit
    npm install
    eval "$cfg_cmd"
    pm2 delete invmc-daemon 2>/dev/null
    pm2 start index.js --name "invmc-daemon"
}

if [[ "$1" == "configure" ]]; then
    shift
    install_daemon "npm run configure -- $@"
    exit 0
fi

while true; do
    clear
    echo -e "${BLUE}INVMC MANAGER${NC}\n1. Install Panel\n2. Configure Daemon\n0. Exit"
    read -p "Select: " c </dev/tty
    case $c in
        1) install_panel ;;
        2) install_daemon ;;
        0) exit 0 ;;
    esac
done
