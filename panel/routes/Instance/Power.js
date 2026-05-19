const express = require('express');
const router = express.Router();
const axios = require('axios');
const { db } = require('../../handlers/db.js');
const { isUserAuthorizedForContainer } = require('../../utils/authHelper');

/**
 * POST /instance/:id/power/:action
 * Manages the power state of an instance by proxying the request to the associated node.
 */
router.post("/instance/:id/power/:action", async (req, res) => {
    if (!req.user) return res.status(401).json({ error: 'Authentication required' });
    
    const { id, action } = req.params;
    const instance = await db.get(id + '_instance');

    if (!instance) return res.status(404).json({ error: 'Instance not found' });

    const isAuthorized = await isUserAuthorizedForContainer(req.user.userId, instance.Id);
    if (!isAuthorized) {
        return res.status(403).json({ error: 'Unauthorized access to this instance' });
    }

    if (instance.suspended === true) {
        return res.status(403).json({ error: 'Instance is suspended' });
    }

    if (!instance.Node || !instance.Node.address || !instance.Node.port) {
        return res.status(500).json({ error: 'Invalid node configuration' });
    }

    const url = `http://${instance.Node.address}:${instance.Node.port}/instances/${instance.ContainerId}/${action}`;

    try {
        const response = await axios({
            method: 'post',
            url: url,
            auth: {
                username: 'INVMC',
                password: instance.Node.apiKey
            },
            timeout: 10000 // 10 second timeout for power actions
        });

        res.status(response.status).json(response.data);
    } catch (error) {
        const errorMessage = error.response && error.response.data && error.response.data.details 
            ? error.response.data.details 
            : 'Failed to communicate with the node daemon.';
        
        console.error(`Power action '${action}' failed for instance ${id}:`, error.message);
        res.status(error.response ? error.response.status : 500).json({ error: errorMessage });
    }
});

module.exports = router;
