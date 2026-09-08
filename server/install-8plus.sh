#!/usr/bin/env bash
# Pila Require de 8+ Survivors In Coop (Harry):
# https://github.com/fbef0102/Game-Private_Plugin/tree/main/Tutorial_教學區/English/Game/L4D2/8+_Survivors_In_Coop
set -euo pipefail

GAME_DIR="${1:-${GAME_DIR:-/home/steam/l4d2}}"
L4D2="$GAME_DIR/left4dead2"
SM="$L4D2/addons/sourcemod"
SM_PLUGINS="$SM/plugins"
SCRIPTING="$SM/scripting"
CACHE_DIR="${ADDON_CACHE_DIR:-$GAME_DIR/.addon-cache}"
FORCE_MS="${FORCE_MULTISLOTS_UPDATE:-${FORCE_8PLUS_UPDATE:-0}}"
if [[ "${FORCE_ADDON_INSTALL:-0}" == "1" ]]; then
  FORCE_MS=1
fi
STAMP="$CACHE_DIR/8plus-coop.stamp"
STAMP_VER="2026-09-08-actions-gamedata"

HARRY_RAW="${HARRY_RAW:-https://raw.githubusercontent.com/fbef0102/L4D1_2-Plugins/master}"
L4DHOOKS_URL="${L4DHOOKS_URL:-https://github.com/SilvDev/Left4DHooks/archive/refs/heads/main.tar.gz}"
MULTICOLORS_URL="${MULTICOLORS_URL:-https://github.com/fbef0102/L4D1_2-Plugins/releases/download/Multi-Colors/multicolors.zip}"
STRIPPER_URL="${STRIPPER_URL:-https://github.com/alliedmodders/stripper-source/releases/download/v1.2.2-git147/stripper-1.2.2-git147-linux.tar.gz}"
ACTIONS_URL="${ACTIONS_URL:-https://github.com/Vinillia/actions.ext/releases/download/v4.0.1/actions.ext.zip}"
SCRAMBLE_URL="${SCRAMBLE_URL:-https://github.com/nosoop/SMExt-SourceScramble/releases/download/0.8.2.2/package.tar.gz}"
LUX_TAR_URL="${LUX_TAR_URL:-https://github.com/LuxLuma/Left-4-fix/archive/refs/heads/master.tar.gz}"
MOYU_TAR_URL="${MOYU_TAR_URL:-https://github.com/Target5150/MoYu_Server_Stupid_Plugins/archive/refs/heads/master.tar.gz}"
CMD_BUF_TAR_URL="${CMD_BUF_TAR_URL:-https://github.com/SilvDev/Command_Buffer/archive/refs/heads/main.tar.gz}"
LADDER_TAR_URL="${LADDER_TAR_URL:-https://github.com/SilvDev/Ladder_Server_Crash-Fix/archive/refs/heads/main.tar.gz}"
IDENTITY_SP_URL="${IDENTITY_SP_URL:-https://raw.githubusercontent.com/Jackzmc/sourcemod-plugins/master/scripting/l4d_survivor_identity_fix.sp}"
TR_SP_URL="${TR_SP_URL:-https://raw.githubusercontent.com/umlka/l4d2/main/transition_restore_fix/transition_restore_fix.sp}"
TR_GD_URL="${TR_GD_URL:-https://raw.githubusercontent.com/umlka/l4d2/main/transition_restore_fix/transition_restore_fix.txt}"

curl_get() {
  curl -fsSL --retry 3 --retry-delay 2 \
    -A "Mozilla/5.0 (compatible; l4d2-8plus/1.0)" \
    "$@"
}

extract_zip() {
  python3 - "$1" "$2" <<'PY'
import sys, zipfile
zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])
PY
}

download_cached() {
  local url="$1"
  local dest="$2"
  if [[ -f "$dest" && -s "$dest" && "$FORCE_MS" != "1" ]]; then
    echo "    cache hit: $(basename "$dest")" >&2
    printf '%s\n' "$dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  echo "    $url" >&2
  curl_get "$url" -o "$dest.partial"
  mv -f "$dest.partial" "$dest"
  printf '%s\n' "$dest"
}

