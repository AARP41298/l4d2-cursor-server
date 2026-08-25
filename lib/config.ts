export const MAPS = [
  { id: "c1m1_hotel", campaign: "Dead Center", name: "Hotel" },
  { id: "c2m1_highway", campaign: "Dark Carnival", name: "Highway" },
  { id: "c3m1_plankcountry", campaign: "Swamp Fever", name: "Plank Country" },
  { id: "c4m1_milltown_a", campaign: "Hard Rain", name: "Milltown" },
  { id: "c5m1_waterfront", campaign: "The Parish", name: "Waterfront" },
  { id: "c6m1_riverbank", campaign: "The Passing", name: "Riverbank" },
  { id: "c7m1_docks", campaign: "The Sacrifice", name: "Docks" },
  { id: "c8m1_apartment", campaign: "No Mercy", name: "Apartments" },
  { id: "c9m1_alleys", campaign: "Crash Course", name: "Alleys" },
  { id: "c10m1_caves", campaign: "Death Toll", name: "Caves" },
  { id: "c11m1_greenhouse", campaign: "Dead Air", name: "Greenhouse" },
  { id: "c12m1_hilltop", campaign: "Blood Harvest", name: "Hilltop" },
  { id: "c13m1_alpinecreek", campaign: "Cold Stream", name: "Alpine Creek" },
  { id: "c14m1_junkyard", campaign: "The Last Stand", name: "Junkyard" },
] as const;

export const REGIONS = [
  { id: 255, label: "Mundial (recomendado)" },
  { id: 0, label: "US Este" },
  { id: 1, label: "US Oeste" },
  { id: 2, label: "Sudamérica" },
  { id: 3, label: "Europa" },
  { id: 4, label: "Asia" },
  { id: 5, label: "Australia" },
  { id: 6, label: "Oriente Medio" },
  { id: 7, label: "África" },
] as const;

export const GAMEMODES = [
  {
    id: "coop",
    label: "Campaña",
    hint: "La opción más estable para 5–12 supervivientes.",
  },
  {
    id: "realism",
    label: "Realismo",
    hint: "Misma campaña, sin siluetas ni reapariciones fáciles.",
  },
  {
    id: "versus",
    label: "Versus",
    hint: "Necesita SuperVersus además de ABM si pasas de 4v4.",
  },
  {
    id: "survival",
    label: "Supervivencia",
    hint: "ABM escala hordas; 8 jugadores aguantan más de lo que el director espera.",
  },
] as const;

export type GameMode = (typeof GAMEMODES)[number]["id"];

export type ServerSettings = {
  hostname: string;
  maxPlayers: number;
  gamemode: GameMode;
  startMap: string;
  region: number;
  port: number;
  rconPassword: string;
  svPassword: string;
  steamGroup: string;
  publicServer: boolean;
};

export const DEFAULT_SETTINGS: ServerSettings = {
  hostname: "Los 8 de Mercy",
  maxPlayers: 8,
  gamemode: "coop",
  startMap: "c8m1_apartment",
  region: 255,
  port: 27016,
  rconPassword: "",
  svPassword: "",
  steamGroup: "",
  publicServer: false,
};

export function clampPlayers(n: number): number {
  return Math.min(18, Math.max(5, Math.round(n)));
}

export function recommendedRam(maxPlayers: number): string {
  if (maxPlayers <= 8) return "2–4 GB";
  if (maxPlayers <= 12) return "4 GB";
  return "4–8 GB";
}

export function lobbyNote(maxPlayers: number, gamemode: GameMode): string {
  if (gamemode === "versus") {
    return maxPlayers <= 8
      ? "El lobby de Versus admite 8. Si subes de 8, el resto entra con connect."
      : "El lobby de Valve se llena en 8. Del noveno en adelante: connect IP:puerto.";
  }
  if (maxPlayers <= 8) {
    return "Campaña oficial solo lista 4 en el lobby. Con la mutación 8 Player Lobby y mm_dedicated_force_servers puedes meter hasta 8. El resto, connect.";
  }
  return "A partir de 9 jugadores nadie más entra por lobby. Pásales connect IP:puerto.";
}

