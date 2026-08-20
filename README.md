

# Minecraft CTF: The linux adventure

I created this CTF to help people learn Linux command-line and sysadmin skills in a gamified way. Players navigate through the overworld, nether, and the end using only bash commands

## Warning

**Run this in a virtual machine.** While a `cleanup.sh` script is provided, using an isolated VM with snapshots is highly recommended
*Note1: Developed and tested strictly on Debian. Other distributions might not work correctly*
*Note2: Copy-pasting wrapped commands from PDF grabs the newline and breaks execution. Paste as one single line*

## Features

* Three environments to explore (overworld, nether, the end)
* Custom systemd daemons for real-time events like spawning zombies and loot
* SHA-512 password hashing
* Practical tasks covering `grep`, `tar`, `chmod`, SSH tunneling, `cron`, and process management


## Installation

1. Download the repository:

   ```bash
   git clone https://github.com/susjantux/minecraft-ctf.git
   cd minecraft-ctf
   ```
2. Run the installer script:

   ```bash
   sudo bash minecraft_ctf.sh
   ```
3. Open a second terminal to monitor the server logs:

   ```bash
   tail -f /var/log/minecraft_server.log
   ```
   
## Teardown
To safely remove all generated dimensions, systemd services, and users, run the cleanup script:

```bash
sudo bash cleanup.sh
```

## Contributing
Feel free to open an issue or submit a pr if you want to add improvements or fix a bug (though I tested this meticulously for ages, so I'm like 99.9% sure it's flawless... but you never know)

* made with programmer socks btw
