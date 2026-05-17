<p align="center">
  <img src="https://i.ibb.co/mrHNJD2y/WB-2.png" width="96" height="96" alt="INVMC Logo">
</p>

<h1 align="center">INVMC Panel</h1>

<p align="center">
  The core web interface for the INVMC management suite. A modern, fast, and secure frontend for your gaming infrastructure.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Component-Frontend-blue?style=flat-square" alt="Component">
  <img src="https://img.shields.io/badge/Framework-Node.js-indigo?style=flat-square" alt="Framework">
  <img src="https://img.shields.io/badge/Author-OddBoyXD-blue?style=flat-square" alt="Author">
</p>

---

## 🚀 Features

- **Dynamic UI**: Fully responsive and themed with a professional dark mode.
- **Unified Settings**: Change logos, links, and names directly from the Admin panel.
- **Server Control**: Real-time console, file management, and power controls.
- **Multi-Game Support**: Optimized for Minecraft, Discord Bots, and more.

## 🛠️ Manual Installation

If you are not using the main `invmc.sh` installer, you can set up the panel manually:

1. **Install Node.js 22**:
   ```bash
   curl -sL https://deb.nodesource.com/setup_22.x | sudo bash -
   sudo apt-get install -y nodejs
   ```

2. **Clone and Enter Directory**:
   ```bash
   git clone https://github.com/OddBoyXdxd69/INVMC-Panel
   cd INVMC-Panel/panel
   ```

3. **Install Dependencies**:
   ```bash
   npm install
   ```

4. **Initialize Database**:
   ```bash
   npm run seed
   npm run createUser
   ```

5. **Start with PM2**:
   ```bash
   npm install pm2 -g
   pm2 start index.js --name "invmc-panel"
   ```

## 📂 Structure

- `index.js`: Main entry point.
- `/views`: EJS templates for the frontend.
- `/routes`: Express route handlers.
- `/handlers`: Database and utility handlers.
- `/storage`: Local database and theme configuration.

---

<p align="center">
  © 2026 INVMC | Developed by <b>OddBoyXD</b>
</p>
