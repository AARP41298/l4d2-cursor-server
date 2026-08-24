#!/usr/bin/env bash
# Instala MetaMod, SourceMod y L4DToolZ dentro del dedicated.
# Idempotente: si MetaMod ya está, no pisa plugins del usuario salvo FORCE_ADDON_INSTALL=1.
set -euo pipefail

GAME_DIR="${1:-/home/steam/l4d2}"
L4D2="$GAME_DIR/left4dead2"
FORCE="${FORCE_ADDON_INSTALL:-0}"

# AlliedModders ya no sirve mmsource-latest-linux.tar.gz (es un puntero de texto
# o Cloudflare 403). GitHub Releases es el espejo estable.
MMS_URL="${MMS_URL:-https://github.com/alliedmodders/metamod-source/releases/download/1.12.0.1225/mmsource-1.12.0-git1225-linux.tar.gz}"
SM_URL="${SM_URL:-https://github.com/alliedmodders/sourcemod/releases/download/1.12.0.7250/sourcemod-1.12.0-git7250-linux.tar.gz}"
MMS_LATEST_PTR="${MMS_LATEST_PTR:-https://mms.alliedmods.net/mmsdrop/1.12/mmsource-latest-linux}"
SM_LATEST_PTR="${SM_LATEST_PTR:-https://sm.alliedmods.net/smdrop/1.12/sourcemod-latest-linux}"
# Pinned: el zip histórico de AlliedModders no carga en L4D2 actual.
L4DTOOLZ_URL="${L4DTOOLZ_URL:-https://github.com/accelerator74/l4dtoolz/releases/download/2.2.0/l4dtoolz-l4d2-linux-ef2a8df.tar.gz}"

curl_get() {
  curl -fsSL --retry 3 --retry-delay 2 \
    -A "Mozilla/5.0 (compatible; l4d2-8plus/1.0)" \
    "$@"
}

# Intenta GitHub; si falla, resuelve el puntero AlliedModders (nombre real del tar).
download_addon() {
  local dest="$1"
  local github_url="$2"
  local latest_ptr="$3"
  local name base url

  echo "    $github_url"
  if curl_get "$github_url" -o "$dest"; then
    return 0
  fi

  echo "    fallback AlliedModders: $latest_ptr"
  name="$(curl_get "$latest_ptr" | tr -d '\r\n[:space:]')" || true
  if [[ -n "$name" && "$name" == *.tar.gz ]]; then
    base="${latest_ptr%/*}"
    url="${base}/${name}"
    echo "    $url"
    if curl_get "$url" -o "$dest"; then
      return 0
    fi
  fi

  echo "ERROR: no se pudo descargar $dest"
  return 1
}

mkdir -p "$L4D2"
if [[ -f "$L4D2/addons/metamod.vdf" && "$FORCE" != "1" ]]; then
  echo ">>> Addons ya presentes (FORCE_ADDON_INSTALL=1 para reinstalar MM/SM/L4DToolZ)"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo ">>> MetaMod:Source"
download_addon mms.tar.gz "$MMS_URL" "$MMS_LATEST_PTR"
tar -xzf mms.tar.gz -C "$L4D2"

echo ">>> SourceMod"
download_addon sm.tar.gz "$SM_URL" "$SM_LATEST_PTR"
tar -xzf sm.tar.gz -C "$L4D2"

echo ">>> L4DToolZ 2.2.0 (accelerator74)"
curl_get "$L4DTOOLZ_URL" -o l4dtoolz.tar.gz
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
