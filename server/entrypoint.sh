#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="${GAME_DIR:-/home/steam/l4d2}"
STEAMCMD="${STEAMCMD:-/home/steam/steamcmd/steamcmd.sh}"
APPID=222860
MAXPLAYERS="${SRCDS_MAXPLAYERS:-8}"
STARTMAP="${SRCDS_STARTMAP:-c8m1_apartment}"
PORT="${SRCDS_PORT:-27015}"

mkdir -p "$GAME_DIR" "$GAME_DIR/steamapps" "$HOME/.steam"

# Valve rompió el install anónimo de 222860 en Linux: SteamCMD responde
# "Invalid platform" o "Missing configuration" si se fuerza linux en frío.
# Sembrar el appmanifest (como Pterodactyl) hace que trate el update como
# ya configurado. Si aún falla, se baja el depot Windows y se superpone Linux.
seed_l4d2_appmanifest() {
  local manifest="$GAME_DIR/steamapps/appmanifest_${APPID}.acf"
  if [[ -f "$GAME_DIR/srcds_run" && -f "$manifest" ]]; then
    return 0
  fi
  echo ">>> SteamCMD: sembrando appmanifest_${APPID}.acf (workaround Valve)"
  cat > "$manifest" <<'EOF'
"AppState"
{
	"appid"		"222860"
	"Universe"		"1"
	"name"		"Left 4 Dead 2 Dedicated Server"
	"StateFlags"		"2"
	"installdir"		"Left 4 Dead 2 Dedicated Server"
	"LastUpdated"		"0"
	"LastPlayed"		"0"
	"SizeOnDisk"		"0"
	"StagingSize"		"0"
	"buildid"		"0"
	"LastOwner"		"0"
	"UpdateResult"		"0"
	"BytesToDownload"		"0"
	"BytesDownloaded"		"0"
	"BytesToStage"		"0"
	"BytesStaged"		"0"
	"TargetBuildID"		"0"
	"AutoUpdateBehavior"		"0"
	"AllowOtherDownloadsWhileRunning"		"0"
	"ScheduledAutoUpdate"		"0"
	"InstalledDepots"
	{
	}
	"UserConfig"
	{
	}
	"MountedConfig"
	{
	}
}
EOF
}

if [[ -f "$GAME_DIR/srcds_run" && "${FORCE_STEAM_UPDATE:-0}" != "1" ]]; then
  echo ">>> SteamCMD: dedicated ya instalado; se omite validate (FORCE_STEAM_UPDATE=1 para forzar)"
else
  steamcmd_login=()
  if [[ -n "${STEAM_USER:-}" && "$STEAM_USER" != "anonymous" ]]; then
    steamcmd_login=(+login "$STEAM_USER")
    [[ -n "${STEAM_PASS:-}" ]] && steamcmd_login+=("$STEAM_PASS")
    [[ -n "${STEAM_GUARD:-}" ]] && steamcmd_login+=("$STEAM_GUARD")
    echo ">>> SteamCMD: Left 4 Dead 2 Dedicated Server (${APPID}) como ${STEAM_USER}"
  else
    steamcmd_login=(+login anonymous)
    echo ">>> SteamCMD: Left 4 Dead 2 Dedicated Server (${APPID}) anónimo"
  fi

  seed_l4d2_appmanifest

  steamcmd_ok=0
  if "$STEAMCMD" \
      +force_install_dir "$GAME_DIR" \
      "${steamcmd_login[@]}" \
      +app_update "$APPID" validate \
      +quit; then
    steamcmd_ok=1
  fi

  if [[ "$steamcmd_ok" -ne 1 || ! -f "$GAME_DIR/srcds_run" ]]; then
    if [[ -f "$GAME_DIR/srcds_run" ]]; then
      echo ">>> SteamCMD: update falló, pero srcds_run ya está; se arranca igual"
    else
      echo ">>> SteamCMD: install Linux anónimo falló; depot Windows y luego Linux"
      seed_l4d2_appmanifest
      "$STEAMCMD" \
        +force_install_dir "$GAME_DIR" \
        "${steamcmd_login[@]}" \
        +@sSteamCmdForcePlatformType windows \
        +app_update "$APPID" \
        +@sSteamCmdForcePlatformType linux \
        +app_update "$APPID" validate \
        +quit
    fi
  fi
fi

if [[ ! -f "$GAME_DIR/srcds_run" ]]; then
  echo "ERROR: SteamCMD no dejó srcds_run. Prueba STEAM_USER/STEAM_PASS de una cuenta que tenga L4D2."
  exit 1
fi

