/**
 * INVMC Daemon
 * High-performance node management service
 */
process.env.dockerSocket = process.platform === "win32" ? "//./pipe/docker_engine" : "/var/run/docker.sock";
const express = require('express');
const Docker = require('dockerode');
const basicAuth = require('express-basic-auth');
const bodyParser = require('body-parser');
const CatLoggr = require('cat-loggr');
const WebSocket = require('ws');
const http = require('http');
const fs = require('node:fs');
const path = require('node:path');
const chalk = require('chalk');
const os = require('os');

const log = new CatLoggr();
const config = JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8'));
const docker = new Docker({ socketPath: process.env.dockerSocket });

const { init, createVolumesFolder } = require('./handlers/init.js');
const { seed } = require('./handlers/seed.js');
const { getVolumeSize } = require('./handlers/db.js');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const ascii = fs.readFileSync(path.join(__dirname, 'handlers', 'ascii.txt'), 'utf8');
console.log(chalk.gray(ascii) + chalk.white(`\nVersion v${config.version}\n`));

init();
createVolumesFolder();
seed();

app.use(bodyParser.json());
app.use(basicAuth({
    users: { 'INVMC': config.key },
    challenge: true
}));

// Route Imports
const instanceRouter = require('./routes/Instance.js');
const deploymentRouter = require('./routes/Deploy.js');
const powerRouter = require('./routes/PowerActions.js');
const archiveRouter = require('./routes/ArchiveVolume.js');
const filesystemRouter = require('./routes/Volume.js');

// Mounting Routes
app.use('/instances', instanceRouter);
app.use('/instances', deploymentRouter);
app.use('/instances', powerRouter);
app.use('/archive', archiveRouter);
app.use('/fs', filesystemRouter);

app.get('/stats', async (req, res) => {
    try {
        const stats = {
            memory: {
                total: os.totalmem(),
                used: os.totalmem() - os.freemem(),
                percent: (((os.totalmem() - os.freemem()) / os.totalmem()) * 100).toFixed(2)
            },
            cpu: {
                usage: (os.loadavg()[0] * 100 / os.cpus().length).toFixed(2),
                cores: os.cpus().length
            },
            uptime: `${Math.floor(os.uptime() / 86400)}d ${Math.floor((os.uptime() % 86400) / 3600)}h`,
            status: 'Online',
            timestamp: Date.now()
        };
        res.json(stats);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.get('/', async (req, res) => {
    try {
        const dockerInfo = await docker.info();
        res.json({ status: 'Online', docker: dockerInfo });
    } catch (e) {
        res.status(500).json({ status: 'Error', error: e.message });
    }
});

// WebSocket Handler
wss.on('connection', (ws, req) => {
    let isAuthenticated = false;
    let currentContainer = null;
    let logStream = null;
    let statsTask = null;

    ws.on('message', async (message) => {
        let msg = {};
        try { msg = JSON.parse(message); } catch (e) { return; }

        if (msg.event === 'auth' && msg.args) {
            if (msg.args[0] === config.key) {
                isAuthenticated = true;
                const parts = req.url.split('/');
                const type = parts[1]; // exec or stats
                const containerId = parts[2];

                if (!containerId) return ws.close(1008, "No Container ID");
                currentContainer = docker.getContainer(containerId);
                
                if (type === 'exec') setupConsole(ws, currentContainer);
                else if (type === 'stats') setupStats(ws, currentContainer, containerId);
            } else {
                ws.close(1008, "Auth Failed");
            }
        }
    });

    async function setupConsole(ws, container) {
        try {
            // 1. Send status immediately
            const data = await container.inspect();
            ws.send(JSON.stringify({ type: 'status', status: data.State.Running ? 'online' : 'offline' }));

            // 2. Stream logs using follow
            const stream = await container.logs({
                follow: true,
                stdout: true,
                stderr: true,
                tail: 50,
                timestamps: false
            });
            
            logStream = stream;

            // Stream data to WebSocket
            stream.on('data', chunk => {
                if (ws.readyState === WebSocket.OPEN) {
                    ws.send(chunk.toString('utf8'));
                }
            });

            // Handle browser commands (via a separate attach stream for input)
            ws.on('message', async (message) => {
                try {
                    const msg = JSON.parse(message);
                    if (msg.event === 'cmd' && msg.command) {
                        const input = await container.attach({ stream: true, stdin: true, stdout: false, stderr: false, hijack: true });
                        input.write(msg.command + '\n');
                        input.end();
                    }
                } catch (e) {}
            });

            stream.on('error', err => {
                console.error('Log stream error:', err);
            });

        } catch (e) {
            console.error('Console setup error:', e);
            ws.send(`\r\n\x1b[31m[INVMC] Console connection failed: ${e.message}\x1b[0m\r\n`);
        }
    }

    async function setupStats(ws, container, id) {
        const sendStats = async () => {
            try {
                if (ws.readyState !== WebSocket.OPEN) return;
                
                // Simpler stats (one snapshot)
                container.stats({ stream: false }, async (err, stats) => {
                    if (err || !stats) return;
                    
                    const volumeSize = await getVolumeSize(id);
                    
                    ws.send(JSON.stringify({
                        type: 'stats',
                        stats: {
                            // Basic CPU usage calculation for one snapshot
                            cpu: { usage: stats.cpu_stats.online_cpus || 1 }, 
                            memory: { used: stats.memory_stats.usage },
                            disk: { used: volumeSize * 1024 * 1024 },
                            status: stats.memory_stats.usage > 0 ? 'online' : 'offline'
                        }
                    }));
                });
            } catch (e) {}
        };
        sendStats();
        statsTask = setInterval(sendStats, 3000);
    }

    ws.on('close', () => {
        if (logStream) logStream.destroy();
        if (statsTask) clearInterval(statsTask);
    });
});

server.listen(config.port, () => log.info(`INVMC Daemon listening on port ${config.port}`));

// Global Error Handler
app.use((err, req, res, next) => {
    log.error(err.stack);
    res.status(500).send('Daemon Error');
});
