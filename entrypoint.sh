#!/bin/bash

echo " [!] Initializing Minecraft CTF Docker Container... "

# 1. Avvia il servizio Cron
service cron start

# 2. Trova ed esegue minecraft_ctf.sh (gestendo se è nella root o in scripts/)
if [ -f "./minecraft_ctf.sh" ]; then
    bash ./minecraft_ctf.sh
elif [ -f "./scripts/minecraft_ctf.sh" ]; then
    # Entra nella cartella scripts così i percorsi relativi degli asset coincidono
    cd scripts || exit 1
    bash ./minecraft_ctf.sh
    cd ..
else
    echo "[!] Error: minecraft_ctf.sh not found!"
    exit 1
fi

# 3. Avvia i demoni di gioco in background (bypassando systemd)
if [ -f "/opt/minecraft_ctf_sys/game_master.sh" ]; then
    echo "[*] Starting Game Master daemon..."
    nohup /opt/minecraft_ctf_sys/game_master.sh > /var/log/game_master.log 2>&1 &
fi

if [ -f "/opt/minecraft_ctf_sys/spawner.sh" ]; then
    echo "[*] Starting Spawner daemon..."
    nohup /opt/minecraft_ctf_sys/spawner.sh > /var/log/spawner.log 2>&1 &
fi

echo " [OK] CTF Environment is fully up and running inside Docker!"
echo " [>] Connect via SSH: ssh nether_traveler@localhost -p 2222"

# 4. Avvia il server SSH in primo piano per mantenere il container attivo
exec /usr/sbin/sshd -D
