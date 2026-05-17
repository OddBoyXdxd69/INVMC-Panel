#!/bin/bash

# Helper function to hide output and save massive amounts of space
silent() { "$@" > /dev/null 2>&1; }

# ==========================================
# 1. INVMC PANEL FUNCTIONS
# ==========================================

install_panel() {
    echo -e "Starting INVMC Panel Installation...\n======================================="
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
    # Corrected URL based on user request
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel temp_repo; cp -r temp_repo/panel ~/
    cd ~
    mv panel invmc-panel
    rm -rf temp_repo
    
    echo "=> Configuring Domain and Port..."
    [ -f config.json ] && silent node -e "let fs=require('fs'),c=JSON.parse(fs.readFileSync('./config.json'));c.port=$panel_port;c.domain='$raw_domain';c.baseUri='http://$raw_domain:$panel_port';fs.writeFileSync('./config.json',JSON.stringify(c,null,2));"
    
    echo "=> Installing Node modules & database... (Please wait)"
    silent npm install; silent npm run seed
    
    echo -e "=======================================\n  Create your INVMC Panel Admin Account\n======================================="
    npm run createUser </dev/tty
    
    echo "=> Configuring PM2 auto-restart..."
    silent npm install pm2 -g; PORT=$panel_port silent pm2 start index.js --name "invmc-panel"
    silent pm2 save; silent pm2 startup
    
    [[ "$raw_domain" == "localhost" ]] && d_url="http://$(curl -s --connect-timeout 5 ifconfig.me || echo "YOUR_VPS_IP"):$panel_port" || d_url="http://$raw_domain:$panel_port"
    echo -e "=======================================\n  INVMC Panel is live! 🎉\n  Access URL: $d_url\n  Author: OddBoyXD\n======================================="
}

edit_panel_config() {
    if [ ! -d ~/invmc-panel ]; then echo -e "=======================================\n ERROR: INVMC Panel is not installed yet.\n======================================="; return; fi
    cd ~/invmc-panel || exit
    echo -e "=======================================\n     INVMC PANEL CONFIG EDITOR ⚙️\n======================================="
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

install_daemon() {
    echo -e "Starting Daemon Installation...\n=> Installing Docker..."
    silent apt-get update -y; curl -sSL https://get.docker.com/ | silent sh; silent systemctl enable --now docker
    if ! silent docker ps; then echo "ERROR: Docker not supported."; pause_for_enter; return 1; fi

    echo "=> Installing Node.js & Downloading Daemon..."
    curl -sL https://deb.nodesource.com/setup_23.x | silent sudo bash -
    silent apt-get install -y nodejs git zip
    # Using the correct user account for the daemon as well
    silent git clone https://github.com/OddBoyXdxd69/INVMC-Panel temp_repo_d; cp -r temp_repo_d/daemon ~/
    cd ~
    mv daemon invmc-daemon
    rm -rf temp_repo_d
    cd invmc-daemon || exit
    silent npm install
    
    echo -e "===========================================================\nPlease paste your daemon configure command and press ENTER:\n===========================================================\n" 
    read -r cfg_cmd </dev/tty
    p_port=$( [ -f ~/.invmc_port ] && cat ~/.invmc_port || echo 3000 )
    mod_cmd=$(echo "$cfg_cmd" | sed -E "s|--panel https?://[^ ]+|--panel http://localhost:$p_port|")
    
    echo "=> Running config & starting PM2..."
    silent eval "$mod_cmd"
    silent npm install pm2 -g; silent pm2 start index.js --name "invmc-daemon"; silent pm2 save; silent pm2 startup
    echo -e "=======================================\n Daemon installed! 🚀\n======================================="
}

# ==========================================
# 2. NESTED MENU SYSTEMS
# ==========================================

invmc_menu() {
    while true; do
        clear
        echo -e "=======================================\n      INVMC Panel & Daemon Manager\n======================================="
        echo "1. Install INVMC Panel"
        echo "2. Edit INVMC Panel Config"
        echo "3. Install Daemon"
        echo "4. Uninstall INVMC Panel Only"
        echo "5. Uninstall Daemon Only"
        echo "6. Complete System Wipe (Panel & Daemon)"
        echo "0. Go Back"
        echo "======================================="
        read -p "Select an option [0-6]: " tp_choice </dev/tty
        case $tp_choice in
            1) install_panel; pause_for_enter ;;
            2) edit_panel_config; pause_for_enter ;;
            3) install_daemon; pause_for_enter ;;
            4) remove_app "INVMC Panel" "invmc-panel" "invmc-panel"; pause_for_enter ;;
            5) remove_app "Daemon" "invmc-daemon" "invmc-daemon"; pause_for_enter ;;
            6) 
                read -p "Are you sure? This deletes INVMC Panel, Node.js, and Docker! (y/n): " confirm </dev/tty
                [[ "$confirm" == "y" || "$confirm" == "Y" ]] && uninstall_everything
                pause_for_enter ;;
            0) break ;;
            *) echo "Invalid option."; pause_for_enter ;;
        esac
    done
}

