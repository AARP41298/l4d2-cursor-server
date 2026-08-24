#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="${GAME_DIR:-/home/steam/l4d2}"
STEAMCMD="${STEAMCMD:-/home/steam/steamcmd/steamcmd.sh}"
APPID=222860
MAXPLAYERS="${SRCDS_MAXPLAYERS:-8}"
STARTMAP="${SRCDS_STARTMAP:-c8m1_apartment}"
PORT="${SRCDS_PORT:-27015}"

mkdir -p "$GAME_DIR" "$HOME/.steam/sdk32"

echo ">>> SteamCMD: Left 4 Dead 2 Dedicated Server (${APPID})"
# Workaround histórico: a veces SteamCMD marca plataforma inválida en updates de L4D2.
"$STEAMCMD" \
  +@sSteamCmdForcePlatformType linux \
  +force_install_dir "$GAME_DIR" \
  +login anonymous \
  +app_update "$APPID" validate \
  +quit

if [[ -f /home/steam/steamcmd/linux32/steamclient.so ]]; then
  cp -f /home/steam/steamcmd/linux32/steamclient.so "$HOME/.steam/sdk32/steamclient.so"
  mkdir -p "$GAME_DIR/bin"
  cp -f /home/steam/steamcmd/linux32/steamclient.so "$GAME_DIR/bin/steamclient.so" || true
fi

/home/steam/install-addons.sh "$GAME_DIR"

CFG_DIR="$GAME_DIR/left4dead2/cfg"
mkdir -p "$CFG_DIR"
if [[ -d /home/steam/defaults/cfg ]]; then
  cp -a /home/steam/defaults/cfg/. "$CFG_DIR/"
  if [[ -f "$CFG_DIR/motd.txt" ]]; then
    cp -f "$CFG_DIR/motd.txt" "$GAME_DIR/left4dead2/motd.txt"
  fi
fi

# server.cfg generado en cada arranque para que .env mande.
HOSTNAME_VALUE="${SRCDS_HOSTNAME:-L4D2 8 jugadores}"
RCON_VALUE="${SRCDS_RCONPW:-cambia-esto}"
PW_VALUE="${SRCDS_PW:-}"
REGION_VALUE="${SRCDS_REGION:-255}"
GAMEMODE_VALUE="${SRCDS_GAMEMODE:-coop}"
STEAMGROUP_VALUE="${SRCDS_STEAMGROUP:-0}"

cat > "$CFG_DIR/server.cfg" <<EOF
hostname "${HOSTNAME_VALUE//\"/}"
rcon_password "${RCON_VALUE//\"/}"
sv_password "${PW_VALUE//\"/}"

sv_maxplayers ${MAXPLAYERS}
sv_visiblemaxplayers ${MAXPLAYERS}
sv_removehumanlimit 1
sv_force_unreserved 1
sv_allow_lobby_connect_only 0

mp_gamemode "${GAMEMODE_VALUE}"
sv_gametypes "coop,realism,versus,survival,scavenge"
sv_consistency 0
sv_lan 0
sv_region ${REGION_VALUE}
sv_voiceenable 1
sv_alltalk 0
sv_allow_wait_command 0
sv_steamgroup "${STEAMGROUP_VALUE}"
sv_steamgroup_exclusive 0

sv_minrate 20000
sv_maxrate 30000
sv_minupdaterate 20
sv_maxupdaterate 30
sv_mincmdrate 20
sv_maxcmdrate 30

sv_hibernate_when_empty 0
motd_enabled 1

sm_cvar survivor_limit ${MAXPLAYERS}

exec banned_user.cfg
exec banned_ip.cfg
writeid
writeip
EOF

DROP="/home/steam/addons-drop"
if [[ -d "$DROP/addons" ]]; then
  echo ">>> Copiando addons-drop (ABM y extras)"
  mkdir -p "$GAME_DIR/left4dead2/addons"
  cp -a "$DROP/addons"/. "$GAME_DIR/left4dead2/addons/"
fi

cd "$GAME_DIR"
echo ">>> Arrancando srcds  -maxplayers ${MAXPLAYERS}  +map ${STARTMAP}"
exec ./srcds_run \
  -game left4dead2 \
  -console \
  -usercon \
  -secure \
  -port "$PORT" \
  -ip 0.0.0.0 \
  -maxplayers "$MAXPLAYERS" \
  +map "$STARTMAP" \
  +sv_lan 0 \
  -norestart \
  -nowatchdog