unpack_tar() {
  local url="$1"
  local cache_name="$2"
  local tar tmp dir
  tar="$(download_cached "$url" "$CACHE_DIR/$cache_name")"
  tmp="$(mktemp -d)"
  tar -xzf "$tar" -C "$tmp"
  dir="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d -print -quit)"
  printf '%s\n' "$dir"
}

find_spcomp() {
  if [[ -x "$SCRIPTING/spcomp64" ]]; then
    printf '%s\n' "$SCRIPTING/spcomp64"
  elif [[ -x "$SCRIPTING/spcomp" ]]; then
    printf '%s\n' "$SCRIPTING/spcomp"
  elif [[ -f "$SCRIPTING/spcomp64" ]]; then
    chmod +x "$SCRIPTING/spcomp64"
    printf '%s\n' "$SCRIPTING/spcomp64"
  elif [[ -f "$SCRIPTING/spcomp" ]]; then
    chmod +x "$SCRIPTING/spcomp"
    printf '%s\n' "$SCRIPTING/spcomp"
  else
    return 1
  fi
}

cleanup_tmp_root() {
  local root="${1:-}"
  [[ -n "$root" && "$root" == /tmp/* && -d "$root" ]] || return 0
  rm -rf "$(dirname "$root")"
}

strip_crlf() {
  local f
  for f in "$@"; do
    [[ -f "$f" ]] || continue
    sed -i 's/\r$//' "$f"
  done
}

copy_sm_tree() {
  local root="$1"
  [[ -d "$root" ]] || return 1
  if [[ -d "$root/gamedata" ]]; then
    mkdir -p "$SM/gamedata"
    cp -a "$root/gamedata/." "$SM/gamedata/"
  fi
  if [[ -d "$root/translations" ]]; then
    mkdir -p "$SM/translations"
    cp -a "$root/translations/." "$SM/translations/"
  fi
  if [[ -d "$root/data" ]]; then
    mkdir -p "$SM/data"
    cp -a "$root/data/." "$SM/data/"
  fi
  if [[ -d "$root/scripting/include" ]]; then
    mkdir -p "$SCRIPTING/include"
    cp -a "$root/scripting/include/." "$SCRIPTING/include/"
  fi
  find "$root" -type f \( -name '*.sp' -o -name '*.inc' -o -name '*.txt' \) -print0 \
    | xargs -0 -r sed -i 's/\r$//'
}

compile_sp_dir() {
  local root="$1"
  local spcomp="$2"
  local sp base
  [[ -d "$root/scripting" ]] || return 0
  while IFS= read -r -d "" sp; do
    base="$(basename "$sp" .sp)"
    echo "    compile $base"
    if ! (
      cd "$SCRIPTING"
      cp -f "$sp" "$SCRIPTING/$base.sp"
      "$spcomp" "$base.sp" -o"$SM_PLUGINS/$base.smx"
    ); then
      echo "WARN: falló $base.sp" >&2
      return 1
    fi
  done < <(find "$root/scripting" -maxdepth 1 -type f -name '*.sp' -print0)
}

install_plugin_tree() {
  local root="$1"
  local spcomp="$2"
  copy_sm_tree "$root"
  compile_sp_dir "$root" "$spcomp"
}

copy_harry_plugin() {
  local name="$1"
  local dest="$2"
  local src="/home/steam/plugins-src/${name}"
  mkdir -p "$dest"
  if [[ -d "$src/scripting" ]]; then
    echo "    local $name"
    cp -a "$src/." "$dest/"
    return 0
  fi
  echo "    github $name"
  python3 - "$HARRY_RAW" "$name" "$dest" <<'PY'
import os, sys, urllib.request
raw, name, dest = sys.argv[1], sys.argv[2], sys.argv[3]
ua = {"User-Agent": "l4d2-8plus/1.0"}
def get(url, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    req = urllib.request.Request(url, headers=ua)
    with urllib.request.urlopen(req) as r, open(path, "wb") as f:
        f.write(r.read())
base = f"{raw}/{name}"
sp = os.path.join(dest, "scripting", f"{name}.sp")
get(f"{base}/scripting/{name}.sp", sp)
optional = [
    (f"{base}/scripting/include/{name}.inc", os.path.join(dest, "scripting/include", f"{name}.inc")),
    (f"{base}/gamedata/{name}.txt", os.path.join(dest, "gamedata", f"{name}.txt")),
    (f"{base}/translations/{name}.phrases.txt", os.path.join(dest, "translations", f"{name}.phrases.txt")),
]
if name == "l4d_CreateSurvivorBot":
    optional.append((f"{base}/scripting/include/l4d_CreateSurvivorBot.inc", os.path.join(dest, "scripting/include/l4d_CreateSurvivorBot.inc")))
if name == "spawn_infected_nolimit":
    optional.append((f"{base}/scripting/include/spawn_infected_nolimit.inc", os.path.join(dest, "scripting/include/spawn_infected_nolimit.inc")))
for url, path in optional:
    try:
        get(url, path)
    except Exception:
        pass
PY
}

if [[ ! -f "$L4D2/addons/metamod.vdf" ]]; then
  echo "ERROR: MetaMod/SourceMod no están" >&2
  exit 1
fi

mkdir -p "$SM_PLUGINS" "$SM/gamedata" "$SM/data" "$SM/translations" \
  "$SM/extensions" "$SCRIPTING/include" "$CACHE_DIR" "$L4D2/addons/metamod"

if [[ -f "$STAMP" && "$FORCE_MS" != "1" ]] && grep -qx "$STAMP_VER" "$STAMP" \
    && [[ -f "$SM_PLUGINS/l4dmultislots.smx" && -f "$SM_PLUGINS/l4d_unreservelobby.smx" ]]; then
  echo ">>> 8+ coop stack ya instalada ($STAMP_VER)"
  exit 0
fi

spcomp="$(find_spcomp)" || {
  echo "ERROR: no hay spcomp en $SCRIPTING" >&2
  exit 1
}

echo ">>> Stripper:Source"
stripper_tar="$(download_cached "$STRIPPER_URL" "$CACHE_DIR/stripper-linux.tar.gz")"
tar -xzf "$stripper_tar" -C "$L4D2"
if [[ -f "$L4D2/addons/metamod/stripper.vdf" ]] || [[ -f "$L4D2/addons/stripper.vdf" ]]; then
  echo "    stripper listo"
else
  echo "WARN: no se vio stripper.vdf" >&2
fi

echo ">>> Actions extension"
actions_zip="$(download_cached "$ACTIONS_URL" "$CACHE_DIR/actions.ext.zip")"
actions_tmp="$(mktemp -d)"
extract_zip "$actions_zip" "$actions_tmp"
# v4 zip: extensions/ + gamedata/ + scripting/ (no addons/sourcemod).
# El fallback viejo copiaba el .so y se saltaba actions.games.txt →
# "Required extension Actions file(actions.ext) not running".
actions_root="$actions_tmp"
if [[ -d "$actions_tmp/addons/sourcemod" ]]; then
  actions_root="$actions_tmp/addons/sourcemod"
elif [[ -d "$actions_tmp/sourcemod" ]]; then
  actions_root="$actions_tmp/sourcemod"
fi
if [[ -d "$actions_root/gamedata" ]]; then
  cp -a "$actions_root/gamedata/." "$SM/gamedata/"
fi
if [[ -d "$actions_root/scripting/include" ]]; then
  cp -a "$actions_root/scripting/include/." "$SCRIPTING/include/"
else
  find "$actions_tmp" -name 'actions*.inc' -exec cp -f {} "$SCRIPTING/include/" \;
fi
actions_so="$(find "$actions_root" "$actions_tmp" -name 'actions.ext.2.l4d2.so' ! -path '*/x64/*' -print -quit)"
if [[ -z "$actions_so" ]]; then
  actions_so="$(find "$actions_tmp" -name 'actions.ext*.so' ! -path '*/x64/*' ! -name '*tf2*' ! -name '*l4d.so' -print -quit)"
fi
if [[ -n "$actions_so" ]]; then
  cp -f "$actions_so" "$SM/extensions/$(basename "$actions_so")"
  echo "    $(basename "$actions_so")"
else
  echo "ERROR: no hay actions.ext*.so de Linux L4D2 en el zip" >&2
  rm -rf "$actions_tmp"
  exit 1
fi
rm -rf "$actions_tmp"
if [[ ! -f "$SM/gamedata/actions.games.txt" ]]; then
  echo "ERROR: falta gamedata/actions.games.txt (Actions no arranca sin eso)" >&2
  exit 1
fi
touch "$SM/extensions/actions.autoload" || true

echo ">>> Source Scramble"
scramble_tar="$(download_cached "$SCRAMBLE_URL" "$CACHE_DIR/sourcescramble.tar.gz")"
scramble_tmp="$(mktemp -d)"
tar -xzf "$scramble_tar" -C "$scramble_tmp"
if [[ -d "$scramble_tmp/addons/sourcemod" ]]; then
  cp -a "$scramble_tmp/addons/sourcemod/." "$SM/"
else
  # package.tar.gz suele ser addons/sourcemod relativo o el propio sourcemod
  find "$scramble_tmp" -name 'sourcescramble.ext*.so' -exec cp -f {} "$SM/extensions/" \;
  find "$scramble_tmp" -name 'sourcescramble.inc' -exec cp -f {} "$SCRIPTING/include/" \;
  # a veces el tar ya es la carpeta sourcemod
  if [[ -d "$scramble_tmp/extensions" ]]; then
    cp -a "$scramble_tmp/." "$SM/"
  fi
fi
rm -rf "$scramble_tmp"

echo ">>> Left 4 DHooks"
hooks_root="$(unpack_tar "$L4DHOOKS_URL" "left4dhooks-main.tar.gz")"
hooks_sm="$(find "$hooks_root" -type d -name sourcemod -print -quit)"
cp -f "$hooks_sm/plugins/left4dhooks.smx" "$SM_PLUGINS/"
cp -a "$hooks_sm/gamedata/." "$SM/gamedata/"
[[ -d "$hooks_sm/data" ]] && cp -a "$hooks_sm/data/." "$SM/data/"
cp -a "$hooks_sm/scripting/include/." "$SCRIPTING/include/"
cleanup_tmp_root "$hooks_root"

echo ">>> Multi Colors"
colors_zip="$(download_cached "$MULTICOLORS_URL" "$CACHE_DIR/multicolors.zip")"
colors_tmp="$(mktemp -d)"
extract_zip "$colors_zip" "$colors_tmp"
if [[ -d "$colors_tmp/scripting/include" ]]; then
  cp -a "$colors_tmp/scripting/include/." "$SCRIPTING/include/"
else
  cp -a "$colors_tmp/." "$SCRIPTING/"
fi
rm -rf "$colors_tmp"

echo ">>> Plugins Harry (L4D1_2-Plugins)"
HARRY_PLUGINS=(
  l4d_CreateSurvivorBot
  spawn_infected_nolimit
  l4dmultislots
  l4d_unreservelobby
  l4dafkfix_deadbot
  l4d_both_fixUpgradePack
  l4d2_trigger_flow_fix
  l4d2_vocalizebasedmodel
  l4d2_transition_info_fix
  l4d2_maptankfix
  l4d2_rescue_vehicle_multi
  l4d_full_slot_bot_replace_fix
)
harry_fail=0
for name in "${HARRY_PLUGINS[@]}"; do
  work="$(mktemp -d)"
  if copy_harry_plugin "$name" "$work"; then
    if ! install_plugin_tree "$work" "$spcomp"; then
      echo "WARN: no compiló $name" >&2
      harry_fail=1
    fi
  else
    echo "WARN: no se pudo obtener $name" >&2
    harry_fail=1
  fi
  rm -rf "$work"
done
if [[ ! -f "$SM_PLUGINS/l4dmultislots.smx" || ! -f "$SM_PLUGINS/l4d_CreateSurvivorBot.smx" ]]; then
  echo "ERROR: faltan l4dmultislots / CreateSurvivorBot" >&2
  exit 1
fi
if [[ ! -f "$SM_PLUGINS/l4d_unreservelobby.smx" ]]; then
  echo "ERROR: falta l4d_unreservelobby (sin esto el 5º no entra por IP)" >&2
  exit 1
fi

echo ">>> Lux Left-4-fix (defib, charger, witch, AFK)"
lux_root="$(unpack_tar "$LUX_TAR_URL" "left4fix-master.tar.gz")"
for rel in \
    "left 4 fix/Defib_Fix" \
    "left 4 fix/charger/Charger_Collision_patch" \
    "left 4 fix/witch/witch_target_patch" \
    "left 4 fix/survivors/survivor_afk_fix"
do
  if [[ -d "$lux_root/$rel" ]]; then
    install_plugin_tree "$lux_root/$rel" "$spcomp" || echo "WARN: Lux $rel" >&2
  else
    echo "WARN: no está $rel en Left-4-fix" >&2
  fi
done
cleanup_tmp_root "$lux_root"

echo ">>> MoYu (changelevel, character mixed, target replace)"
moyu_root="$(unpack_tar "$MOYU_TAR_URL" "moyu-master.tar.gz")"
for rel in \
    "The Last Stand/l4d2_fix_changelevel" \
    "The Last Stand/l4d2_fix_character_mixed" \
    "The Last Stand/l4d_fix_target_replace"
do
  if [[ -d "$moyu_root/$rel" ]]; then
    install_plugin_tree "$moyu_root/$rel" "$spcomp" || echo "WARN: MoYu $rel" >&2
  else
    echo "WARN: no está $rel en MoYu" >&2
  fi
done
cleanup_tmp_root "$moyu_root"

echo ">>> Silvers Command Buffer + Ladder crash"
cmd_root="$(unpack_tar "$CMD_BUF_TAR_URL" "command-buffer-main.tar.gz")"
install_plugin_tree "$cmd_root" "$spcomp" || echo "WARN: Command_Buffer" >&2
cleanup_tmp_root "$cmd_root"
ladder_root="$(unpack_tar "$LADDER_TAR_URL" "ladder-crash-main.tar.gz")"
install_plugin_tree "$ladder_root" "$spcomp" || echo "WARN: Ladder crash" >&2
cleanup_tmp_root "$ladder_root"

echo ">>> Survivor Identity Fix (Shadowysn / Jackz fork)"
curl_get "$IDENTITY_SP_URL" -o "$SCRIPTING/l4d_survivor_identity_fix.sp"
sed -i 's/\r$//' "$SCRIPTING/l4d_survivor_identity_fix.sp"
sed -i 's/#define DEBUG 1/#define DEBUG 0/' "$SCRIPTING/l4d_survivor_identity_fix.sp"
if [[ -f /home/steam/gamedata-drop/l4d_survivor_identity_fix.txt ]]; then
  cp -f /home/steam/gamedata-drop/l4d_survivor_identity_fix.txt "$SM/gamedata/"
fi
(
  cd "$SCRIPTING"
  "$spcomp" l4d_survivor_identity_fix.sp -o"$SM_PLUGINS/l4d_survivor_identity_fix.smx"
) || echo "WARN: identity fix no compiló (clientprefs / gamedata)" >&2

echo ">>> Transition Restore Fix (sorallll / umlka)"
curl_get "$TR_SP_URL" -o "$SCRIPTING/transition_restore_fix.sp"
sed -i 's/\r$//' "$SCRIPTING/transition_restore_fix.sp"
curl_get "$TR_GD_URL" -o "$SM/gamedata/transition_restore_fix.txt"
(
  cd "$SCRIPTING"
  "$spcomp" transition_restore_fix.sp -o"$SM_PLUGINS/transition_restore_fix.smx"
) || echo "WARN: Transition Restore Fix no compiló (DHooks / Source Scramble / gamedata)" >&2

printf '%s\n' "$STAMP_VER" > "$STAMP"
echo ">>> 8+ coop Require listo"
if [[ "$harry_fail" -ne 0 ]]; then
  echo ">>> Aviso: algún plugin de Harry no compiló; mira WARN arriba"
fi
