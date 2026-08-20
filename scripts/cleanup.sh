#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Error: Cleanup requires root privileges. (sudo bash $0)"
  exit 1
fi

echo " Initiating CTF cleanup "

echo "[*] Stopping and removing game daemons..."
systemctl stop ctf-game-master.service 2>/dev/null
systemctl stop ctf-spawner.service 2>/dev/null
systemctl disable ctf-game-master.service 2>/dev/null
systemctl disable ctf-spawner.service 2>/dev/null
rm -f /etc/systemd/system/ctf-game-master.service
rm -f /etc/systemd/system/ctf-spawner.service
systemctl daemon-reload

echo "Removing users"
for user in nether_traveler ender_traveler; do
    killall -u $user 2>/dev/null
    userdel -f -r $user 2>/dev/null
done

echo " Deleting game files and logs "
if [ -n "$SUDO_USER" ]; then
    PLAYER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    PLAYER_HOME="/root"
fi

rm -rf "$PLAYER_HOME/minecraft_ctf"
rm -rf "/opt/minecraft_ctf_sys"
rm -f "/var/log/minecraft_server.log"

echo "[OK] Cleanup complete. The world has been successfully deleted."
