#!/bin/bash

# There was no error handling anywhere in here before, so if a step partway
# through failed (no network for the apt-get install below, for example)
# it would just carry on through the rest of the setup regardless and
# still print "installation completed successfully" at the very end,
# leaving a half-built game with no clue what actually went wrong.
# `set -euo pipefail` makes it stop immediately and loudly on the first
# real failure instead.
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Error: Installer requires root privileges. (sudo bash $0)"
  exit 1
fi

# Rilevamento automatico del Package Manager (APT vs Pacman)
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
else
    echo "Error: Nessun package manager supportato (apt o pacman) trovato."
    exit 1
fi

REPO_DIR=$(pwd)

if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    PLAYER_USER="$SUDO_USER"
    PLAYER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    # This used to just let anyone with no SUDO_USER set (or a SUDO_USER
    # of "root" itself, e.g. someone who ran `su -` before invoking the
    # script) become the "root" player:
    #   PLAYER_USER="root"
    #   PLAYER_HOME="/root"
    # That's not harmless — this whole game is a series of Linux
    # permission puzzles (locked-down directories, files only another
    # account can read, etc), and root can read and write straight through
    # every single one of them. Someone who spins up a fresh VM per the
    # README and just works as root the whole time (a very common way
    # people actually use disposable VMs) would silently skip every
    # puzzle instead of solving it. Refuse to start instead of quietly
    # running the whole game as root.
    echo "Error: run this with 'sudo' from a normal (non-root) user account, not while logged in as root." >&2
    echo "  e.g.: adduser player && usermod -aG sudo player && su - player" >&2
    echo "        sudo bash $0" >&2
    exit 1
fi

GAME_DIR="$PLAYER_HOME/minecraft_ctf"
SYS_DIR="/opt/minecraft_ctf_sys"
CHAT_LOG="/var/log/minecraft_server.log"

echo " ⋅˚₊‧    Initializing minecraft CTF environment    ‧₊˚ ⋅ "

touch "$CHAT_LOG"
chmod 644 "$CHAT_LOG"
echo "[SERVER] World generation complete. Type 'tail -f $CHAT_LOG' in a second terminal to monitor server events." > "$CHAT_LOG"

# Installazione dipendenze di sistema cross-distro (SSH + Cron)
echo "[*] Checking system dependencies (SSH & Cron)..."
if [ "$PKG_MANAGER" = "apt" ]; then
    apt-get update -qq
    apt-get install -y openssh-server cron
    systemctl enable --now cron 2>/dev/null || true
elif [ "$PKG_MANAGER" = "pacman" ]; then
    pacman -Sy --noconfirm --quiet
    pacman -S --noconfirm openssh cronie
    systemctl enable --now cronie 2>/dev/null || true
fi

# Configurazione SSH
if [ -f "/etc/ssh/sshd_config" ]; then
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
fi

for user in nether_traveler ender_traveler; do
    if id "$user" &>/dev/null; then
        # This only cleared the visible files on a reinstall:
        #   rm -rf /home/$user/*
        # A bare `*` glob doesn't match dotfiles, so anything hidden left
        # over from a previous run (.bash_history, .lesshst, whatever a
        # player leaves behind) survives a "fresh" reinstall instead of the
        # game actually resetting.
        find "/home/$user" -mindepth 1 -exec rm -rf {} +
    else
        useradd -m -s /bin/bash $user
    fi
    chmod 755 /home/$user

    # Fix compatibilità .cache per crontab (indispensabile per cronie su Arch)
    mkdir -p /home/$user/.cache/crontab
    chown -R $user:$user /home/$user/.cache
done

PASS_NETHER=$(openssl passwd -6 $(echo "TWluZWNyYWZ0Q1RGe3BvcnRhbF9pZ25pdGVkfQ==" | base64 -d))
PASS_ENDER=$(openssl passwd -6 $(echo "TWluZWNyYWZ0Q1RGe2RyYWdvbl9zbGF5ZXJ9" | base64 -d))

usermod --password "$PASS_NETHER" nether_traveler
usermod --password "$PASS_ENDER" ender_traveler

