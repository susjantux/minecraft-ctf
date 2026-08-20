#!/bin/bash

END_DIR="/home/ender_traveler/the_end"
SYS_DIR="/opt/minecraft_ctf_sys"
CHAT_LOG="/var/log/minecraft_server.log"

while true; do
    if sudo -u ender_traveler crontab -l 2>/dev/null | grep -qE "12:00|0 12|00 12|\* 12"; then
        if [ -f "$END_DIR/hint.txt" ]; then
            rm "$END_DIR/hint.txt"
            echo "[SERVER] A dark portal opened in The End..." >> "$CHAT_LOG"
        fi
        
        if [ -d "$END_DIR" ]; then
            COUNT=$(ls "$END_DIR"/enderman_*.txt 2>/dev/null | wc -l)
            if [ $COUNT -lt 3 ]; then
                FILE="$END_DIR/enderman_$RANDOM.txt"
                cp "$SYS_DIR/assets/enderman.txt" "$FILE"
                chown ender_traveler:ender_traveler "$FILE"
            fi
        fi
    fi
    sleep 5
done
