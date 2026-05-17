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
    
    # Auto-detect IP
    IP=$(curl -s --connect-timeout 5 ifconfig.me || echo "localhost")
    
    read -p "Enter Domain/IP [Default: $IP]: " u_dom </dev/tty
    raw_domain=${u_dom:-$IP}; echo "$raw_domain" > ~/.invmc_domain

    read -p "Enter Web Port [Default: 3000]: " u_port </dev/tty
    panel_port=${u_port:-3000}; echo "$panel_port" > ~/.invmc_port
    
    echo -e "\n${BLUE}=>${NC} Preparing system..."
    silent apt-get update -y
    
    if ! command -v node &> /dev/null; then
        echo -e "${BLUE}=>${NC} Installing Node.js..."
        curl -sL https://deb.nodesource.com/setup_22.x | silent sudo bash -
        silent apt-get install -y nodejs git zip
    fi
    
    echo -e "${BLUE}=>${NC} Downloading INVMC Panel..."
    rm -rf ~/invmc_temp
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_temp
    mkdir -p ~/invmc-panel
    cp -r ~/invmc_temp/panel/* ~/invmc-panel/
    rm -rf ~/invmc_temp
    
    cd ~/invmc-panel || exit
    
    echo -e "${BLUE}=>${NC} Configuring environment..."
    [ -f config.json ] && silent node -e "let fs=require('fs'),c=JSON.parse(fs.readFileSync('./config.json'));c.port=$panel_port;c.domain='$raw_domain';c.baseUri='http://$raw_domain:$panel_port';fs.writeFileSync('./config.json',JSON.stringify(c,null,2));"
    
    echo -e "${BLUE}=>${NC} Installing dependencies (Please wait)..."
    silent npm install
    silent npm run seed
    
    echo -e "\n${GREEN}=======================================${NC}"
    echo -e "${GREEN}  CREATE YOUR ADMIN ACCOUNT BELOW      ${NC}"
    echo -e "${GREEN}=======================================${NC}"
    npm run createUser </dev/tty
    
    echo -e "\n${BLUE}=>${NC} Finalizing services..."
    if ! command -v pm2 &> /dev/null; then
        silent npm install pm2 -g
    fi
    
    PORT=$panel_port silent pm2 start index.js --name "invmc-panel"
    silent pm2 save; silent pm2 startup
    
    echo -e "\n${GREEN}=======================================${NC}"
    echo -e "  🎉 INVMC Panel is now LIVE!"
    echo -e "  🌐 URL: http://$raw_domain:$panel_port"
    echo -e "  👤 Author: OddBoyXD"
    echo -e "${GREEN}=======================================${NC}"
}

install_daemon() {
    clear
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}    🐉 INVMC DAEMON AUTO-CONFIGURE    ${NC}"
    echo -e "${BLUE}=======================================${NC}"
    
    echo -e "Please paste your configuration command from the panel"
    echo -e "(Example: npm run configure -- --panel http://IP:3000 --key UUID)"
    echo -e "${BLUE}=======================================${NC}"
    read -p "Command: " cfg_cmd </dev/tty
    
    if [[ -z "$cfg_cmd" ]]; then echo -e "${RED}Error: Command cannot be empty.${NC}"; return; fi

    echo -e "\n${BLUE}=>${NC} Checking requirements..."
    silent apt-get update -y
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${BLUE}=>${NC} Installing Docker..."
        curl -sSL https://get.docker.com/ | silent sh
        silent systemctl enable --now docker
    fi

    # Check Node
    if ! command -v node &> /dev/null; then
        echo -e "${BLUE}=>${NC} Installing Node.js..."
        curl -sL https://deb.nodesource.com/setup_22.x | silent sudo bash -
        silent apt-get install -y nodejs git zip
    fi

    echo -e "${BLUE}=>${NC} Downloading INVMC Daemon..."
    rm -rf ~/invmc_daemon_temp
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_daemon_temp
    mkdir -p ~/invmc-daemon
    cp -r ~/invmc_daemon_temp/daemon/* ~/invmc-daemon/
    rm -rf ~/invmc_daemon_temp
    
    cd ~/invmc-daemon || exit
    
    echo -e "${BLUE}=>${NC} Installing dependencies..."
    silent npm install
    
    echo -e "${BLUE}=>${NC} Applying configuration..."
    # Execute the command provided by the user
    eval "$cfg_cmd"
    
    echo -e "${BLUE}=>${NC} Starting Daemon..."
    if ! command -v pm2 &> /dev/null; then
        silent npm install pm2 -g
    fi
    
    silent pm2 start index.js --name "invmc-daemon"
    silent pm2 save; silent pm2 startup
    
    echo -e "\n${GREEN}=======================================${NC}"
    echo -e "  ✅ INVMC Daemon installed & configured!"
    echo -e "  🚀 Your node is now connecting to the panel."
    echo -e "  👤 Author: OddBoyXD"
    echo -e "${GREEN}=======================================${NC}"
}

update_panel() {
    clear
    if [ ! -d ~/invmc-panel ] && [ ! -d ~/invmc-daemon ]; then 
        echo -e "${RED}ERROR: INVMC is not installed.${NC}"; return; 
    fi
    
    echo -e "${BLUE}Checking for updates...${NC}"
    rm -rf ~/invmc_update_temp
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_update_temp
    
    if [ -d ~/invmc-panel ]; then
        echo -e "${BLUE}=>${NC} Updating Panel..."
        cp -r ~/invmc_update_temp/panel/* ~/invmc-panel/
        cd ~/invmc-panel && silent npm install
        silent pm2 restart invmc-panel
    fi

    if [ -d ~/invmc-daemon ]; then
        echo -e "${BLUE}=>${NC} Updating Daemon..."
        cp -r ~/invmc_update_temp/daemon/* ~/invmc-daemon/
        cd ~/invmc-daemon && silent npm install
        silent pm2 restart invmc-daemon
    fi
    
    rm -rf ~/invmc_update_temp
    echo -e "\n${GREEN}Update Successful!${NC}"
}

manage_service() {
    while true; do
        clear
        echo -e "${BLUE}=======================================${NC}"
        echo -e "       INVMC SERVICE MANAGER 🛠️"
        echo -e "${BLUE}=======================================${NC}"
        echo "1. Start All"
        echo "2. Stop All"
        echo "3. Restart All"
        echo "4. View Logs"
        echo "0. Go Back"
        echo -e "${BLUE}=======================================${NC}"
        read -p "Select [0-4]: " s_choice </dev/tty
        case $s_choice in
            1) silent pm2 start all; echo -e "${GREEN}Started!${NC}"; sleep 1 ;;
            2) silent pm2 stop all; echo -e "${RED}Stopped!${NC}"; sleep 1 ;;
            3) silent pm2 restart all; echo -e "${BLUE}Restarted!${NC}"; sleep 1 ;;
            4) pm2 logs ;;
            0) break ;;
        esac
    done
}

edit_config() {
    clear
    if [ ! -d ~/invmc-panel ]; then echo -e "${RED}ERROR: Panel not installed.${NC}"; return; fi
    
    o_dom=$(cat ~/.invmc_domain 2>/dev/null || echo "localhost")
    o_port=$(cat ~/.invmc_port 2>/dev/null || echo "3000")
    
    echo -e "${BLUE}=======================================${NC}"
    echo -e "       QUICK CONFIG EDITOR ⚙️"
    echo -e "${BLUE}=======================================${NC}"
    read -p "New Domain/IP [Current: $o_dom]: " u_dom </dev/tty
    read -p "New Web Port [Current: $o_port]: " u_port </dev/tty
    
    n_dom=${u_dom:-$o_dom}; n_port=${u_port:-$o_port}
    echo "$n_dom" > ~/.invmc_domain; echo "$n_port" > ~/.invmc_port
    
    cd ~/invmc-panel || exit
    [ -f config.json ] && silent node -e "let fs=require('fs'),c=JSON.parse(fs.readFileSync('./config.json'));c.port=$n_port;c.domain='$n_dom';c.baseUri='http://$n_dom:$n_port';fs.writeFileSync('./config.json',JSON.stringify(c,null,2));"
    PORT=$n_port silent pm2 restart invmc-panel --update-env; silent pm2 save
    echo -e "\n${GREEN}Config Updated!${NC} New URL: http://$n_dom:$n_port"
}

check_status() {
    clear
    echo -e "${BLUE}=======================================${NC}"
    echo -e "         INVMC SYSTEM STATUS 📡"
    echo -e "${BLUE}=======================================${NC}"
    
    if pm2 list 2>/dev/null | grep -q "invmc-panel"; then
        if pm2 list | grep "invmc-panel" | grep -q "online"; then echo -e " 🖥️  Panel:  ${GREEN}🟢 ONLINE${NC}"; else echo -e " 🖥️  Panel:  ${RED}🔴 OFFLINE${NC}"; fi
    else echo -e " 🖥️  Panel:  ${RED}⚪ NOT INSTALLED${NC}"; fi

    if pm2 list 2>/dev/null | grep -q "invmc-daemon"; then
        if pm2 list | grep "invmc-daemon" | grep -q "online"; then echo -e " ⚙️  Daemon: ${GREEN}🟢 ONLINE${NC}"; else echo -e " ⚙️  Daemon: ${RED}🔴 OFFLINE${NC}"; fi
    else echo -e " ⚙️  Daemon: ${RED}⚪ NOT INSTALLED${NC}"; fi
    
    echo -e " 👤 Author:  OddBoyXD"
    echo -e "${BLUE}=======================================${NC}"
}

# ==========================================
# 2. MAIN MENU
# ==========================================

pause_for_enter() { echo ""; read -p "Press ENTER to return to menu..." </dev/tty; }

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
    echo -e "  2. ${BLUE}Configure${NC} INVMC Daemon (Paste command)"
    echo -e "  3. Update Panel & Daemon"
    echo -e "  4. Service Manager (Start/Stop)"
    echo -e "  5. Edit Panel Configuration"
    echo -e "  6. System Status"
    echo -e "  7. ${RED}Uninstall${NC} Everything"
    echo -e "  0. Exit"
    echo -e "${BLUE}=======================================${NC}"
    read -p "Select [0-7]: " choice </dev/tty

    case $choice in
        1) install_panel; pause_for_enter ;;
        2) install_daemon; pause_for_enter ;;
        3) update_panel; pause_for_enter ;;
        4) manage_service ;;
        5) edit_config; pause_for_enter ;;
        6) check_status; pause_for_enter ;;
        7) 
            read -p "Are you sure? This deletes EVERYTHING. (y/n): " confirm </dev/tty
            if [[ "$confirm" == "y" ]]; then
                silent pm2 stop all; silent pm2 delete all; rm -rf ~/invmc-panel ~/invmc-daemon
                echo "Uninstalled."; sleep 2
            fi ;;
        0) exit 0 ;;
    esac
done
