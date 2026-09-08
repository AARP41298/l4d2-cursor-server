# L4D2 8+ — servidor dedicado para más de 4 jugadores

Left 4 Dead 2 deja campaña en **4** y Versus en **8**. Subir `sv_maxplayers` no basta: el binario rechaza la quinta conexión. La forma estable es un **dedicated Linux** con tres capas encima:

1. **MetaMod + SourceMod** — cargan plugins.
2. **L4DToolZ** (fork de [accelerator74](https://github.com/accelerator74/l4dtoolz), 2.2.0) — abre el cupo del motor. El zip viejo de AlliedModders ya no carga.
3. **[8+ Survivors In Coop](https://github.com/fbef0102/Game-Private_Plugin/tree/main/Tutorial_教學區/English/Game/L4D2/8+_Survivors_In_Coop)** (Harry) — Stripper, Left 4 DHooks, Actions, **l4dmultislots**, **l4d_unreservelobby** y los fixes 5+. Sin esto el 5º entra de espectador o Valve lo corta en 4/4. No uses ABM ni SuperVersus: chocan con l4dmultislots.

Este repo trae Docker para el dedicated, configs listas y un asistente web que genera `.env` / `server.cfg`.

## Requisitos

- Docker y Docker Compose
- ~15 GB de disco (la primera bajada del dedicated son ~10 GB)
- UDP **y** TCP **27016** abiertos hacia la máquina (en esta PC el juego ya ocupa el 27015; el dedicated se publica en 27016. UDP es el juego; TCP es RCON)
- 2 vCPU / 4 GB RAM sobran para 8 en campaña

Un listen server («Local») con `-insecure` sirve para una noche. SourceMod no lo soporta en serio y si el host se cae, se acaba la run.

## Levantar el servidor

```bash
cp .env.example .env
# edita SRCDS_HOSTNAME, SRCDS_RCONPW y SRCDS_MAXPLAYERS
docker compose up --build
```

La primera vez SteamCMD instala el dedicated (app 222860) y el entrypoint mete MetaMod, SourceMod, L4DToolZ y la pila **8+ Survivors In Coop**. Los ficheros del juego quedan en el volumen `l4d2-game`.

Si SteamCMD dice `needs to be online` / `Couldn't resolve host name`: el binario 32-bit no usa el DNS interno de Docker. Compose ya pone `8.8.8.8` y `1.1.1.1`. Apaga VPN, vuelve a `docker compose up --build`.

### 8+ coop (tutorial de Harry)

La guía es [8+ Survivors In Coop](https://github.com/fbef0102/Game-Private_Plugin/tree/main/Tutorial_教學區/English/Game/L4D2/8+_Survivors_In_Coop). El contenedor instala la sección **Require** (y Prepare: Stripper, Left 4 DHooks, Actions):

- **L4DToolZ** — cupo del motor
- **l4d_unreservelobby** — sin esto el 5º no entra por `connect` cuando el lobby está “lleno”
- **l4dmultislots** + **l4d_CreateSurvivorBot** — bots extra; `!join` / `!js`
- Fixes 5+: identity, AFK, deadbot, defib, charger collision, witch target, upgrade packs, changelevel, vocalize, rescue vehicle, tank de mapa, etc.

Compose monta `../L4D1_2-Plugins` y compila desde ahí. Si no está ese repo, se baja el source de GitHub. **8 Slots Lobby** es un addon de Workshop **en el cliente** ([2754956355](https://steamcommunity.com/sharedfiles/filedetails/?id=2754956355)), no en el dedicated.

No toques `survivor_limit`. No instales ABM / SuperVersus / bebop. El arranque los mueve a `plugins/disabled`.

Cvars del tutorial en `server.cfg`: `precache_all_survivors 1`, `sv_consistency 0`. En `cfg/sourcemod/l4dmultislots.cfg` el entrypoint pone:

```text
l4d_multislots_max_survivors "8"
l4d_multislots_min_survivors "8"
l4d_multislots_spawn_survivors_roundstart "1"
```

(el `8` es `SRCDS_MAXPLAYERS`). Para recompilar la pila: `FORCE_8PLUS_UPDATE=1`.

En consola comprueba el stack:

```text
status
meta list
sm exts list
sm plugins list
```

L4DToolZ *Running*, `l4dmultislots` y `l4d_unreservelobby` en `sm plugins list`. `status` **unreserved**. El 8º lobby de Valve sigue sin existir: hasta 8 puedes forzar dedicated; desde el 9º, `connect`.

**Actions** (Prepare del tutorial) hoy **no carga** en SourceMod 1.12: `sm exts list` muestra `actions.ext.2.l4d2.so` FAILED (`Extension version is too new to load (9, max is 8)`). Por eso `l4d_fix_target_replace` falla en `sm plugins list`. El zip de [Vinillia](https://github.com/Vinillia/actions.ext/releases) está compilado contra API 9 (SM 1.13); 1.12 solo admite 8. Lo dejamos así hasta que el autor publique un build para 1.12 — ver [issue #30](https://github.com/Vinillia/actions.ext/issues/30#issuecomment-5457903002). El resto de la pila 8+ sí corre.

No se instala **Character_manager** (choca con Identity Fix). De la lista Require, **InputKill Kick Prevention** (Shadowysn) solo está en AlliedModders y Cloudflare bloquea la bajada automática; si un mapa te saca con `Kicked by Console : CBaseEntity::InputKill()`, déjalo en `addons-drop`. **Transition Restore Fix** sí se baja de [umlka/l4d2](https://github.com/umlka/l4d2/tree/main/transition_restore_fix). Optional / Fun del tutorial no van.

## Consola del dedicated

`status`, `meta list`, `sm exts list` y `sm plugins list` son comandos de **srcds**, no de Linux. La pestaña de logs y Docker Desktop → Exec no sirven (Exec abre un `/bin/sh`).

En la máquina **donde corre el contenedor**:

```bash
docker attach l4d2-8plus
```

Escribe el comando y Enter. Para salir **sin apagar** el server: `Ctrl+P` y luego `Ctrl+Q`. `Ctrl+C` mata srcds.

Eso no es «solo local». Funciona en esta PC y en la otra: `docker attach` habla con Docker de *ese* host. Si el dedicated está en otro equipo, entra por SSH (o siéntate ahí) y lanza el mismo comando.

Desde el **juego** (cualquier PC de la red o Internet), con el puerto TCP **27016** abierto:

```text
rcon_password TU_SRCDS_RCONPW
rcon status
rcon meta list
rcon sm exts list
rcon sm plugins list
```

RCON es lo práctico cuando tú juegas en un sitio y el server está en otro.

## Mapas Workshop

En Windows usabas [Geam/steam_workshop_downloader](https://github.com/Geam/steam_workshop_downloader) contra la colección [2233971331](https://steamcommunity.com/sharedfiles/filedetails/?id=2233971331) ([gist](https://gist.github.com/AARP41298/f9ec90b2ecf594be24a90d98a5d8c4f0#for-mods)). Aquí SteamCMD hace lo mismo al arrancar.

Por defecto `.env` trae:

```env
WORKSHOP_IDS=2233971331
```

Esa colección anida (SteamCMD las expande):

| Campaña | Notas |
|---------|--------|
| Deathcraft II | Colección `122131588`. El autor pide no mezclar otros addons *mientras* la juegas. |
| The Hive | Colección `3514750197` (6 partes). |
| Resident Evil 1 | Casa Spencer. |
| Resident Evil 2 Side A / B | `re` maps de Roku. |
| Resident Evil 3 | Empieza en `re3m1` (Uptown). |
| Tank Challenge | Supervivencia de tanks. |
| Big Wat | 5 capítulos. |

La primera vez son **varios GB**. Luego quedan en el volumen `l4d2-game`. Para re-bajar: `FORCE_WORKSHOP_UPDATE=1`.

Para **no** bajar mapas: `WORKSHOP_IDS=` (vacío). Para añadir IDs sueltos o más colecciones:

```env
WORKSHOP_IDS=2233971331,122131588
```

Cuando termine el log (`>>> Workshop: N addon(s)`), en la consola srcds (`docker attach` o RCON):

```text
maps *
changelevel re3m1
```

Los clientes necesitan esos addons (suscritos en Workshop, o la descarga del dedicated con `sv_consistency 0` ya puesto). El server sigue arrancando en un mapa oficial (`SRCDS_STARTMAP`) aunque el Workshop falle.

## Cómo entran los jugadores

`status` muestra **tres IPs**. Es normal; cada una sirve para una cosa:

| Lo que ves | Ejemplo | Quién la usa |
|------------|---------|----------------|
| `udp/ip` del contenedor | `172.19.0.2:27015` | Nadie. Es la red interna de Docker. |
| `public` (Steam) | `189.243.210.111:27016` | Amigos **fuera** de tu casa, con el puerto reenviado. |
| IP de Windows | `192.168.68.106` | PCs en tu Wi‑Fi / LAN. |

Si el juego está **en la misma PC que Docker**, no uses la pública ni el puerto 27015: `left4dead2.exe` ya escucha UDP 27015 y se come los paquetes. En consola del cliente (`~`):

```text
connect 127.0.0.1:27016
```

O la LAN del Windows:

```text
connect 192.168.68.106:27016
```

Otra PC en casa: `connect 192.168.68.106:27016`. Por Internet: `connect 189.243.210.111:27016` (UDP **y** TCP 27016 del router a `192.168.68.106`).

El lobby de Valve no conoce un dedicated de 8 en campaña.

- **Hasta 8:** el host puede usar la mutación de Workshop *8 Player Lobby*, settings en Campaign, servidor *Best Available Dedicated*, y en consola (`mm_dedicated_force_servers` con la **misma** IP que usarías en `connect`).
- **Siempre funciona (y es obligatorio desde el 9º):** `connect` como arriba.

Si hay `sv_password`, primero `password la-clave` y luego `connect`.

## Comando de arranque

L4DToolZ **2.2** lee `-maxplayers`, no `+maxplayers`. El entrypoint ya lo pasa. No lo cambies a `+`.

## Asistente web (configs)

```bash
npm install
npm run dev
```

Abre [http://127.0.0.1:43217](http://127.0.0.1:43217). Ahí está el porqué del stack, el generador de configs y la guía de «si no entra el 5º».

## Hardware y cupo

| Jugadores | RAM | Notas |
|-----------|-----|--------|
| 5–8 | 2–4 GB | Punto dulce. Lobby usable con la mutación. |
| 9–12 | 4 GB | Solo `connect`. El director se siente inflado. |
| 13–18 | 4–8 GB | Límite práctico de L4DToolZ. Mapas estrechos van mal. |

Versus por encima de 4v4: l4dmultislots cubre el lado superviviente (`!join`). Para más infectados / 10v10 usa [l4dinfectedbots](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/l4dinfectedbots). No instales SuperVersus.

Kits extra para el 5º+ van en los cvars de l4dmultislots (`saferoom_extra_first_aid`, `finale_extra_first_aid`). Opcional: Extra Player Items (ammo) y [l4d_infected_limit_control](https://github.com/fbef0102/Game-Private_Plugin/tree/main/L4D_插件/Common_Infected_%E6%99%AE%E9%80%9A%E6%84%9F%E6%9F%93%E8%80%85/l4d_infected_limit_control) para hordas según el número de jugadores.

## Plugins del gist

En `server/addons-drop` van [Perkmod](https://forums.alliedmods.net/showthread.php?p=889437), [Country Nick](https://forums.alliedmods.net/showthread.php?p=738756) y [Infected Health Gauge](https://forums.alliedmods.net/showthread.php?t=125747), más GeoLite2-City para las banderas. Detalle en `server/addons-drop/README.md`.

Perkmod necesita a mano `plugin.perkmod.txt` (en el [post 647](https://forums.alliedmods.net/showpost.php?p=2329726) se llama `plugin.perkmod - all langs 1 file.txt`) en:

```text
server/addons-drop/addons/sourcemod/translations/plugin.perkmod.txt
```

Tras copiar, reinicia el contenedor. En consola: `sm plugins list`.

## Admin SourceMod

Edita `addons/sourcemod/configs/admins_simple.ini` dentro del volumen, o mételo vía `addons-drop`:

```text
"STEAM_1:0:TU_ID" "99:z"
```

El SteamID2 sale en <https://steamid.io>.

## Licencia

Kit de configuración. Left 4 Dead 2 es de Valve. MetaMod, SourceMod, L4DToolZ, l4dmultislots y el resto de la pila 8+ tienen sus propias licencias. No redistribuimos el juego ni los `.smx` de terceros.