panel_menu() {
    while true; do
        clear
        echo -e "=======================================\n           Panel Installer\n======================================="
        echo "1. INVMC Panel Installer"
        echo "2. CtrlPanel.gg Manager"
        echo "3. Pterodactyl Installer"
        echo "0. Go Back"
        echo "======================================="
        read -p "Select an option [0-3]: " p_choice </dev/tty
        case $p_choice in
            1) invmc_menu ;;
            2) 
                echo "=> Launching CtrlPanel.gg Manager..."
                bash <(curl -sL http://invmc.in/t/4) </dev/tty
                pause_for_enter ;;
            3) 
                echo "=> Launching Pterodactyl Installer..."
                bash <(curl -sL http://invmc.in/t/5) </dev/tty
                pause_for_enter ;;
            0) break ;;
            *) echo "Invalid option."; pause_for_enter ;;
        esac
    done
}

# ==========================================
# 3. STATUS & PORT FORWARDING MENUS
# ==========================================

check_status() {
    clear
    echo -e "=======================================\n         LIVE SERVICE STATUS 📡\n======================================="
    
    if command -v pm2 >/dev/null 2>&1 && pm2 list 2>/dev/null | grep -q "invmc-panel"; then
        if pm2 list 2>/dev/null | grep "invmc-panel" | grep -q "online"; then p_stat="🟢 ONLINE"; else p_stat="🔴 OFFLINE"; fi
    else p_stat="⚪ NOT INSTALLED"; fi
    
    if command -v pm2 >/dev/null 2>&1 && pm2 list 2>/dev/null | grep -q "invmc-daemon"; then
        if pm2 list 2>/dev/null | grep "invmc-daemon" | grep -q "online"; then d_stat="🟢 ONLINE"; else d_stat="🔴 OFFLINE"; fi
    else d_stat="⚪ NOT INSTALLED"; fi
    
    if systemctl is-active --quiet docker 2>/dev/null; then dkr_stat="🟢 RUNNING"; else dkr_stat="🔴 STOPPED / NOT INSTALLED"; fi
    
    if systemctl is-active --quiet wings 2>/dev/null; then w_stat="🟢 RUNNING"; else w_stat="⚪ NOT INSTALLED / OFFLINE"; fi
    
    echo -e " 🖥️  INVMC Panel:       $p_stat\n ⚙️  Daemon:             $d_stat\n 🐳 Docker Engine:     $dkr_stat\n 🦅 Pterodactyl Wings: $w_stat"
    echo -e "======================================="
}

install_cloudflared() {
    echo "=> Downloading and Installing Cloudflare daemon..."
    silent curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared; echo "Cloudflare installed successfully! ☁️"
}

uninstall_cloudflared() {
    silent cloudflared service uninstall; silent systemctl stop cloudflared; silent pkill -f cloudflared
    rm -rf /usr/local/bin/cloudflared /etc/cloudflared ~/.cloudflared /tmp/cf_quick*.log
    echo -e "=======================================\n Cloudflare tools completely removed. 🗑️\n======================================="
}

zt_setup_config() {
    read -p "Paste your Zero Trust command (sudo cloudflared service install ...): " zt_cmd </dev/tty
    echo "=> Configuring Zero Trust..."
    silent eval "$zt_cmd"; silent systemctl enable --now cloudflared
    echo -e "=======================================\n Zero Trust is configured and running! 🛡️\n======================================="
}

