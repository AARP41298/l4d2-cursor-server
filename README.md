# L4D2 8+ — servidor dedicado para más de 4 jugadores

Left 4 Dead 2 deja campaña en **4** y Versus en **8**. Subir `sv_maxplayers` no basta: el binario rechaza la quinta conexión. La forma estable es un **dedicated Linux** con tres capas encima:

1. **MetaMod + SourceMod** — cargan plugins.
2. **L4DToolZ** (fork de [accelerator74](https://github.com/accelerator74/l4dtoolz), 2.2.0) — abre el cupo del motor. El zip viejo de AlliedModders ya no carga.
3. **ABM** — spawnea supervivientes extra y escala infectados. Sin esto, el 5º entra de espectador.

Este repo trae Docker para el dedicated, configs listas y un asistente web que genera `.env` / `server.cfg`.

## Requisitos

- Docker y Docker Compose
- ~15 GB de disco (la primera bajada del dedicated son ~10 GB)
- UDP **y** TCP 27015 abiertos hacia la máquina
- 2 vCPU / 4 GB RAM sobran para 8 en campaña

Un listen server («Local») con `-insecure` sirve para una noche. SourceMod no lo soporta en serio y si el host se cae, se acaba la run.

## Levantar el servidor

```bash
cp .env.example .env
# edita SRCDS_HOSTNAME, SRCDS_RCONPW y SRCDS_MAXPLAYERS
docker compose up --build
```

La primera vez SteamCMD instala el dedicated (app 222860) y el entrypoint mete MetaMod, SourceMod y L4DToolZ. Los ficheros del juego quedan en el volumen `l4d2-game`.

### ABM (obligatorio para el 5º personaje)

AlliedModders bloquea descargas automáticas. A mano:

1. Hilo: <https://forums.alliedmods.net/showthread.php?t=291562>
2. Baja **abm.smx** (adjunto compilado, no pulses «Get Plugin») y **abm.txt**
3. Colócalos así:

```text
server/addons-drop/addons/sourcemod/plugins/abm.smx
server/addons-drop/addons/sourcemod/gamedata/abm.txt
```

4. Reinicia el contenedor. El entrypoint copia `addons-drop` encima del dedicated en cada arranque.

En la consola del servidor tiene que salir L4DToolZ *Running* y ABM en `sm plugins list`:

```text
meta list
sm plugins list
status
```

`status` debe mostrar el servidor **unreserved**.

## Cómo entran los jugadores

El lobby de Valve no conoce un dedicated de 8 en campaña.

- **Hasta 8:** el host puede usar la mutación de Workshop *8 Player Lobby*, settings en Campaign, servidor *Best Available Dedicated*, y en consola:

  ```text
  mm_dedicated_force_servers TU.IP.PUBLICA:27015
  ```

- **Siempre funciona (y es obligatorio desde el 9º):**

  ```text
  connect TU.IP.PUBLICA:27015
  ```

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

Versus por encima de 4v4 pide SuperVersus además de (o en lugar de) ABM.

Opcional con 8+: [Left 4 DHooks](https://forums.alliedmods.net/showthread.php?t=321696) y Extra Player Items (kits/ammo para el 5º). No hacen falta para que entren.

## Admin SourceMod

Edita `addons/sourcemod/configs/admins_simple.ini` dentro del volumen, o mételo vía `addons-drop`:

```text
"STEAM_1:0:TU_ID" "99:z"
```

El SteamID2 sale en <https://steamid.io>.

## Licencia

Kit de configuración. Left 4 Dead 2 es de Valve. MetaMod, SourceMod, L4DToolZ y ABM tienen sus propias licencias. No redistribuimos el juego ni los `.smx` de terceros.