# SteamCMD bootstrap ya no trae steamclient.so. El dedicated sí, en bin/.
# Valve deja steam_appid 879 en bin/ y eso mete el server en LAN.
# srcds_run pone bin/ primero en LD_LIBRARY_PATH: la libstdc++ vieja
# del juego rompe SteamGameServer_Init del steamclient actual.
setup_steam_runtime() {
  mkdir -p "$HOME/.steam/sdk32" "$HOME/.steam/sdk64" "$GAME_DIR/bin" "$GAME_DIR/left4dead2"

  local steamclient=""
  for candidate in \
      "$GAME_DIR/bin/steamclient.so" \
      /home/steam/steamcmd/linux32/steamclient.so
  do
    if [[ -f "$candidate" ]]; then
      steamclient="$candidate"
      break
    fi
  done
  if [[ -z "$steamclient" ]]; then
    echo "ERROR: no hay steamclient.so (Steam runtime)."
    return 1
  fi

  cp -f "$steamclient" "$HOME/.steam/sdk32/steamclient.so"
  if [[ -f /home/steam/steamcmd/linux64/steamclient.so ]]; then
    cp -f /home/steam/steamcmd/linux64/steamclient.so "$HOME/.steam/sdk64/steamclient.so"
  fi
  for f in crashhandler.so libtier0_s.so libvstdlib_s.so steamconsole.so; do
    if [[ -f "/home/steam/steamcmd/linux32/$f" ]]; then
      cp -f "/home/steam/steamcmd/linux32/$f" "$HOME/.steam/sdk32/"
    elif [[ -f "$GAME_DIR/bin/$f" ]]; then
      cp -f "$GAME_DIR/bin/$f" "$HOME/.steam/sdk32/"
    fi
  done

  printf '550\n' > "$GAME_DIR/steam_appid.txt"
  printf '550\n' > "$GAME_DIR/bin/steam_appid.txt"
  printf '550\n' > "$GAME_DIR/left4dead2/steam_appid.txt"

  for lib in libstdc++.so.6 libgcc_s.so.1; do
    if [[ -f "$GAME_DIR/bin/$lib" ]]; then
      mv -f "$GAME_DIR/bin/$lib" "$GAME_DIR/bin/${lib}.bundled"
    fi
  done

  echo ">>> Steam runtime: steam_appid=550 sdk32=$HOME/.steam/sdk32"
}

setup_steam_runtime

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
sm_cvar l4d_perkmod_forcerandomperks 1

exec banned_user.cfg
exec banned_ip.cfg
writeid
writeip
EOF

PERKMOD_CFG="$CFG_DIR/sourcemod/perkmod.cfg"
if [[ -f "$PERKMOD_CFG" ]]; then
  sed -i 's/l4d_perkmod_forcerandomperks "0"/l4d_perkmod_forcerandomperks "1"/' "$PERKMOD_CFG"
fi

DROP="/home/steam/addons-drop"
if [[ -d "$DROP/addons" ]]; then
  echo ">>> Copiando addons-drop (plugins y extras)"
  mkdir -p "$GAME_DIR/left4dead2/addons"
  cp -a "$DROP/addons"/. "$GAME_DIR/left4dead2/addons/"
fi

GEOIP_DIR="$GAME_DIR/left4dead2/addons/sourcemod/configs/geoip"
GEOIP_DB="$GEOIP_DIR/GeoLite2-City.mmdb"
if [[ ! -f "$GEOIP_DB" ]]; then
  echo ">>> GeoIP: bajando GeoLite2-City.mmdb (Country Nick)"
  mkdir -p "$GEOIP_DIR"
  curl -fsSL --retry 3 -L \
    "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb" \
    -o "$GEOIP_DB" \
    || echo ">>> GeoIP: no se pudo bajar; Country Nick puede fallar"
fi

/home/steam/install-workshop.sh "$GAME_DIR" || echo ">>> Workshop: se arranca sin actualizar mapas"

cd "$GAME_DIR"
# -ip 0.0.0.0 hace fallar SteamGameServer_Init en Docker (LAN only).
export LD_LIBRARY_PATH="/usr/lib/i386-linux-gnu:${HOME}/.steam/sdk32:${LD_LIBRARY_PATH:-}"
echo ">>> Arrancando srcds  -maxplayers ${MAXPLAYERS}  +map ${STARTMAP}"
exec ./srcds_run \
  -game left4dead2 \
  -console \
  -usercon \
  -secure \
  -port "$PORT" \
  -maxplayers "$MAXPLAYERS" \
  +map "$STARTMAP" \
  +sv_lan 0 \
  -norestart \
  -nowatchdog
