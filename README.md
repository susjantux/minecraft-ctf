# Minecraft CTF: The linux adventure

I created this CTF to help people learn Linux command-line and sysadmin skills in a gamified way. Players navigate through the overworld, nether, and the end using only bash commands.

## Warning

**Run this in a Docker container or a virtual machine.** While a `cleanup.sh` script is provided for bare-metal installs, using the provided Docker environment is highly recommended to avoid modifying your host system.
*Note1: Developed and tested on Debian/Ubuntu and Arch Linux/Garuda.*
*Note2: Copy-pasting wrapped commands from PDF grabs the newline and breaks execution. Paste as one single line.*

## Features

* Three environments to explore (overworld, nether, the end)
* Custom systemd daemons for real-time events like spawning zombies and loot
* SHA-512 password hashing
* Practical tasks covering `grep`, `tar`, `chmod`, SSH tunneling, `cron`, and process management
* **Fully containerized Docker environment for safe and isolated gameplay**
* **Cross-distribution compatibility for host installations (Debian & Arch-based)**

## Installation

First, download the repository:

```bash
git clone [https://github.com/susjantux/minecraft-ctf.git](https://github.com/susjantux/minecraft-ctf.git)
cd minecraft-ctf
Option 1: Docker (Highly Recommended)
Run the CTF in a completely isolated environment without altering your host system.

Build and start the container in the background:

Bash
docker compose up -d --build
Connect to the game via SSH (password is hidden in the game!):

Bash
ssh nether_traveler@localhost -p 2222
Option 2: Bare Metal
Warning: This will create users and modify systemd services directly on your host machine.

Run the installer script:

Bash
sudo bash minecraft_ctf.sh
Open a second terminal to monitor the server logs:

Bash
tail -f /var/log/minecraft_server.log
Teardown
If you used the Docker method, simply run:

Bash
docker compose down
To safely remove all generated dimensions, systemd services, and users from a bare-metal installation, run the cleanup script:

Bash
sudo bash cleanup.sh
Contributing
Feel free to open an issue or submit a PR if you want to add improvements or fix a bug (though I tested this meticulously for ages, so I'm like 99.9% sure it's flawless... but you never know).

made with programmer socks btw
