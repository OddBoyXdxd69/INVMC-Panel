const express = require('express');
const router = express.Router();
const WebSocket = require('ws');
const { db } = require('../../../handlers/db.js');
const { isUserAuthorizedForContainer } = require('../../../utils/authHelper');

/**
 * INVMC WebSocket Console Proxy
 * Securely tunnels terminal traffic between browser and node.
 */
router.ws("/console/:id", async (ws, req) => {
    if (!req.user) return ws.close(1008, "Authorization required");

    const { id } = req.params;
    const instance = await db.get(id + '_instance');

    if (!instance) return ws.close(1008, "Instance not found");

    const isAuthorized = await isUserAuthorizedForContainer(req.user.userId, instance.Id);
    if (!isAuthorized) return ws.close(1008, "Unauthorized access");

    const node = instance.Node;
    // Connect to Daemon
    const socket = new WebSocket(`ws://${node.address}:${node.port}/exec/${instance.ContainerId}`);

    socket.on('open', () => {
        // Send INVMC Auth Packet
        socket.send(JSON.stringify({ 
            event: "auth", 
            args: [node.apiKey] 
        }));
    });

    socket.on('message', data => {
        // Forward logs/status from daemon to browser
        if (ws.readyState === WebSocket.OPEN) ws.send(data);
    });

    socket.on('error', err => {
        if (ws.readyState === WebSocket.OPEN) ws.send('\r\n\x1b[31;1m[INVMC] Daemon connection error. Retrying...\x1b[0m\r\n');
    });

    ws.on('message', msg => {
        // Forward commands from browser to daemon
        if (socket.readyState === WebSocket.OPEN) {
            try {
                const parsed = JSON.parse(msg);
                // Ensure event is properly formatted for daemon
                if (parsed.event === 'cmd') {
                    socket.send(JSON.stringify({ event: 'cmd', command: parsed.command }));
                } else if (parsed.event && parsed.event.startsWith('power:')) {
                    socket.send(msg);
                }
            } catch (e) {
                // If not JSON, it might be raw input (though frontend sends JSON)
            }
        }
    });

    ws.on('close', () => socket.close());
    socket.on('close', () => ws.close());
});

module.exports = router;
