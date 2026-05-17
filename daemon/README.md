
<h1 align="center">INVMCDaemon</h1>
## Overview
INVMC Daemon is the invmc-invmc-daemon for the INVMC Panel.

## Installation
1. Clone the repository:
`git clone https://github.com/draco-labes/draco-invmc-invmc-daemon`

2. go to panel directory:
`cd draco-invmc-invmc-daemon` 

3. Install dependencies:
`npm install`

4. Configure INVMCDaemon:
- Get your Panel's access key from the Hydra panel's config.json file and set it as 'remoteKey'. Do the same for the other way, set your INVMCDaemon access key and configure it on the Panel.

4. Start the Daemon:
`node . # or use pm2 to keep it online`

## Configuration
Configuration settings can be adjusted in the `config.json` file. This includes the authentication key for API access.

## Usage
The invmc-invmc-daemon runs as a background service, interfacing with the INVMC Panel for operational commands and status updates. It is not typically interacted with directly by end-users.

## Contributing
Contributions to enhance the functionality or performance of the INVMC Daemon are encouraged. Please submit pull requests for any enhancements.

## License
(c) 2024 MJ and contributors. This software is licensed under the MIT License.


## Credits
SRYDEN
Skyport
Hydra-Labes

- Thanks ma4z,ether,achul123,privt
