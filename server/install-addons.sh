#!/usr/bin/env bash
# Instala MetaMod, SourceMod y L4DToolZ dentro del dedicated.
# Idempotente: si MetaMod ya está, no pisa plugins del usuario salvo FORCE_ADDON_INSTALL=1.
set -euo pipefail

GAME_DIR="${1:-/home/steam/l4d2}"
L4D2="$GAME_DIR/left4dead2"
FORCE="${FORCE_ADDON_INSTALL:-0}"

MMS_URL="${MMS_URL:-https://mms.alliedmods.net/mmsdrop/1.12/mmsource-latest-linux.tar.gz}"
SM_URL="${SM_URL:-https://sm.alliedmods.net/smdrop/1.12/sourcemod-latest-linux.tar.gz}"
# Pinned: el zip histórico de AlliedModders no carga en L4D2 actual.
L4DTOOLZ_URL="${L4DTOOLZ_URL:-https://github.com/accelerator74/l4dtoolz/releases/download/2.2.0/l4dtoolz-l4d2-linux-ef2a8df.tar.gz}"

mkdir -p "$L4D2"
if [[ -f "$L4D2/addons/metamod.vdf" && "$FORCE" != "1" ]]; then
  echo ">>> Addons ya presentes (FORCE_ADDON_INSTALL=1 para reinstalar MM/SM/L4DToolZ)"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo ">>> MetaMod:Source"
curl -fsSL "$MMS_URL" -o mms.tar.gz
tar -xzf mms.tar.gz -C "$L4D2"

echo ">>> SourceMod"
curl -fsSL "$SM_URL" -o sm.tar.gz
tar -xzf sm.tar.gz -C "$L4D2"

echo ">>> L4DToolZ 2.2.0 (accelerator74)"
curl -fsSL "$L4DTOOLZ_URL" -o l4dtoolz.tar.gz
# El tar trae addons/l4dtoolz y addons/metamod/l4dtoolz.vdf
tar -xzf l4dtoolz.tar.gz -C "$L4D2"

ADMINS="$L4D2/addons/sourcemod/configs/admins_simple.ini"
if [[ -f "$ADMINS" ]] && ! grep -q "STEAM_1:0:0000" "$ADMINS"; then
  {
    echo ""
    echo "// Pon tu SteamID2 aquí, por ejemplo:"
    echo '// "STEAM_1:0:12345678" "99:z"'
  } >> "$ADMINS"
fi

echo ">>> MetaMod + SourceMod + L4DToolZ listos"
echo ">>> Falta ABM: deja abm.smx y abm.txt en server/addons-drop (ver README)"