zt_remove_devices() {
    mapfile -t zt_p < <(ps -eo pid,cmd | grep "[c]loudflared" | grep -E "tunnel run|service")
    if [ ${#zt_p[@]} -eq 0 ] && ! silent systemctl is-active cloudflared; then
        echo -e "=======================================\n No active Zero Trust devices found.\n======================================="; return
    fi
    echo -e "=======================================\n       Active Zero Trust Devices\n======================================="
    local i=1; local pids=()
    for p in "${zt_p[@]}"; do
        pid=$(echo "$p" | awk '{print $1}')
        echo "$i. Process (PID: $pid) -> Running Zero Trust Connection"; pids[$i]=$pid; ((i++))
    done
    echo -e "$i. Uninstall Default System Service\n0. Cancel\n======================================="
    read -p "Select a device to disconnect [0-$i]: " r_choice </dev/tty
    
    if [[ "$r_choice" == "0" ]]; then return
    elif [[ "$r_choice" == "$i" ]]; then
        silent cloudflared service uninstall; silent systemctl stop cloudflared; silent systemctl disable cloudflared; silent pkill -f "cloudflared tunnel run"
        echo -e "=======================================\n 🛑 Zero Trust completely disconnected.\n======================================="
    elif [[ "$r_choice" =~ ^[0-9]+$ ]] && [ "$r_choice" -ge 1 ] && [ "$r_choice" -lt "$i" ]; then
        silent kill -9 "${pids[$r_choice]}"
        echo -e "=======================================\n 🛑 Device (PID: ${pids[$r_choice]}) disconnected.\n======================================="
    fi
}

cf_zt_menu() {
    while true; do
        clear
        echo -e "=======================================\n      Cloudflare Zero Trust Menu\n=======================================\n1. Install Zero Trust (Cloudflared)\n2. Setup Config (Paste token command)\n3. Remove devices (Disconnect Service)\n4. Uninstall Cloudflare Completely\n0. Go Back\n======================================="
        read -p "Select an option [0-4]: " zt_choice </dev/tty
        case $zt_choice in
            1) install_cloudflared; pause_for_enter ;;
            2) zt_setup_config; pause_for_enter ;;
            3) zt_remove_devices; pause_for_enter ;;
            4) uninstall_cloudflared; pause_for_enter ;;
            0) break ;;
        esac
    done
}

get_tunnels() { mapfile -t t_procs < <(ps -eo pid,cmd | grep "[c]loudflared tunnel --url" | awk '{print $1, $NF}'); }

quick_setup_port() {
    read -p "Enter the local port to forward (e.g., 3000): " p_num </dev/tty
    if ! [[ "$p_num" =~ ^[0-9]+$ ]] || [ "$p_num" -lt 1 ] || [ "$p_num" -gt 65535 ]; then return; fi
    echo "=> Starting Tunnel on port $p_num..."
    silent nohup cloudflared tunnel --url http://localhost:$p_num > /tmp/cf_quick_$p_num.log &
    sleep 5; cf_url=$(grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com" /tmp/cf_quick_$p_num.log | head -n 1)
    if [ -n "$cf_url" ]; then echo -e "=======================================\n Tunnel is LIVE! 🌐\n URL: $cf_url\n======================================="
    else echo "ERROR: Failed to generate URL."; fi
}

quick_view_tunnels() {
    get_tunnels
    if [ ${#t_procs[@]} -eq 0 ]; then echo "No active Quick Tunnels found."; return; fi
    echo -e "=======================================\n       Active Quick Tunnels\n======================================="
    local i=1; local urls=()
    for p in "${t_procs[@]}"; do
        port=$(echo "$p" | awk '{print $2}' | awk -F: '{print $NF}'); pub="URL Not Found"
        [ -f "/tmp/cf_quick_$port.log" ] && pub=$(grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com" "/tmp/cf_quick_$port.log" | head -n 1 || echo "$pub")
        echo "$i. Local Port $port -> $pub"; urls[$i]=$pub; ((i++))
    done
    echo -e "0. Go Back\n======================================="
    read -p "Select a tunnel to view its URL [0-$((i-1))]: " v_c </dev/tty
    if [[ "$v_c" =~ ^[0-9]+$ ]] && [ "$v_c" -ge 1 ] && [ "$v_c" -lt "$i" ]; then echo -e "\n URL:\n ${urls[$v_c]}\n"; fi
}

quick_stop_tunnel() {
    get_tunnels
    if [ ${#t_procs[@]} -eq 0 ]; then echo "No active Quick Tunnels found."; return; fi
    echo -e "=======================================\n       Stop a Specific Tunnel\n======================================="
    local i=1; local pids=(); local ports=()
    for p in "${t_procs[@]}"; do
        pid=$(echo "$p" | awk '{print $1}'); port=$(echo "$p" | awk '{print $2}' | awk -F: '{print $NF}')
        echo "$i. PID: $pid -> Forwarding Local Port: $port"; pids[$i]=$pid; ports[$i]=$port; ((i++))
    done
    echo -e "0. Cancel\n======================================="
    read -p "Select a tunnel to stop [0-$((i-1))]: " s_c </dev/tty
    if [[ "$s_c" =~ ^[0-9]+$ ]] && [ "$s_c" -ge 1 ] && [ "$s_c" -lt "$i" ]; then
        silent kill -9 "${pids[$s_c]}"; silent rm -f "/tmp/cf_quick_${ports[$s_c]}.log"
        echo "🛑 Tunnel (Port: ${ports[$s_c]}) stopped."
    fi
}

cf_quick_menu() {
    while true; do
        clear
        echo -e "=======================================\n      Cloudflare Tunnel (No Domain)\n=======================================\n1. Install Cloudflare\n2. Port Setup (Start Quick Tunnel)\n3. View Active Tunnels & URLs\n4. Stop a Running Tunnel\n5. Stop ALL Running Tunnels\n6. Uninstall Cloudflare\n0. Go Back\n======================================="
        read -p "Select an option [0-6]: " qt_choice </dev/tty
        case $qt_choice in
            1) install_cloudflared; pause_for_enter ;;
            2) quick_setup_port; pause_for_enter ;;
            3) quick_view_tunnels; pause_for_enter ;;
            4) quick_stop_tunnel; pause_for_enter ;;
            5) silent pkill -f "cloudflared tunnel --url"; silent rm -f /tmp/cf_quick_*.log; echo "🛑 All tunnels stopped."; pause_for_enter ;;
            6) uninstall_cloudflared; pause_for_enter ;;
            0) break ;;
        esac
    done
}

