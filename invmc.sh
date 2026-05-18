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
    
    rm -rf ~/invmc_temp
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_temp
    mkdir -p ~/invmc-panel
    cp -r ~/invmc_temp/panel/. ~/invmc-panel/
    rm -rf ~/invmc_temp
    cd ~/invmc-panel || exit
    
    [ -f config.json ] && silent node -e "let fs=require('fs'),c=JSON.parse(fs.readFileSync('./config.json'));c.port=$panel_port;c.domain='$raw_domain';c.baseUri='http://$raw_domain:$panel_port';fs.writeFileSync('./config.json',JSON.stringify(c,null,2));"
    silent npm install
    silent npm run seed
    
    echo -e "\n${GREEN}=======================================${NC}"
    echo -e "${GREEN}  CREATE YOUR ADMIN ACCOUNT BELOW      ${NC}"
    echo -e "${GREEN}=======================================${NC}"
    npm run createUser </dev/tty
    
    if ! command -v pm2 &> /dev/null; then silent npm install pm2 -g; fi
    PORT=$panel_port silent pm2 start index.js --name "invmc-panel"
    silent pm2 save; silent pm2 startup
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

    echo -e "\n${BLUE}=>${NC} Installing Dependencies..."
    silent apt-get update -y
    if ! command -v docker &> /dev/null; then
        curl -sSL https://get.docker.com/ | silent sh
        silent systemctl enable --now docker
    fi
    if ! command -v node &> /dev/null; then
        curl -sL https://deb.nodesource.com/setup_22.x | silent sudo bash -
        silent apt-get install -y nodejs git zip
    fi

    echo -e "${BLUE}=>${NC} Downloading Daemon..."
    rm -rf ~/invmc_daemon_temp
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_daemon_temp
    mkdir -p ~/invmc-daemon
    cp -r ~/invmc_daemon_temp/daemon/. ~/invmc-daemon/
    rm -rf ~/invmc_daemon_temp
    
    cd ~/invmc-daemon || exit
    silent npm install
    
    echo -e "${BLUE}=>${NC} Applying Auto-Config..."
    eval "$cfg_cmd"
    
    if ! command -v pm2 &> /dev/null; then silent npm install pm2 -g; fi
    silent pm2 start index.js --name "invmc-daemon"
    silent pm2 save; silent pm2 startup
    echo -e "\n${GREEN}✅ INVMC Daemon Configured & Started!${NC}"
}

update_panel() {
    echo -e "${BLUE}Updating Panel & Daemon...${NC}"
    rm -rf ~/invmc_update_temp
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_update_temp
    if [ -d ~/invmc-panel ]; then
        cp -r ~/invmc_update_temp/panel/* ~/invmc-panel/
        cd ~/invmc-panel && silent npm install && silent pm2 restart invmc-panel
    fi
    if [ -d ~/invmc-daemon ]; then
        cp -r ~/invmc_update_temp/daemon/* ~/invmc-daemon/
        cd ~/invmc-daemon && silent npm install && silent pm2 restart invmc-daemon
    fi
    rm -rf ~/invmc_update_temp
    echo -e "\n${GREEN}Successfully Updated!${NC}"
}

manage_service() {
    while true; do
        clear
        echo -e "1. Start All\n2. Stop All\n3. Restart All\n4. View Logs\n0. Go Back"
        read -p "Select: " s_choice </dev/tty
        case $s_choice in
            1) silent pm2 start all; echo "Started!"; sleep 1 ;;
            2) silent pm2 stop all; echo "Stopped!"; sleep 1 ;;
            3) silent pm2 restart all; echo "Restarted!"; sleep 1 ;;
            4) pm2 logs ;;
            0) break ;;
        esac
    done
}

edit_config() {
    if [ ! -d ~/invmc-panel ]; then echo "Not installed."; return; fi
    o_dom=$(cat ~/.invmc_domain 2>/dev/null || echo "localhost")
    o_port=$(cat ~/.invmc_port 2>/dev/null || echo "3000")
    read -p "New Domain [$o_dom]: " n_dom </dev/tty
    read -p "New Port [$o_port]: " n_port </dev/tty
    n_dom=${n_dom:-$o_dom}; n_port=${n_port:-$o_port}
    echo "$n_dom" > ~/.invmc_domain; echo "$n_port" > ~/.invmc_port
    cd ~/invmc-panel || exit
    [ -f config.json ] && silent node -e "let fs=require('fs'),c=JSON.parse(fs.readFileSync('./config.json'));c.port=$n_port;c.domain='$n_dom';c.baseUri='http://$n_dom:$n_port';fs.writeFileSync('./config.json',JSON.stringify(c,null,2));"
    pm2 restart invmc-panel --update-env && pm2 save
    echo "Config Updated!"
}

# ==========================================
# 2. MAIN LOGIC (ARGUMENTS + MENU)
# ==========================================

# Direct Command Handling
if [[ "$1" == "configure" ]]; then
    shift
    # Construct the full npm command from provided arguments
    full_cmd="npm run configure -- $@"
    install_daemon "$full_cmd"
    exit 0
fi

pause_for_enter() { echo ""; read -p "Press ENTER to return..." </dev/tty; }

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
    echo -e "  1. ${GREEN}Install${NC} INVMC Panel"
    echo -e "  2. ${BLUE}Configure${NC} Daemon (Paste command)"
    echo -e "  3. Update Panel & Daemon"
    echo -e "  4. Service Manager"
    echo -e "  5. Edit Config\n  6. Status\n  7. Uninstall\n  0. Exit"
    echo -e "${BLUE}=======================================${NC}"
    read -p "Select [0-7]: " choice </dev/tty
    case $choice in
        1) install_panel; pause_for_enter ;;
        2) install_daemon; pause_for_enter ;;
        3) update_panel; pause_for_enter ;;
        4) manage_service ;;
        5) edit_config; pause_for_enter ;;
        6) clear; pm2 list; pause_for_enter ;;
        7) silent pm2 stop all; silent pm2 delete all; rm -rf ~/invmc-panel ~/invmc-daemon; echo "Done."; sleep 2 ;;
        0) exit 0 ;;
    esac
done