echo "[*] Checking SSH server dependencies..."
if [ ! -f "/etc/ssh/sshd_config" ]; then
        echo "[*] OpenSSH Server is missing. Installing automatically..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -qq
            apt-get install -y openssh-server
        elif command -v pacman >/dev/null 2>&1; then
            pacman -Sy --noconfirm openssh
        else
            echo "[-] Error: Unsupported package manager. Please install OpenSSH manually."
            exit 1
        fi
    fi
# These two lines flipped PasswordAuthentication to "yes" for the ENTIRE
# sshd, for every account on the box, not just the two throwaway CTF
# accounts:
#   sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
#   sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Two problems with that: (1) it weakens SSH login for the real
# machine/VM account too, not just the game NPC accounts, and (2) modern
# Debian ships "Include /etc/ssh/sshd_config.d/*.conf" near the TOP of
# sshd_config, and sshd uses the FIRST value it finds for a setting — so
# if a distro or cloud-image drop-in in that directory already says
# "PasswordAuthentication no", it wins over our edit further down the
# file and password login silently never actually works. A `Match User`
# block scopes the setting to just our two accounts, and because Match
# blocks are evaluated as their own separate context, they reliably
# override for those users regardless of what conf.d says.
SSHD_MARKER_BEGIN="# BEGIN minecraft-ctf sshd override"
SSHD_MARKER_END="# END minecraft-ctf sshd override"
if ! grep -qF "$SSHD_MARKER_BEGIN" /etc/ssh/sshd_config; then
    {
        echo "$SSHD_MARKER_BEGIN"
        echo "Match User nether_traveler,ender_traveler"
        echo "    PasswordAuthentication yes"
        echo "$SSHD_MARKER_END"
    } >> /etc/ssh/sshd_config
fi
systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null

#  END DIMENSION 
sudo -u ender_traveler mkdir -p /home/ender_traveler/the_end/ender_dragon
sudo -u ender_traveler touch /home/ender_traveler/the_end/ender_dragon/dragon_heart.txt
cp "$REPO_DIR/assets/hint.txt" /home/ender_traveler/the_end/hint.txt
chown -R ender_traveler:ender_traveler /home/ender_traveler/the_end

# NETHER DIMENSION
NETHER_HOME="/home/nether_traveler/nether"
sudo -u nether_traveler mkdir -p "$NETHER_HOME/wither_fortress"
chmod 000 "$NETHER_HOME/wither_fortress"
sudo -u nether_traveler mkdir -p "$NETHER_HOME/altar_of_fire"
sudo -u nether_traveler touch "$NETHER_HOME/wither_skull.txt"

cp "$REPO_DIR/assets/enchanting_table.txt" "$NETHER_HOME/enchanting_table.txt"
cp "$REPO_DIR/assets/nether_bash_history.txt" /home/nether_traveler/.bash_history

chown nether_traveler:nether_traveler /home/nether_traveler/.bash_history
chown -R nether_traveler:nether_traveler "$NETHER_HOME"

#  OVERWORLD
rm -rf "$GAME_DIR"
mkdir -p "$GAME_DIR"

mkdir -p "$GAME_DIR/east_shaft/mines/diamond_vein"
mkdir -p "$GAME_DIR/west_shaft/.collapsed_tunnel/cobwebs"
mkdir -p "$GAME_DIR/north_shaft/flooded_section"
mkdir -p "$GAME_DIR/south_shaft/lava_lake/.safe_path"
mkdir -p "$GAME_DIR/.old_mineshaft/dead_end"
mkdir -p "$GAME_DIR/.lost_library/secret_room"
mkdir -p "$GAME_DIR/east_shaft/.hidden_crevice"

echo "TWluZWNyYWZ0Q1RGe2hpZGRlbl9sb290X3VuY292ZXJlZH0=" | base64 -d > "$GAME_DIR/east_shaft/.hidden_crevice/golden_apple.txt"

REAL_MINE="$GAME_DIR/.abandoned_mineshaft/.deep_cave/.secret_mine"
mkdir -p "$REAL_MINE"

touch "$GAME_DIR/east_shaft/mines/dirt.txt"
touch "$GAME_DIR/south_shaft/lava_lake/warning.txt"
touch "$GAME_DIR/west_shaft/.collapsed_tunnel/bat.txt"
touch "$GAME_DIR/west_shaft/.collapsed_tunnel/cobwebs/stuck.txt"
touch "$GAME_DIR/north_shaft/flooded_section/water.txt"

