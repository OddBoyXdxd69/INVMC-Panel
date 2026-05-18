const { db } = require('../handlers/db.js');
const config = require('../config.json');
const { v4: uuidv4 } = require('uuid');
const CatLoggr = require('cat-loggr');
const log = new CatLoggr();

async function init() {
    const invmc = await db.get('invmc_instance');
    if (!invmc) {
        log.init('this is probably your first time starting invmc, welcome!');
        log.init('you can find documentation for the panel at invmc.dev');

        let imageCheck = await db.get('images');
        if (!imageCheck) {
            log.error('before starting invmc for the first time, you didn\'t run the seed command!');
            log.error('please run: npm run seed');
            log.error('if you didn\'t do it already, make a user for yourself: npm run createUser');
            process.exit();
        }

        let invmcId = uuidv4();
        let setupTime = Date.now();
        
        let info = {
            invmcId: invmcId,
            setupTime: setupTime,
            originalVersion: config.version
        }

        await db.set('invmc_instance', info)
        log.info('initialized invmc panel with id: ' + invmcId)
    }        

    log.info('init complete!')
}

module.exports = { init }