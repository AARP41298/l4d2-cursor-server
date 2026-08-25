#!/usr/bin/env bash
# Baja mapas/addons del Workshop (app 550) y los copia a left4dead2/addons.
set -euo pipefail

GAME_DIR="${1:-/home/steam/l4d2}"
STEAMCMD="${STEAMCMD:-/home/steam/steamcmd/steamcmd.sh}"
WORKSHOP_APP=550
FORCE="${FORCE_WORKSHOP_UPDATE:-0}"
ADDONS="$GAME_DIR/left4dead2/addons"
EXPAND="/home/steam/expand-workshop.py"

IDS_RAW="${WORKSHOP_IDS:-}"
if [[ -z "$IDS_RAW" ]]; then
  echo ">>> Workshop: WORKSHOP_IDS vacío; no se bajan mapas"
  exit 0
fi

IDS_RAW="${IDS_RAW//,/ }"
read -r -a ROOT_IDS <<< "$IDS_RAW"
if [[ ${#ROOT_IDS[@]} -eq 0 ]]; then
  echo ">>> Workshop: WORKSHOP_IDS vacío; no se bajan mapas"
  exit 0
fi

echo ">>> Workshop: expandiendo ${ROOT_IDS[*]}"
mapfile -t FILE_IDS < <(python3 "$EXPAND" "${ROOT_IDS[@]}")
if [[ ${#FILE_IDS[@]} -eq 0 ]]; then
  echo ">>> Workshop: la API no devolvió ítems"
  exit 0
fi
echo ">>> Workshop: ${#FILE_IDS[@]} ítem(s) a instalar"

steamcmd_login=(+login anonymous)
if [[ -n "${STEAM_USER:-}" && "$STEAM_USER" != "anonymous" ]]; then
  steamcmd_login=(+login "$STEAM_USER")
  [[ -n "${STEAM_PASS:-}" ]] && steamcmd_login+=("$STEAM_PASS")
  [[ -n "${STEAM_GUARD:-}" ]] && steamcmd_login+=("$STEAM_GUARD")
fi

workshop_dirs=(
  "$GAME_DIR/steamapps/workshop/content/${WORKSHOP_APP}"
  "$HOME/Steam/steamapps/workshop/content/${WORKSHOP_APP}"
)

item_present() {
  local id="$1" dir
  for dir in "${workshop_dirs[@]}"; do
    if [[ -n "$(find "$dir/$id" -type f -print -quit 2>/dev/null)" ]]; then
      return 0
    fi
  done
  return 1
}

to_download=()
for id in "${FILE_IDS[@]}"; do
  [[ -z "$id" ]] && continue
  if [[ "$FORCE" != "1" ]] && item_present "$id"; then
    continue
  fi
  to_download+=("$id")
done

if [[ ${#to_download[@]} -gt 0 ]]; then
  echo ">>> Workshop: SteamCMD baja ${#to_download[@]} ítem(s) (app ${WORKSHOP_APP})"
  cmd=("$STEAMCMD" +force_install_dir "$GAME_DIR" "${steamcmd_login[@]}")
  for id in "${to_download[@]}"; do
    cmd+=(+workshop_download_item "$WORKSHOP_APP" "$id")
  done
  cmd+=(+quit)
  "${cmd[@]}" || echo ">>> Workshop: SteamCMD devolvió error; se copian los addons que haya"
else
  echo ">>> Workshop: caché ya está; FORCE_WORKSHOP_UPDATE=1 para re-bajar"
fi

mkdir -p "$ADDONS"
copied=0
copy_workshop_file() {
  local src="$1"
  local id="$2"
  local base dest
  base="$(basename "$src")"
  case "${base,,}" in
    *.vpk)
      dest="$ADDONS/${id}-${base}"
      ;;
    *_legacy.bin|*.bin)
      dest="$ADDONS/${id}-${base%.*}.vpk"
      ;;
    *)
      return 0
      ;;
  esac
  cp -f "$src" "$dest"
  copied=$((copied + 1))
  echo "    $dest"
}

for id in "${FILE_IDS[@]}"; do
  [[ -z "$id" ]] && continue
  for dir in "${workshop_dirs[@]}"; do
    [[ -d "$dir/$id" ]] || continue
    while IFS= read -r -d "" src; do
      copy_workshop_file "$src" "$id"
    done < <(find "$dir/$id" -type f \( -iname '*.vpk' -o -iname '*_legacy.bin' -o -iname '*.bin' \) -print0 2>/dev/null)
  done
done

echo ">>> Workshop: $copied addon(s) en $ADDONS"
echo ">>> Workshop: changelevel con el mapa (en consola: maps *)"