export function generateEnv(s: ServerSettings): string {
  return `# Copia este archivo a .env en la raíz del repo
SRCDS_HOSTNAME=${quote(s.hostname)}
SRCDS_MAXPLAYERS=${s.maxPlayers}
SRCDS_STARTMAP=${s.startMap}
SRCDS_GAMEMODE=${s.gamemode}
SRCDS_PORT=27015
SRCDS_HOST_PORT=${s.port}
SRCDS_REGION=${s.region}
SRCDS_RCONPW=${quote(s.rconPassword || "cambia-esto")}
SRCDS_PW=${quote(s.svPassword)}
SRCDS_STEAMGROUP=${s.steamGroup}
SRCDS_LAN=${s.publicServer ? "0" : "0"}
# Mapas Workshop (colección del gist). Vacío = no baja mapas.
WORKSHOP_IDS=2233971331
FORCE_WORKSHOP_UPDATE=0
`;
}

export function generateServerCfg(s: ServerSettings): string {
  const visible = s.maxPlayers;
  const passwordLine = s.svPassword
    ? `sv_password "${escapeCfg(s.svPassword)}"`
    : `sv_password ""`;
  const steamGroup = s.steamGroup.trim()
    ? `sv_steamgroup "${escapeCfg(s.steamGroup.trim())}"`
    : `sv_steamgroup "0"`;

  return `// Generado por el kit L4D2 8+ — no subas este archivo con contraseñas reales
hostname "${escapeCfg(s.hostname)}"
rcon_password "${escapeCfg(s.rconPassword || "cambia-esto")}"
${passwordLine}

sv_maxplayers ${s.maxPlayers}
sv_visiblemaxplayers ${visible}
sv_removehumanlimit 1
sv_force_unreserved 1
sv_allow_lobby_connect_only 0

mp_gamemode "${s.gamemode}"
sv_gametypes "coop,realism,versus,survival,scavenge"
sv_consistency 0
sv_lan 0
sv_region ${s.region}
sv_voiceenable 1
sv_alltalk 0
sv_allow_wait_command 0
sv_steamgroup_exclusive 0
${steamGroup}

sv_minrate 20000
sv_maxrate 30000
sv_minupdaterate 20
sv_maxupdaterate 30
sv_mincmdrate 20
sv_maxcmdrate 30

motd_enabled 1
sv_hibernate_when_empty 0

sm_cvar survivor_limit ${Math.min(s.maxPlayers, 24)}
sm_cvar z_max_player_zombies ${s.gamemode === "versus" ? Math.min(s.maxPlayers, 18) : 4}
sm_cvar l4d_perkmod_forcerandomperks 1

exec banned_user.cfg
exec banned_ip.cfg
writeid
writeip
`;
}

export function generateAbmCfg(s: ServerSettings): string {
  const extra = Math.max(0, s.maxPlayers - 4);
  return `// cfg/sourcemod/abm.cfg — se crea al cargar ABM; deja estos valores
abm_minplayers "${s.maxPlayers}"
abm_maxplayers "${s.maxPlayers}"
abm_autohard "${extra >= 4 ? 1 : 0}"
abm_identityfix "1"
abm_joinmenu "0"
abm_offertakeover "1"
abm_lockslots "0"
`;
}

export function generateConnectSnippet(
  ip: string,
  port: number,
): { connect: string; force: string } {
  const host = ip.trim() || "TU.IP.PUBLICA";
  return {
    connect: `connect ${host}:${port}`,
    force: `mm_dedicated_force_servers ${host}:${port}`,
  };
}

export function generateComposeSnippet(s: ServerSettings): string {
  return `services:
  l4d2:
    build: ./server
    container_name: l4d2-8plus
    restart: unless-stopped
    stdin_open: true
    tty: true
    ports:
      - "${s.port}:27015/udp"
      - "${s.port}:27015/tcp"
    environment:
      SRCDS_HOSTNAME: ${quote(s.hostname)}
      SRCDS_MAXPLAYERS: "${s.maxPlayers}"
      SRCDS_STARTMAP: ${s.startMap}
      SRCDS_GAMEMODE: ${s.gamemode}
      SRCDS_REGION: "${s.region}"
      SRCDS_RCONPW: ${quote(s.rconPassword || "cambia-esto")}
      SRCDS_PW: ${quote(s.svPassword)}
      SRCDS_STEAMGROUP: "${s.steamGroup}"
      WORKSHOP_IDS: "2233971331"
    volumes:
      - l4d2-game:/home/steam/l4d2
      - ./server/addons-drop:/home/steam/addons-drop:ro

volumes:
  l4d2-game:
`;
}

function escapeCfg(value: string): string {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function quote(value: string): string {
  if (value === "") return '""';
  if (/[\s#"']/.test(value)) return `"${value.replace(/"/g, '\\"')}"`;
  return value;
}
