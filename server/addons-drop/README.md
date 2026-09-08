Plugins del gist (https://gist.github.com/AARP41298/f9ec90b2ecf594be24a90d98a5d8c4f0#plugin-example).

El entrypoint copia esta carpeta encima del dedicated en cada arranque.

## Ya incluidos

- `plugins/perkmod2.smx` — [Perkmod](https://forums.alliedmods.net/showthread.php?p=889437) compilado (perkmod2.sp).
- `plugins/countrynick.smx` — [Country Nick](https://forums.alliedmods.net/showthread.php?p=738756) 1.2.3_fix.
- `plugins/l4d_infectedhp.smx` — [Infected Health Gauge](https://forums.alliedmods.net/showthread.php?t=125747).
- `translations/countrynick.phrases.txt`
- GeoIP: `configs/geoip/GeoLite2-City.mmdb` (o el entrypoint la baja de [P3TERX/GeoLite.mmdb](https://github.com/P3TERX/GeoLite.mmdb)).

## Perkmod: traducción (obligatoria para los menús)

AlliedModders bloquea el adjunto. A mano:

1. Post: https://forums.alliedmods.net/showpost.php?p=2329726
2. Baja `plugin.perkmod - all langs 1 file.txt`
3. Renómbralo a `plugin.perkmod.txt`
4. Déjalo en `addons/sourcemod/translations/plugin.perkmod.txt`

## l4dmultislots / 8+ coop

Lo instala el entrypoint según el tutorial 8+ Survivors In Coop (Require). No pongas ABM, SuperVersus ni Character_manager aquí.

Opcional a mano: **InputKill Kick Prevention** (`l4d2_client_inputkill_prevention.smx`) si un mapa te saca con `CBaseEntity::InputKill()` — AlliedModders bloquea la bajada automática.
