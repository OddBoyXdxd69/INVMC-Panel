const Keyv = require('keyv');
const db = new Keyv('sqlite://AirDaemon.db');
const fs = require('fs').promises;
const path = require('path');

/**
 * Calculates the size of a directory recursively.
 */
async function getVolumeSize(id) {
    const volumePath = path.join(__dirname, '../volumes', id);
    let totalSize = 0;

    async function calculateSize(dir) {
        try {
            const files = await fs.readdir(dir);
            for (const file of files) {
                const filePath = path.join(dir, file);
                const stats = await fs.stat(filePath);
                if (stats.isDirectory()) {
                    await calculateSize(filePath);
                } else {
                    totalSize += stats.size;
                }
            }
        } catch (e) {
            // Ignore errors
        }
    }

    await calculateSize(volumePath);
    return (totalSize / 1024 / 1024).toFixed(2); // MB
}

module.exports = { db, getVolumeSize }
