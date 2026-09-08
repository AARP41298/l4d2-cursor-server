#!/usr/bin/env bash
# Instala MetaMod, SourceMod, L4DToolZ y la pila 8+ coop (install-8plus.sh).
# Idempotente: si MetaMod ya está, no pisa MM/SM/L4DToolZ salvo FORCE_ADDON_INSTALL=1.
# FORCE_MULTISLOTS_UPDATE=1 o FORCE_8PLUS_UPDATE=1 recompila la pila 8+.
# Los tar se guardan en $GAME_DIR/.addon-cache (volumen) para no re-descargar.
set -euo pipefail

GAME_DIR="${1:-/home/steam/l4d2}"
L4D2="$GAME_DIR/left4dead2"
SM="$L4D2/addons/sourcemod"
FORCE="${FORCE_ADDON_INSTALL:-0}"
CACHE_DIR="${ADDON_CACHE_DIR:-$GAME_DIR/.addon-cache}"

# AlliedModders ya no sirve mmsource-latest-linux.tar.gz (es un puntero de texto
# o Cloudflare 403). GitHub Releases es el espejo estable; el puntero solo
# dice el nombre del tar actual para saber si hay versión nueva.
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

github_mirror_url() {
  local name="$1"
  if [[ "$name" =~ ^mmsource-([0-9]+\.[0-9]+\.[0-9]+)-git([0-9]+)-linux\.tar\.gz$ ]]; then
    printf 'https://github.com/alliedmodders/metamod-source/releases/download/%s.%s/%s\n' \
      "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$name"
    return 0
  fi
  if [[ "$name" =~ ^sourcemod-([0-9]+\.[0-9]+\.[0-9]+)-git([0-9]+)-linux\.tar\.gz$ ]]; then
    printf 'https://github.com/alliedmodders/sourcemod/releases/download/%s.%s/%s\n' \
      "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$name"
    return 0
  fi
  return 1
}

prune_addon_cache() {
  local prefix="$1"
  local keep="$2"
  local f
  for f in "$CACHE_DIR/${prefix}"*.tar.gz; do
    [[ -e "$f" ]] || continue
    [[ "$(basename "$f")" == "$keep" ]] && continue
    echo "    cache: quitando $(basename "$f")" >&2
    rm -f "$f"
  done
}

# Descarga (o reutiliza) el tar de la versión actual.
# Logs a stderr; imprime la ruta del tar en stdout.
# Si el tar ya está en cache, no descarga (sirve para FORCE_ADDON_INSTALL).
# Si el puntero indica un nombre distinto, descarga y sustituye el cache viejo.
download_addon() {
  local github_url="$1"
  local latest_ptr="$2"
  local prefix="$3"
  local github_name name cached partial url mirror="" drop="" seen=""

  mkdir -p "$CACHE_DIR"
  github_name="$(basename "$github_url")"
  name="$github_name"

  if [[ -n "$latest_ptr" ]]; then
    echo "    versión actual: $latest_ptr" >&2
    name="$(curl_get "$latest_ptr" | tr -d '\r\n[:space:]')" || true
    if [[ -z "$name" || "$name" != *.tar.gz ]]; then
      echo "    puntero no disponible; se usa $github_name" >&2
      name="$github_name"
    else
      echo "    actual: $name" >&2
    fi
  fi

  cached="$CACHE_DIR/$name"
  if [[ -f "$cached" && -s "$cached" ]]; then
    echo "    cache hit: $name" >&2
    printf '%s\n' "$cached"
    return 0
  fi

  partial="$cached.partial"
  rm -f "$partial"

  mirror="$(github_mirror_url "$name" || true)"
  if [[ -n "$latest_ptr" && "$name" == *.tar.gz ]]; then
    drop="${latest_ptr%/*}/${name}"
  fi

  for url in "$mirror" "$github_url" "$drop"; do
    [[ -n "$url" ]] || continue
    case " $seen " in
      *" $url "*) continue ;;
    esac
    seen+=" $url "
    echo "    $url" >&2
    if curl_get "$url" -o "$partial"; then
      mv -f "$partial" "$cached"
      prune_addon_cache "$prefix" "$name"
      printf '%s\n' "$cached"
      return 0
    fi
    rm -f "$partial"
  done

  echo "ERROR: no se pudo descargar $name" >&2
  return 1
}

install_mm_sm_l4dtoolz() {
  mkdir -p "$L4D2"
  if [[ -f "$L4D2/addons/metamod.vdf" && "$FORCE" != "1" ]]; then
    echo ">>> Addons ya presentes (FORCE_ADDON_INSTALL=1 para reinstalar MM/SM/L4DToolZ)"
    return 0
  fi

  echo ">>> MetaMod:Source"
  MMS_TAR="$(download_addon "$MMS_URL" "$MMS_LATEST_PTR" "mmsource-")"
  tar -xzf "$MMS_TAR" -C "$L4D2"

  echo ">>> SourceMod"
  SM_TAR="$(download_addon "$SM_URL" "$SM_LATEST_PTR" "sourcemod-")"
  tar -xzf "$SM_TAR" -C "$L4D2"

  echo ">>> L4DToolZ 2.2.0 (accelerator74)"
  L4DTOOLZ_TAR="$(download_addon "$L4DTOOLZ_URL" "" "l4dtoolz-")"
  tar -xzf "$L4DTOOLZ_TAR" -C "$L4D2"

  ADMINS="$SM/configs/admins_simple.ini"
  if [[ -f "$ADMINS" ]] && ! grep -q "STEAM_1:0:0000" "$ADMINS"; then
    {
      echo ""
      echo "// Pon tu SteamID2 aquí, por ejemplo:"
      echo '// "STEAM_1:0:12345678" "99:z"'
    } >> "$ADMINS"
  fi

  echo ">>> MetaMod + SourceMod + L4DToolZ listos"
}

install_mm_sm_l4dtoolz
/home/steam/install-8plus.sh "$GAME_DIR"
