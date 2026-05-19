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
                free: os.freemem(),
                used: os.totalmem() - os.freemem(),
                percent: ((os.totalmem() - os.freemem()) / os.totalmem() * 100).toFixed(2)
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
    let statsInterval = null;

    ws.on('message', async (message) => {
        let msg = {};
        try {
            msg = JSON.parse(message);
        } catch (e) { return; }

        if (msg.event === 'auth' && msg.args) {
            if (msg.args[0] === config.key) {
                isAuthenticated = true;
                const parts = req.url.split('/');
                const containerId = parts[2];
                const type = parts[1]; // exec or stats

                if (!containerId) return ws.close(1008, "No Container ID");

                currentContainer = docker.getContainer(containerId);
                
                if (type === 'exec') {
                    setupConsole(ws, currentContainer);
                } else if (type === 'stats') {
                    setupStats(ws, currentContainer, containerId);
                }
            } else {
                ws.close(1008, "Auth Failed");
            }
        } else if (isAuthenticated && currentContainer) {
            if (msg.event === 'cmd' && msg.command) {
                // Command handling is now inside setupConsole for direct stream access
            } else if (msg.event && msg.event.startsWith('power:')) {
                const action = msg.event.split(':')[1];
                try {
                    if (action === 'start') await currentContainer.start();
                    else if (action === 'stop') await currentContainer.stop();
                    else if (action === 'restart') await currentContainer.restart();
                    else if (action === 'kill') await currentContainer.kill();
                } catch (e) {
                    ws.send(`\r\n\x1b[31m[INVMC] Action failed: ${e.message}\x1b[0m\r\n`);
                }
            }
        }
    });

    async function setupConsole(ws, container) {
        try {
            // Send tail logs
            const logs = await container.logs({ stdout: true, stderr: true, tail: 50 });
            ws.send(logs.toString());

            // Attach for live stream
            const stream = await container.attach({ stream: true, stdout: true, stderr: true, stdin: true, hijack: true });
            logStream = stream;

            stream.on('data', chunk => ws.send(chunk.toString()));

            ws.on('message', (message) => {
                try {
                    const msg = JSON.parse(message);
                    if (msg.event === 'cmd' && msg.command) {
                        stream.write(msg.command + '\n');
                    }
                } catch (e) {}
            });
        } catch (e) {
            ws.send(`\r\n\x1b[31m[INVMC] Console error: ${e.message}\x1b[0m\r\n`);
        }
    }

    async function setupStats(ws, container, id) {
        const sendStats = async () => {
            try {
                const stats = await container.stats({ stream: false });
                const volumeSize = await getVolumeSize(id);
                stats.volumeSize = volumeSize;
                ws.send(JSON.stringify(stats));
            } catch (e) {}
        };
        sendStats();
        statsInterval = setInterval(sendStats, 2000);
    }

    ws.on('close', () => {
        if (logStream) logStream.destroy();
        if (statsInterval) clearInterval(statsInterval);
    });
});

server.listen(config.port, () => log.info(`INVMC Daemon listening on port ${config.port}`));

// Global Error Handler
app.use((err, req, res, next) => {
    log.error(err.stack);
    res.status(500).send('Daemon Error');
});
