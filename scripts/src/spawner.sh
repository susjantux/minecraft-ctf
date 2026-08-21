#!/bin/bash

END_DIR="/home/ender_traveler/the_end"
SYS_DIR="/opt/minecraft_ctf_sys"
CHAT_LOG="/var/log/minecraft_server.log"

# Same issue as game_master.sh's safe_place_file (this daemon also runs
# as root and writes into a directory the player controls): this used to
# do
#   cp "$SYS_DIR/assets/enderman.txt" "$FILE"
#   chown ender_traveler:ender_traveler "$FILE"
# straight onto a predictable path, which follows a symlink the player
# could plant there ahead of time to redirect the write onto an
# arbitrary root-owned file and then take ownership of it. Writing to an
# unguessable temp name first and rename()-ing it into place can't be
# redirected that way.
safe_place_file() {
    local src="$1" dest="$2" owner="$3"
    local tmp
    tmp=$(mktemp "$(dirname -- "$dest")/.ctf_tmp.XXXXXX")
    cp "$src" "$tmp"
    chown "$owner" "$tmp"
    mv -T -- "$tmp" "$dest"
}

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
                # was: cp "$SYS_DIR/assets/enderman.txt" "$FILE"
                #      chown ender_traveler:ender_traveler "$FILE"
                safe_place_file "$SYS_DIR/assets/enderman.txt" "$FILE" "ender_traveler:ender_traveler"
            fi
        fi
    fi
    sleep 5
done
