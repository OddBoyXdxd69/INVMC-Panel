#!/bin/bash

# ==========================================
# INVMC PANEL ULTIMATE MANAGER
# Author: OddBoyXD
# ==========================================

# Helper function to hide output
silent() { "$@" > /dev/null 2>&1; }

# Colors for better UI
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ==========================================
# 1. CORE FUNCTIONS
# ==========================================

install_panel() {
    clear
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}     🚀 INVMC PANEL ONE-CLICK SETUP    ${NC}"
    echo -e "${BLUE}=======================================${NC}"
    
    IP=$(curl -s --connect-timeout 5 ifconfig.me || echo "localhost")
    read -p "Enter Domain/IP [Default: $IP]: " u_dom </dev/tty
    raw_domain=${u_dom:-$IP}; echo "$raw_domain" > ~/.invmc_domain

    read -p "Enter Web Port [Default: 3000]: " u_port </dev/tty
    panel_port=${u_port:-3000}; echo "$panel_port" > ~/.invmc_port
    
    echo -e "\n${BLUE}=>${NC} Preparing system..."
    silent apt-get update -y
    
    if ! command -v node &> /dev/null; then
        curl -sL https://deb.nodesource.com/setup_22.x | silent sudo bash -
        silent apt-get install -y nodejs git zip
    fi
    
    echo -e "${BLUE}=>${NC} Downloading INVMC Panel..."
    rm -rf /tmp/invmc_clone
    git clone https://github.com/OddBoyXdxd69/INVMC-Panel /tmp/invmc_clone
    
    mkdir -p /root/invmc-panel
    cp -av /tmp/invmc_clone/panel/. /root/invmc-panel/
    rm -rf /tmp/invmc_clone
    
    cd /root/invmc-panel || exit
    
    echo -e "${BLUE}=>${NC} Configuring environment..."
    [ -f config.json ] && silent node -e "let fs=require('fs'),c=JSON.parse(fs.readFileSync('./config.json'));c.port=$panel_port;c.domain='$raw_domain';c.baseUri='http://$raw_domain:$panel_port';fs.writeFileSync('./config.json',JSON.stringify(c,null,2));"
    
    echo -e "${BLUE}=>${NC} Installing dependencies (Please wait)..."
    npm install --no-audit --no-fund
    npm run seed
    
    echo -e "\n${GREEN}=======================================${NC}"
    echo -e "${GREEN}  CREATE YOUR ADMIN ACCOUNT BELOW      ${NC}"
    echo -e "${GREEN}=======================================${NC}"
    npm run createUser </dev/tty
    
    if ! command -v pm2 &> /dev/null; then silent npm install pm2 -g; fi
    PORT=$panel_port pm2 start index.js --name "invmc-panel"
    pm2 save; pm2 startup
    
    echo -e "\n${GREEN}🎉 INVMC Panel is now LIVE! http://$raw_domain:$panel_port${NC}"
}

install_daemon() {
    local cfg_cmd="$1"
    
    if [[ -z "$cfg_cmd" ]]; then
        clear
        echo -e "${BLUE}=======================================${NC}"
        echo -e "${BLUE}    🐉 INVMC DAEMON AUTO-CONFIGURE    ${NC}"
        echo -e "${BLUE}=======================================${NC}"
        echo -e "Please paste your configuration command from the panel"
        read -p "Command: " cfg_cmd </dev/tty
    fi
    
    if [[ -z "$cfg_cmd" ]]; then echo -e "${RED}Error: Command empty.${NC}"; return; fi

    echo -e "\n${BLUE}=>${NC} Checking requirements..."
    silent apt-get update -y
    
    if ! command -v docker &> /dev/null; then
        curl -sSL https://get.docker.com/ | silent sh
        silent systemctl enable --now docker
    fi

    if ! command -v node &> /dev/null; then
        curl -sL https://deb.nodesource.com/setup_22.x | silent sudo bash -
        silent apt-get install -y nodejs git zip
    fi

    echo -e "${BLUE}=>${NC} Downloading INVMC Daemon..."
    rm -rf /tmp/invmc_daemon_clone
    git clone https://github.com/OddBoyXdxd69/INVMC-Panel /tmp/invmc_daemon_clone
    
    mkdir -p /root/invmc-daemon
    cp -av /tmp/invmc_daemon_clone/daemon/. /root/invmc-daemon/
    rm -rf /tmp/invmc_daemon_clone
    
    cd /root/invmc-daemon || exit
    
    echo -e "${BLUE}=>${NC} Installing dependencies..."
    npm install --no-audit --no-fund
    
    echo -e "${BLUE}=>${NC} Applying configuration..."
    eval "$cfg_cmd"
    
    if ! command -v pm2 &> /dev/null; then silent npm install pm2 -g; fi
    pm2 delete invmc-daemon 2>/dev/null
    pm2 start index.js --name "invmc-daemon"
    pm2 save
    
    echo -e "\n${GREEN}✅ INVMC Daemon installed & configured!${NC}"
}

update_all() {
    echo -e "${BLUE}Checking for updates...${NC}"
    rm -rf /tmp/invmc_update
    git clone https://github.com/OddBoyXdxd69/INVMC-Panel /tmp/invmc_update
    
    if [ -d /root/invmc-panel ]; then
        cp -av /tmp/invmc_update/panel/. /root/invmc-panel/
        cd /root/invmc-panel && npm install --no-audit --no-fund && pm2 restart invmc-panel
    fi

    if [ -d /root/invmc-daemon ]; then
        cp -av /tmp/invmc_update/daemon/. /root/invmc-daemon/
        cd /root/invmc-daemon && npm install --no-audit --no-fund && pm2 restart invmc-daemon
    fi
    
    rm -rf /tmp/invmc_update
    echo -e "\n${GREEN}Update Successful!${NC}"
}

# Direct Command Handling
if [[ "$1" == "configure" ]]; then
    shift
    install_daemon "npm run configure -- $@"
    exit 0
fi

while true; do
    clear
    cat << "EOF"
██╗███╗   ██╗██╗   ██╗███╗   ███╗██████╗ 
██║████╗  ██║██║   ██║████╗ ████║██╔════╝ 
██║██╔██╗ ██║██║   ██║██╔████╔██║██║      
██║██║╚██╗██║╚██╗ ██╔╝██║╚██╔╝██║██║      
██║██║ ╚████║ ╚████╔╝ ██║ ╚═╝ ██║╚██████╗ 
╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝     ╚═╝ ╚═════╝ 
      ULITMATE MANAGER | OddBoyXD
EOF
    echo -e "${BLUE}=======================================${NC}"
    echo -e "  1. Install INVMC Panel\n  2. Configure Daemon\n  3. Update All\n  4. Service Status\n  0. Exit"
    echo -e "${BLUE}=======================================${NC}"
    read -p "Select [0-4]: " choice </dev/tty
    case $choice in
        1) install_panel; read -p "Press Enter..." ;;
        2) install_daemon; read -p "Press Enter..." ;;
        3) update_all; read -p "Press Enter..." ;;
        4) clear; pm2 list; read -p "Press Enter..." ;;
        0) exit 0 ;;
    esac
done
