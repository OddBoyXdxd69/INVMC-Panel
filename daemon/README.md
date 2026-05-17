<p align="center">
  <img src="https://i.ibb.co/mrHNJD2y/WB-2.png" width="96" height="96" alt="INVMC Logo">
</p>

<h1 align="center">INVMC Daemon</h1>

<p align="center">
  The powerhouse of the INVMC suite. A high-performance node management service that handles Docker orchestration and server logic.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Component-Backend-red?style=flat-square" alt="Component">
  <img src="https://img.shields.io/badge/Orchestrator-Docker-blue?style=flat-square" alt="Docker">
  <img src="https://img.shields.io/badge/Author-OddBoyXD-blue?style=flat-square" alt="Author">
</p>

---

## ⚡ Role

The **INVMC Daemon** runs on your physical nodes. It communicates with the **INVMC Panel** to:
- Pull and manage Docker images.
- Create and monitor game server containers.
- Execute real-time power actions (Start, Stop, Kill).
- Stream console logs and resource statistics via WebSockets.

## 🛠️ Manual Installation

If you are not using the main `invmc.sh` installer, you can set up the daemon manually:

1. **Install Docker & Node.js**:
   ```bash
   curl -sSL https://get.docker.com/ | sh
   curl -sL https://deb.nodesource.com/setup_22.x | sudo bash -
   sudo apt-get install -y nodejs
   ```

2. **Clone and Enter Directory**:
   ```bash
   git clone https://github.com/OddBoyXdxd69/INVMC-Panel
   cd INVMC-Panel/daemon
   ```

3. **Install Dependencies**:
   ```bash
   npm install
   ```

4. **Configuration**:
   Copy the configuration command from your INVMC Panel (Admin > Nodes -> Create/Configure) and run it in this directory.

5. **Start with PM2**:
   ```bash
   npm install pm2 -g
   pm2 start index.js --name "invmc-daemon"
   ```

## 📂 Structure

- `index.js`: Main API server.
- `/routes`: Node-specific API routes.
- `/handlers`: Docker and system interaction logic.
- `/volumes`: Where your game server data is stored.

---

<p align="center">
  © 2026 INVMC | Authored by <b>OddBoyXD</b>
</p>
