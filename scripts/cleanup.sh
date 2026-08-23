#!/bin/bash

# There was no error handling in here before, so a single unexpected failure
# (say, `userdel` erroring for an unrelated reason) would just stop
# cleanup dead wherever it happened to be, with the "[OK] Cleanup
# complete" banner further down never printing and no clue why it
# stopped. Fail loudly on real errors instead of silently going half-way.
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Error: Cleanup requires root privileges. (sudo bash $0)"
  exit 1
fi

echo " Initiating CTF cleanup "

echo "[*] Stopping and removing game daemons..."
# These four lines relied on `2>/dev/null` to hide the "service not
# found" noise when running cleanup on a box that was never fully set up
# (or was already cleaned once before):
#   systemctl stop ctf-game-master.service 2>/dev/null
#   systemctl stop ctf-spawner.service 2>/dev/null
#   systemctl disable ctf-game-master.service 2>/dev/null
#   systemctl disable ctf-spawner.service 2>/dev/null
# `2>/dev/null` only hides the error message though, not the command's
# exit status — with `set -e` now in effect, that exit status matters,
# and the very first `systemctl stop` on a service that isn't loaded
# would abort the whole cleanup immediately, before anything else ran.
# `|| true` explicitly says "it's fine if this one has nothing to do".
systemctl stop ctf-game-master.service 2>/dev/null || true
systemctl stop ctf-spawner.service 2>/dev/null || true
systemctl disable ctf-game-master.service 2>/dev/null || true
systemctl disable ctf-spawner.service 2>/dev/null || true
rm -f /etc/systemd/system/ctf-game-master.service
rm -f /etc/systemd/system/ctf-spawner.service
systemctl daemon-reload

# The installer appends a scoped sshd override for the two game accounts
# (see minecraft_ctf.sh) — cleanup never used to touch
# sshd_config at all, so that PasswordAuthentication change stuck around
# on the host permanently, even after every other trace of the game was
# deleted below.
SSHD_MARKER_BEGIN="# BEGIN minecraft-ctf sshd override"
SSHD_MARKER_END="# END minecraft-ctf sshd override"
if grep -qF "$SSHD_MARKER_BEGIN" /etc/ssh/sshd_config 2>/dev/null; then
    sed -i "/$SSHD_MARKER_BEGIN/,/$SSHD_MARKER_END/d" /etc/ssh/sshd_config
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || true
fi

echo "Removing users"
for user in nether_traveler ender_traveler; do
    # Same deal here:
    #   killall -u $user 2>/dev/null
    #   userdel -f -r $user 2>/dev/null
    # Same `set -e` problem as above — if the user has no processes
    # running (the common case) `killall` exits non-zero, and if the
    # user was already removed by an earlier cleanup run `userdel` exits
    # non-zero too, either of which would kill the script right here.
    killall -u $user 2>/dev/null || true
    userdel -f -r $user 2>/dev/null || true
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
