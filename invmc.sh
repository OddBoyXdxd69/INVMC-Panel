#!/bin/bash

# Helper function to hide output and save massive amounts of space
silent() { "$@" > /dev/null 2>&1; }

# ==========================================
# 1. CORE FUNCTIONS
# ==========================================

install_panel() {
    echo -e "\nStarting INVMC Panel Installation...\n======================================="
    read -p "Enter Domain/IP for INVMC Panel (e.g., example.com) [Press ENTER for localhost]: " u_dom </dev/tty
    raw_domain=${u_dom:-localhost}; echo "$raw_domain" > ~/.invmc_domain

    read -p "Enter Web Port for INVMC Panel [Press ENTER for default 3000]: " u_port </dev/tty
    panel_port=${u_port:-3000}; echo "$panel_port" > ~/.invmc_port
    echo "======================================="
    
    echo "=> Updating packages & installing Node.js..."
    silent apt-get update -y
    curl -sL https://deb.nodesource.com/setup_23.x | silent sudo bash -
    silent apt-get install -y nodejs git zip
    
    echo "=> Downloading INVMC Panel files..."
    rm -rf ~/invmc_temp
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_temp
    mkdir -p ~/invmc-panel
    cp -r ~/invmc_temp/panel/* ~/invmc-panel/
    rm -rf ~/invmc_temp
    
    cd ~/invmc-panel || exit
    
    echo "=> Configuring Domain and Port..."
    [ -f config.json ] && silent node -e "let fs=require('fs'),c=JSON.parse(fs.readFileSync('./config.json'));c.port=$panel_port;c.domain='$raw_domain';c.baseUri='http://$raw_domain:$panel_port';fs.writeFileSync('./config.json',JSON.stringify(c,null,2));"
    
    echo "=> Installing Node modules & database... (Please wait)"
    silent npm install; silent npm run seed
    
    echo -e "=======================================\n  Create your INVMC Admin Account\n======================================="
    npm run createUser </dev/tty
    
    echo "=> Configuring PM2 auto-restart..."
    silent npm install pm2 -g; PORT=$panel_port silent pm2 start index.js --name "invmc-panel"
    silent pm2 save; silent pm2 startup
    
    [[ "$raw_domain" == "localhost" ]] && d_url="http://$(curl -s --connect-timeout 5 ifconfig.me || echo "YOUR_VPS_IP"):$panel_port" || d_url="http://$raw_domain:$panel_port"
    echo -e "=======================================\n  INVMC Panel is live! 🎉\n  Access URL: $d_url\n  Author: OddBoyXD\n======================================="
}

update_panel() {
    if [ ! -d ~/invmc-panel ]; then echo "ERROR: INVMC Panel is not installed."; return; fi
    echo -e "=> Starting INVMC Panel Update...\n=> Pulling latest code from GitHub..."
    rm -rf ~/invmc_update_temp
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel ~/invmc_update_temp
    
    echo "=> Merging updates..."
    cp -r ~/invmc_update_temp/panel/* ~/invmc-panel/
    rm -rf ~/invmc_update_temp
    
    cd ~/invmc-panel || exit
    echo "=> Re-installing dependencies..."
    silent npm install
    
    echo "=> Restarting Panel..."
    silent pm2 restart invmc-panel
    echo -e "=======================================\n Update Complete! ✅\n======================================="
}

manage_service() {
    while true; do
        clear
        echo -e "=======================================\n       PANEL SERVICE MANAGER 🛠️\n======================================="
        echo "1. Start Panel"
        echo "2. Stop Panel"
        echo "3. Restart Panel"
        echo "4. View Live Logs"
        echo "0. Go Back"
        echo "======================================="
        read -p "Select an option [0-4]: " s_choice </dev/tty
        case $s_choice in
            1) silent pm2 start invmc-panel; echo "Started!"; sleep 1 ;;
            2) silent pm2 stop invmc-panel; echo "Stopped!"; sleep 1 ;;
            3) silent pm2 restart invmc-panel; echo "Restarted!"; sleep 1 ;;
            4) pm2 logs invmc-panel ;;
            0) break ;;
        esac
    done
}

edit_config() {
    if [ ! -d ~/invmc-panel ]; then echo "ERROR: INVMC Panel is not installed."; return; fi
    cd ~/invmc-panel || exit
    echo -e "=======================================\n     INVMC CONFIG EDITOR ⚙️\n======================================="
    o_dom=$(cat ~/.invmc_domain 2>/dev/null || echo "localhost")
    o_port=$(cat ~/.invmc_port 2>/dev/null || echo "3000")
    
    read -p "Enter NEW Domain/IP [Current: $o_dom] (Press ENTER to keep): " u_dom </dev/tty
    read -p "Enter NEW Web Port [Current: $o_port] (Press ENTER to keep): " u_port </dev/tty
    n_dom=${u_dom:-$o_dom}; n_port=${u_port:-$o_port}
    echo "$n_dom" > ~/.invmc_domain; echo "$n_port" > ~/.invmc_port
    
    echo "=> Updating config.json & Restarting..."
    [ -f config.json ] && silent node -e "let fs=require('fs'),c=JSON.parse(fs.readFileSync('./config.json'));c.port=$n_port;c.domain='$n_dom';c.baseUri='http://$n_dom:$n_port';fs.writeFileSync('./config.json',JSON.stringify(c,null,2));"
    PORT=$n_port silent pm2 restart invmc-panel --update-env; silent pm2 save
    echo -e "=======================================\n Updated! ✅ New URL: http://$n_dom:$n_port\n======================================="
}

check_status() {
    clear
    echo -e "=======================================\n         SYSTEM STATUS 📡\n======================================="
    if command -v pm2 >/dev/null 2>&1 && pm2 list 2>/dev/null | grep -q "invmc-panel"; then
        if pm2 list 2>/dev/null | grep "invmc-panel" | grep -q "online"; then p_stat="🟢 ONLINE"; else p_stat="🔴 OFFLINE"; fi
    else p_stat="⚪ NOT INSTALLED"; fi
    
    cur_v=$(cd ~/invmc-panel 2>/dev/null && node -e "console.log(require('./package.json').version)" || echo "N/A")
    
    echo -e " 🖥️  INVMC Panel:  $p_stat"
    echo -e " 📦 Version:      $cur_v"
    echo -e " 👤 Author:       OddBoyXD"
    echo -e "======================================="
}

uninstall_panel() {
    read -p "Are you sure you want to delete INVMC Panel? (y/n): " confirm </dev/tty
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "=> Removing INVMC Panel..."
        silent pm2 stop invmc-panel; silent pm2 delete invmc-panel; silent pm2 save --force
        rm -rf ~/invmc-panel ~/.invmc_port ~/.invmc_domain
        echo "Done."
    fi
}

# ==========================================
# 2. MAIN MENU
# ==========================================

pause_for_enter() { echo ""; read -p "Press ENTER to continue..." </dev/tty; }

while true; do
    clear
    cat << "EOF"
██╗███╗   ██╗██╗   ██╗███╗   ███╗██████╗ 
██║████╗  ██║██║   ██║████╗ ████║██╔════╝ 
██║██╔██╗ ██║██║   ██║██╔████╔██║██║      
██║██║╚██╗██║╚██╗ ██╔╝██║╚██╔╝██║██║      
██║██║ ╚████║ ╚████╔╝ ██║ ╚═╝ ██║╚██████╗ 
╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝     ╚═╝ ╚═════╝ 
        PANEL MANAGER | OddBoyXD
EOF
    echo -e "======================================="
    echo "1. Install INVMC Panel"
    echo "2. Update Panel Code"
    echo "3. Service Manager (Start/Stop)"
    echo "4. Edit Configuration"
    echo "5. Check Status"
    echo "6. Uninstall Panel"
    echo "0. Exit"
    echo "======================================="
    read -p "Select an option [0-6]: " choice </dev/tty

    case $choice in
        1) install_panel; pause_for_enter ;;
        2) update_panel; pause_for_enter ;;
        3) manage_service ;;
        4) edit_config; pause_for_enter ;;
        5) check_status; pause_for_enter ;;
        6) uninstall_panel; pause_for_enter ;;
        0) exit 0 ;;
        *) echo "Invalid option."; pause_for_enter ;;
    esac
done
