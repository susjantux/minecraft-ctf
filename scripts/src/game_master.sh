#!/bin/bash

GAME_DIR="$1"
PLAYER="$2"
SYS_DIR="/opt/minecraft_ctf_sys"
NETHER_DIR="/home/nether_traveler/nether"
END_DIR="/home/ender_traveler/the_end"
REAL_MINE="$GAME_DIR/.abandoned_mineshaft/.deep_cave/.secret_mine"
CHAT_LOG="/var/log/minecraft_server.log"

ZOMBIE_STATE=0
NETHER_STATE=0
END_STATE=0

# This daemon runs as root (see ctf-game-master.service) and, at several
# points below, writes to a fixed, predictable filename inside a
# directory the player already owns and can write into (their mine, the
# nether traveler's home, etc). This just `cp`'d and
# `chown`'d straight onto those paths, e.g.:
#   cp "$SYS_DIR/assets/zombie.txt" "$REAL_MINE/zombie.txt"
#   chown "$PLAYER":"$PLAYER" "$REAL_MINE/zombie.txt"
# `cp` and `chown` both follow symlinks. Since the player owns that
# directory, nothing stops them from replacing "zombie.txt" with a
# symlink to, say, a sudoers snippet or a root-owned cron job before
# root's next poll — root's `cp` would then overwrite the real target
# with the zombie flavour text, and the `chown` right after would hand
# ownership of that arbitrary root-owned file to the player, who could
# then edit it freely and wait for it to run as root. That's a genuine
# privilege-escalation path hiding inside what's supposed to be a
# locked-down puzzle. The fix: write to a fresh, unguessable temp
# filename first, then atomically rename() it over the destination —
# rename() replaces whatever directory entry is at the destination (even
# a symlink) rather than following it, so it can't be redirected this
# way.
safe_place_file() {
    local src="$1" dest="$2" owner="$3" mode="$4"
    local tmp
    tmp=$(mktemp "$(dirname -- "$dest")/.ctf_tmp.XXXXXX")
    cp "$src" "$tmp"
    chown "$owner" "$tmp"
    [ -n "$mode" ] && chmod "$mode" "$tmp"
    mv -T -- "$tmp" "$dest"
}

# Same idea for a directory the daemon (re)creates at a fixed path — the
# this just did `mkdir -p "$END_DIR/ender_dragon"`, and
# `mkdir -p` treats "a symlink is already sitting there" as good enough
# and happily creates/touches files through it, letting the player
# redirect root's writes into a directory they don't actually own.
ensure_real_dir() {
    local dir="$1"
    [ -L "$dir" ] && rm -f -- "$dir"
    mkdir -p -- "$dir"
}

while true; do
    if [ $ZOMBIE_STATE -eq 0 ] && [ -f "$REAL_MINE/torch.txt" ] && grep -q "light" "$REAL_MINE/torch.txt"; then
        echo "[SERVER] Something in the darkness heard your footsteps..." >> "$CHAT_LOG"
        # was: cp "$SYS_DIR/assets/zombie.txt" "$REAL_MINE/zombie.txt"
        #      chown "$PLAYER":"$PLAYER" "$REAL_MINE/zombie.txt"
        # (see safe_place_file's comment above for why that's unsafe)
        safe_place_file "$SYS_DIR/assets/zombie.txt" "$REAL_MINE/zombie.txt" "$PLAYER:$PLAYER" ""
        ZOMBIE_STATE=1
    fi

    if [ $ZOMBIE_STATE -eq 1 ] && [ ! -f "$REAL_MINE/zombie.txt" ]; then
        echo "[SERVER] The Zombie has fallen! Loot appeared on the ground." >> "$CHAT_LOG"
        # was: cp "$SYS_DIR/assets/chest.txt" "$REAL_MINE/chest.txt"
        #      chown "$PLAYER":"$PLAYER" "$REAL_MINE/chest.txt"
        safe_place_file "$SYS_DIR/assets/chest.txt" "$REAL_MINE/chest.txt" "$PLAYER:$PLAYER" ""
        ZOMBIE_STATE=2
    fi

    if [ $NETHER_STATE -eq 0 ] && [ -f "$NETHER_DIR/enchanted_sword.txt" ] && [ -f "$NETHER_DIR/altar_of_fire/wither_skull.txt" ]; then
        if grep -q -i "Sharpness V" "$NETHER_DIR/enchanted_sword.txt"; then
            echo "[SERVER] Offering accepted! The Wither Fortress opens, but the boss is shielded!" >> "$CHAT_LOG"
            chmod 755 "$NETHER_DIR/wither_fortress"
            # was: cp "$SYS_DIR/assets/wither_boss.txt" "$NETHER_DIR/wither_fortress/wither_boss.txt"
            #      chown nether_traveler:nether_traveler "$NETHER_DIR/wither_fortress/wither_boss.txt"
            #      chmod 000 "$NETHER_DIR/wither_fortress/wither_boss.txt"
            safe_place_file "$SYS_DIR/assets/wither_boss.txt" "$NETHER_DIR/wither_fortress/wither_boss.txt" "nether_traveler:nether_traveler" "000"
            NETHER_STATE=1
        fi
    fi

    if [ $NETHER_STATE -eq 1 ] && [ ! -f "$NETHER_DIR/wither_fortress/wither_boss.txt" ]; then
        echo "[SERVER] The Wither has been defeated! A star drops from its remains!" >> "$CHAT_LOG"
        # was: cp "$SYS_DIR/assets/nether_star.txt" "$NETHER_DIR/wither_fortress/nether_star.txt"
        #      chown nether_traveler:nether_traveler "$NETHER_DIR/wither_fortress/nether_star.txt"
        safe_place_file "$SYS_DIR/assets/nether_star.txt" "$NETHER_DIR/wither_fortress/nether_star.txt" "nether_traveler:nether_traveler" ""
        NETHER_STATE=2
    fi

   
    if [ $END_STATE -eq 0 ]; then
        if [ ! -d "$END_DIR/ender_dragon" ]; then
            ENDERMAN_COUNT=$(ls "$END_DIR"/enderman_*.txt 2>/dev/null | wc -l)
            SPAWNER_RUNNING=$(systemctl is-active ctf-spawner.service >/dev/null 2>&1 && echo 1 || echo 0)
            
            if [ $ENDERMAN_COUNT -gt 0 ] || [ $SPAWNER_RUNNING -eq 1 ]; then
                echo "[SERVER] CRITICAL: The Ender Dragon is immortal while Endermen protect it! Regenerating..." >> "$CHAT_LOG"
                # was: mkdir -p "$END_DIR/ender_dragon"
                # (see ensure_real_dir's comment above)
                ensure_real_dir "$END_DIR/ender_dragon"
                touch "$END_DIR/ender_dragon/dragon_heart.txt"
                chown -R ender_traveler:ender_traveler "$END_DIR/ender_dragon"
            else
                echo "[SERVER] The Ender Dragon has been defeated! The dimension is saved!" >> "$CHAT_LOG"
                # was: cp "$SYS_DIR/assets/victory.txt" "$END_DIR/victory.txt"
                #      chown ender_traveler:ender_traveler "$END_DIR/victory.txt"
                safe_place_file "$SYS_DIR/assets/victory.txt" "$END_DIR/victory.txt" "ender_traveler:ender_traveler" ""
                END_STATE=1
            fi
        fi
    fi

    sleep 5
done