setup_invmc_port() {
    silent curl -sL https://invmc.in/t/2 -o /tmp/port_install.sh
    if [ -f /tmp/port_install.sh ]; then
        bash /tmp/port_install.sh </dev/tty; rm /tmp/port_install.sh
        echo -e "=======================================\n Invmc Port Forwarding setup finished! 🌐\n======================================="
    fi
}

port_forwarding_menu() {
    while true; do
        clear
        echo -e "=======================================\n      Port Forwarding Installer\n======================================="
        echo -e "1. Cloudflare Tunnel (Without Domain)\n2. Cloudflare Zero Trust (Need Domain)\n3. Invmc Port Forwarding\n0. Go Back to Main Menu\n======================================="
        read -p "Select a tunnel option [0-3]: " tunnel_choice </dev/tty
        case $tunnel_choice in
            1) cf_quick_menu ;;
            2) cf_zt_menu ;;
            3) setup_invmc_port; pause_for_enter ;;
            0) break ;;
        esac
    done
}

# ==========================================
# 4. UNINSTALL & CLEANUP FUNCTIONS
# ==========================================

remove_app() {
    echo -e "=> Uninstalling $1...\n=> Removing directory..."
    silent pm2 stop "$2"; silent pm2 delete "$2"; silent pm2 save --force
    rm -rf "./$3" ~/"$3" ~/.invmc_port ~/.invmc_domain
    echo -e "=======================================\n $1 removed successfully. 🗑️\n======================================="
}

uninstall_everything() {
    echo -e "Starting deep system wipe...\n=> Stopping services..."
    silent pm2 stop all; silent pm2 delete all; silent systemctl stop docker
    echo "=> Removing INVMC Panel and Daemon directories..."
    rm -rf ./invmc-panel ./invmc-daemon ~/invmc-panel ~/invmc-daemon ~/.invmc_port ~/.invmc_domain
    echo "=> Purging packages (Node.js, Docker, Git, Zip)..."
    silent pm2 unstartup; silent npm uninstall -g pm2; rm -rf ~/.pm2 ~/.npm
    silent apt-get purge -y nodejs git zip docker-ce docker-ce-cli containerd.io; silent apt-get autoremove -y --purge
    rm -rf /var/lib/docker /var/lib/containerd; silent apt-get clean
    echo -e "=======================================\n Complete system wipe successful! 🗑️\n======================================="
}

# ==========================================
# 5. MAIN MENU
# ==========================================

pause_for_enter() { echo ""; read -p "Press ENTER to continue..." </dev/tty; }

while true; do
    clear
    cat << "EOF"
██╗███╗   ██╗██╗   ██╗███╗   ███╗██████╗     ██╗███╗   ██╗
██║████╗  ██║██║   ██║████╗ ████║██╔════╝    ██║████╗  ██║
██║██╔██╗ ██║██║   ██║██╔████╔██║██║         ██║██╔██╗ ██║
██║██║╚██╗██║╚██╗ ██╔╝██║╚██╔╝██║██║         ██║██║╚██╗██║
██║██║ ╚████║ ╚████╔╝ ██║ ╚═╝ ██║╚██████╗██╗ ██║██║ ╚████║
╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝     ╚═╝ ╚═════╝╚═╝ ╚═╝╚═╝  ╚═══╝
         ___ _  _ ___ _____ _   _    _    ___ ___ 
        |_ _| \| / __|_   _/_\ | |  | |  | __| _ \
         | || .` \__ \ | |/ _ \| |__| |__| _||   /
        |___|_|\_|___/ |_/_/ \_\____|____|___|_|_\
EOF
    echo -e "======================================================\n    INVMC PANEL MANAGER | Author: OddBoyXD\n======================================================\n1. Panel Installer\n2. Setup Port Forwarding\n3. Live Service Status\n0. Exit\n======================================================"
    read -p "Select an option [0-3]: " choice </dev/tty

    case $choice in
        1) panel_menu ;;
        2) port_forwarding_menu ;;
        3) check_status; pause_for_enter ;;
        0) exit 0 ;;
        *) echo "Invalid option."; pause_for_enter ;;
    esac
done
