const express = require('express');
const router = express.Router();
const WebSocket = require('ws');
const { db } = require('../../../handlers/db.js');
const { isUserAuthorizedForContainer } = require('../../../utils/authHelper');

/**
 * INVMC WebSocket Stats Proxy
 */
router.ws("/stats/:id", async (ws, req) => {
    if (!req.user) return ws.close(1008, "Authorization required");

    const { id } = req.params;
    const instance = await db.get(id + '_instance');

    if (!instance) return ws.close(1008, "Instance not found");

    const isAuthorized = await isUserAuthorizedForContainer(req.user.userId, instance.Id);
    if (!isAuthorized) return ws.close(1008, "Unauthorized access");

    const node = instance.Node;
    const volume = instance.VolumeId;
    
    // Connect to Daemon
    const socket = new WebSocket(`ws://${node.address}:${node.port}/stats/${instance.ContainerId}/${volume}`);

    socket.on('open', () => {
        socket.send(JSON.stringify({ 
            event: "auth", 
            args: [node.apiKey] 
        }));
    });

    socket.on('message', data => {
        if (ws.readyState === WebSocket.OPEN) ws.send(data);
    });

    socket.on('error', () => {
        if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ error: 'Stats service unavailable' }));
    });

    ws.on('close', () => socket.close());
    socket.on('close', () => ws.close());
});

module.exports = router;
