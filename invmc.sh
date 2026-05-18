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
    raw_domain=${u_dom:-$IP}; echo "$raw_domain" > ~/.invmc_domain
    read -p "Web Port [3000]: " u_port </dev/tty
    panel_port=${u_port:-3000}; echo "$panel_port" > ~/.invmc_port
    silent apt-get update -y
    if ! command -v node &> /dev/null; then curl -sL https://deb.nodesource.com/setup_22.x | silent sudo bash -; silent apt-get install -y nodejs git zip; fi
    rm -rf ~/invmc_temp
    git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_temp
    mkdir -p ~/invmc-panel
    cp -r ~/invmc_temp/panel/. ~/invmc-panel/
    rm -rf ~/invmc_temp
    cd ~/invmc-panel || exit
    [ -f config.json ] && silent node -e "let fs=require('fs'),c=JSON.parse(fs.readFileSync('./config.json'));c.port=$panel_port;c.domain='$raw_domain';c.baseUri='http://$raw_domain:$panel_port';fs.writeFileSync('./config.json',JSON.stringify(c,null,2));"
    silent npm install; silent npm run seed
    npm run createUser </dev/tty
    if ! command -v pm2 &> /dev/null; then silent npm install pm2 -g; fi
    PORT=$panel_port silent pm2 start index.js --name "invmc-panel"
    silent pm2 save; silent pm2 startup
}

install_daemon() {
    local cfg_cmd="$1"
    if [[ -z "$cfg_cmd" ]]; then
        clear
        echo -e "${BLUE}🐉 INVMC DAEMON SETUP${NC}"
        read -p "Config Command: " cfg_cmd </dev/tty
    fi
    silent apt-get update -y
    if ! command -v docker &> /dev/null; then curl -sSL https://get.docker.com/ | silent sh; silent systemctl enable --now docker; fi
    if ! command -v node &> /dev/null; then curl -sL https://deb.nodesource.com/setup_22.x | silent sudo bash -; silent apt-get install -y nodejs git zip; fi
    rm -rf ~/invmc_daemon_temp
    git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_daemon_temp
    mkdir -p ~/invmc-daemon
    cp -r ~/invmc_daemon_temp/daemon/. ~/invmc-daemon/
    rm -rf ~/invmc_daemon_temp
    cd ~/invmc-daemon || exit
    silent npm install
    eval "$cfg_cmd"
    if ! command -v pm2 &> /dev/null; then silent npm install pm2 -g; fi
    silent pm2 start index.js --name "invmc-daemon"
    silent pm2 save; silent pm2 startup
}

update_all() {
    rm -rf ~/invmc_update_temp
    git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_update_temp
    if [ -d ~/invmc-panel ]; then cp -r ~/invmc_update_temp/panel/. ~/invmc-panel/; cd ~/invmc-panel; silent npm install; pm2 restart invmc-panel; fi
    if [ -d ~/invmc-daemon ]; then cp -r ~/invmc_update_temp/daemon/. ~/invmc-daemon/; cd ~/invmc-daemon; silent npm install; pm2 restart invmc-daemon; fi
    rm -rf ~/invmc_update_temp
}

if [[ "$1" == "configure" ]]; then
    shift
    install_daemon "npm run configure -- $@"
    exit 0
fi

while true; do
    clear
    echo -e "${BLUE}INVMC MANAGER | Author: OddBoyXD${NC}"
    echo "1. Install Panel"
    echo "2. Configure Daemon"
    echo "3. Update All"
    echo "4. Service Status"
    echo "0. Exit"
    read -p "Select: " c </dev/tty
    case $c in
        1) install_panel ;;
        2) install_daemon ;;
        3) update_all ;;
        4) clear; pm2 list; read -p "Press Enter..." ;;
        0) exit 0 ;;
    esac
done