echo "TWluZWNyYWZ0Q1RGe25pY2VfdHJ5fQ==" | base64 -d > "$GAME_DIR/.old_mineshaft/dead_end/mystery.txt"

LOG_FILE="$GAME_DIR/.lost_library/server_logs.txt"
touch "$LOG_FILE"
for i in {1..800}; do echo "[INFO] Villager trade: 5 emeralds for 1 bread" >> "$LOG_FILE"; done
echo "[ERROR] Admin dropped flag near stronghold: MinecraftCTF{grep_master_log_reader}" >> "$LOG_FILE"
for i in {1..500}; do echo "[INFO] Zombie spawned at X:12 Y:50 Z:-14" >> "$LOG_FILE"; done

mkdir -p "/tmp/world_backup"
cp "$REPO_DIR/assets/miners_diary.txt" "/tmp/world_backup/miners_diary.txt"
tar -czf "$GAME_DIR/.old_mineshaft/world_backup_2011.tar.gz" -C "/tmp" world_backup
rm -rf "/tmp/world_backup"

echo "TWluZWNyYWZ0Q1RGe2ZpbGVfY29tbWFuZF9kZXRlY3RpdmV9" | base64 -d > "$GAME_DIR/north_shaft/flooded_section/mysterious_gem.png"

cp "$REPO_DIR/src/book_of_wisdom.py" "$GAME_DIR/.lost_library/secret_room/book_of_wisdom.py"
cp "$REPO_DIR/assets/intro.txt" "$GAME_DIR/intro.txt"
cp "$REPO_DIR/assets/coal.txt" "$REAL_MINE/coal.txt"

#  PERMISSIONS
chown -R "$PLAYER_USER:$PLAYER_USER" "$GAME_DIR"
chmod 755 "$PLAYER_HOME"
chmod -R 755 "$GAME_DIR"
find "$GAME_DIR" -type d -exec chmod 755 {} \;
find "$GAME_DIR" -type f -exec chmod 644 {} \;
chmod +x "$GAME_DIR/.lost_library/secret_room/book_of_wisdom.py"

#  DAEMONS & SYSTEMD
mkdir -p "$SYS_DIR"
chmod 700 "$SYS_DIR"

cp -r "$REPO_DIR/assets" "$SYS_DIR/assets"

cp "$REPO_DIR/src/game_master.sh" "$SYS_DIR/game_master.sh"
cp "$REPO_DIR/src/spawner.sh" "$SYS_DIR/spawner.sh"
chmod +x "$SYS_DIR/game_master.sh"
chmod +x "$SYS_DIR/spawner.sh"

cp "$REPO_DIR/systemd/ctf-game-master.service" /etc/systemd/system/
cp "$REPO_DIR/systemd/ctf-spawner.service" /etc/systemd/system/

# This matched the ENTIRE literal default line to substitute in the real
# paths:
#   sed -i "s|/root/minecraft_ctf root|$GAME_DIR $PLAYER_USER|g" /etc/systemd/system/ctf-game-master.service
# That only works because the checked-in .service file happens to say
# exactly "/root/minecraft_ctf root" right now — rename a variable,
# reflow that line, or add a comment above it later, and this silently
# stops matching, so the installed service keeps pointing at
# /root/minecraft_ctf and runs the wrong game world with no error
# anywhere to tell you. Dedicated placeholder tokens in the template
# aren't tied to the file's current wording, so they can't go stale like
# that.
sed -i "s|__GAME_DIR__|$GAME_DIR|g; s|__PLAYER__|$PLAYER_USER|g" /etc/systemd/system/ctf-game-master.service

systemctl daemon-reload
systemctl enable ctf-game-master.service
systemctl enable ctf-spawner.service
systemctl restart ctf-game-master.service
systemctl restart ctf-spawner.service

echo "  ⋅˚₊‧    CTF installation completed successfully    ‧₊˚ ⋅ "
echo "[OK] Game daemons are running securely via systemd."
echo "[OK] End Dimension link enabled via SSH (port 22)."
echo "[OK] Starting point: $GAME_DIR"
