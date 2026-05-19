/**
 * @fileoverview Handles container power management actions via Docker.
 */

const express = require('express');
const router = express.Router();
const Docker = require('dockerode');

const docker = new Docker({ socketPath: process.env.dockerSocket || '/var/run/docker.sock' });

/**
 * POST /:id/:power
 */
router.post('/:id/:power', async (req, res) => {
    const { id, power } = req.params;
    
    if (!id) return res.status(400).json({ error: 'Container ID is required' });

    const container = docker.getContainer(id);
    
    try {
        switch (power) {
            case 'start':
                await container.start();
                break;
            case 'stop':
                await container.stop();
                break;
            case 'restart':
                await container.restart({ t: 10 });
                break;
            case 'kill':
                await container.kill();
                break;
            default:
                return res.status(400).json({ error: 'Invalid action', received: power });
        }

        res.status(200).json({ 
            success: true,
            message: `Container ${power} operation completed successfully`,
            containerId: id
        });
        
    } catch (err) {
        // 304 means already in that state
        if (err.statusCode === 304) {
            return res.status(400).json({
                error: 'Container already in desired state',
                details: `Container is already ${power}ed`,
                containerId: id
            });
        }
        
        // 404 means container not found
        if (err.statusCode === 404) {
            return res.status(404).json({
                error: 'Container not found',
                containerId: id
            });
        }

        res.status(500).json({ 
            error: 'Operation failed',
            details: err.message,
            containerId: id
        });
    }
});

module.exports = router;
