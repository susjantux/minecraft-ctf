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
