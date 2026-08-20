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

while true; do
    if [ $ZOMBIE_STATE -eq 0 ] && [ -f "$REAL_MINE/torch.txt" ] && grep -q "light" "$REAL_MINE/torch.txt"; then
        echo "[SERVER] Something in the darkness heard your footsteps..." >> "$CHAT_LOG"
        cp "$SYS_DIR/assets/zombie.txt" "$REAL_MINE/zombie.txt"
        chown "$PLAYER":"$PLAYER" "$REAL_MINE/zombie.txt"
        ZOMBIE_STATE=1
    fi

    if [ $ZOMBIE_STATE -eq 1 ] && [ ! -f "$REAL_MINE/zombie.txt" ]; then
        echo "[SERVER] The Zombie has fallen! Loot appeared on the ground." >> "$CHAT_LOG"
        cp "$SYS_DIR/assets/chest.txt" "$REAL_MINE/chest.txt"
        chown "$PLAYER":"$PLAYER" "$REAL_MINE/chest.txt"
        ZOMBIE_STATE=2
    fi

    if [ $NETHER_STATE -eq 0 ] && [ -f "$NETHER_DIR/enchanted_sword.txt" ] && [ -f "$NETHER_DIR/altar_of_fire/wither_skull.txt" ]; then
        if grep -q -i "Sharpness V" "$NETHER_DIR/enchanted_sword.txt"; then
            echo "[SERVER] Offering accepted! The Wither Fortress opens, but the boss is shielded!" >> "$CHAT_LOG"
            chmod 755 "$NETHER_DIR/wither_fortress"
            cp "$SYS_DIR/assets/wither_boss.txt" "$NETHER_DIR/wither_fortress/wither_boss.txt"
            chown nether_traveler:nether_traveler "$NETHER_DIR/wither_fortress/wither_boss.txt"
            chmod 000 "$NETHER_DIR/wither_fortress/wither_boss.txt"
            NETHER_STATE=1
        fi
    fi

    if [ $NETHER_STATE -eq 1 ] && [ ! -f "$NETHER_DIR/wither_fortress/wither_boss.txt" ]; then
        echo "[SERVER] The Wither has been defeated! A star drops from its remains!" >> "$CHAT_LOG"
        cp "$SYS_DIR/assets/nether_star.txt" "$NETHER_DIR/wither_fortress/nether_star.txt"
        chown nether_traveler:nether_traveler "$NETHER_DIR/wither_fortress/nether_star.txt"
        NETHER_STATE=2
    fi

   
    if [ $END_STATE -eq 0 ]; then
        if [ ! -d "$END_DIR/ender_dragon" ]; then
            ENDERMAN_COUNT=$(ls "$END_DIR"/enderman_*.txt 2>/dev/null | wc -l)
            SPAWNER_RUNNING=$(systemctl is-active ctf-spawner.service >/dev/null 2>&1 && echo 1 || echo 0)
            
            if [ $ENDERMAN_COUNT -gt 0 ] || [ $SPAWNER_RUNNING -eq 1 ]; then
                echo "[SERVER] CRITICAL: The Ender Dragon is immortal while Endermen protect it! Regenerating..." >> "$CHAT_LOG"
                mkdir -p "$END_DIR/ender_dragon"
                touch "$END_DIR/ender_dragon/dragon_heart.txt"
                chown -R ender_traveler:ender_traveler "$END_DIR/ender_dragon"
            else
                echo "[SERVER] The Ender Dragon has been defeated! The dimension is saved!" >> "$CHAT_LOG"
                cp "$SYS_DIR/assets/victory.txt" "$END_DIR/victory.txt"
                chown ender_traveler:ender_traveler "$END_DIR/victory.txt"
                END_STATE=1
            fi
        fi
    fi

    sleep 5
done
