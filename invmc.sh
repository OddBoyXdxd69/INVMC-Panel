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

update_panel() {
    clear
    if [ ! -d ~/invmc-panel ]; then echo -e "${RED}ERROR: INVMC Panel is not installed.${NC}"; return; fi
    
    echo -e "${BLUE}Updating INVMC Panel to the latest version...${NC}"
    rm -rf ~/invmc_update_temp
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_update_temp
    
    echo -e "${BLUE}=>${NC} Syncing new code..."
    cp -r ~/invmc_update_temp/panel/* ~/invmc-panel/
    rm -rf ~/invmc_update_temp
    
    cd ~/invmc-panel || exit
    echo -e "${BLUE}=>${NC} Checking dependencies..."
    silent npm install
    
    echo -e "${BLUE}=>${NC} Restarting panel..."
    silent pm2 restart invmc-panel
    echo -e "\n${GREEN}Update Successful!${NC}"
}

manage_service() {
    while true; do
        clear
        echo -e "${BLUE}=======================================${NC}"
        echo -e "       INVMC SERVICE MANAGER 🛠️"
        echo -e "${BLUE}=======================================${NC}"
        echo "1. Start Panel"
        echo "2. Stop Panel"
        echo "3. Restart Panel"
        echo "4. View Real-time Logs"
        echo "0. Go Back"
        echo -e "${BLUE}=======================================${NC}"
        read -p "Select [0-4]: " s_choice </dev/tty
        case $s_choice in
            1) silent pm2 start invmc-panel; echo -e "${GREEN}Started!${NC}"; sleep 1 ;;
            2) silent pm2 stop invmc-panel; echo -e "${RED}Stopped!${NC}"; sleep 1 ;;
            3) silent pm2 restart invmc-panel; echo -e "${BLUE}Restarted!${NC}"; sleep 1 ;;
            4) echo "Press Ctrl+C to stop viewing logs..."; sleep 2; pm2 logs invmc-panel ;;
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
        if pm2 list | grep "invmc-panel" | grep -q "online"; then echo -e " 🖥️  Panel: ${GREEN}🟢 ONLINE${NC}"; else echo -e " 🖥️  Panel: ${RED}🔴 OFFLINE${NC}"; fi
    else echo -e " 🖥️  Panel: ${RED}⚪ NOT INSTALLED${NC}"; fi
    
    cur_v=$(cd ~/invmc-panel 2>/dev/null && node -e "console.log(require('./package.json').version)" || echo "N/A")
    echo -e " 📦 Version: $cur_v"
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
    echo -e "  1. ${GREEN}Install${NC} INVMC Panel (One-Click)"
    echo -e "  2. ${BLUE}Update${NC} Panel (From GitHub)"
    echo -e "  3. Service Manager (Start/Stop)"
    echo -e "  4. Edit Configuration (IP/Port)"
    echo -e "  5. System Status"
    echo -e "  6. ${RED}Uninstall${NC} Panel"
    echo -e "  0. Exit"
    echo -e "${BLUE}=======================================${NC}"
    read -p "Select [0-6]: " choice </dev/tty

    case $choice in
        1) install_panel; pause_for_enter ;;
        2) update_panel; pause_for_enter ;;
        3) manage_service ;;
        4) edit_config; pause_for_enter ;;
        5) check_status; pause_for_enter ;;
        6) 
            read -p "Are you sure? This deletes EVERYTHING. (y/n): " confirm </dev/tty
            if [[ "$confirm" == "y" ]]; then
                silent pm2 stop invmc-panel; silent pm2 delete invmc-panel; rm -rf ~/invmc-panel
                echo "Uninstalled."; sleep 2
            fi ;;
        0) exit 0 ;;
    esac
done
