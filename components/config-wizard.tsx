"use client";

import { useMemo, useState } from "react";
import { Download } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { CodeBlock } from "@/components/code-block";
import { downloadText } from "@/lib/downloads";
import {
  DEFAULT_SETTINGS,
  GAMEMODES,
  MAPS,
  REGIONS,
  clampPlayers,
  generateAbmCfg,
  generateComposeSnippet,
  generateConnectSnippet,
  generateEnv,
  generateServerCfg,
  lobbyNote,
  recommendedRam,
  type ServerSettings,
} from "@/lib/config";

export function ConfigWizard() {
  const [settings, setSettings] = useState<ServerSettings>(DEFAULT_SETTINGS);
  const [publicIp, setPublicIp] = useState("");

  function patch(partial: Partial<ServerSettings>) {
    setSettings((current) => ({ ...current, ...partial }));
  }

  const envFile = useMemo(() => generateEnv(settings), [settings]);
  const serverCfg = useMemo(() => generateServerCfg(settings), [settings]);
  const abmCfg = useMemo(() => generateAbmCfg(settings), [settings]);
  const compose = useMemo(
    () => generateComposeSnippet(settings),
    [settings],
  );
  const connect = useMemo(
    () => generateConnectSnippet(publicIp, settings.port),
    [publicIp, settings.port],
  );
  const mapLabel = MAPS.find((map) => map.id === settings.startMap);

  const missingRcon = settings.rconPassword.trim().length < 8;

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
      <Card>
        <CardHeader>
          <CardTitle>Parámetros del servidor</CardTitle>
          <CardDescription>
            8 jugadores es el punto dulce: lobby usable con un addon y el
            director todavía se siente a L4D2. A partir de 12 el caos gana.
          </CardDescription>
        </CardHeader>
        <CardContent className="grid gap-5">
          <div className="grid gap-2">
            <Label htmlFor="hostname">Nombre en el navegador</Label>
            <Input
              id="hostname"
              value={settings.hostname}
              maxLength={63}
              onChange={(event) => patch({ hostname: event.target.value })}
              placeholder="Los 8 de Mercy"
            />
          </div>

          <div className="grid gap-2">
            <div className="flex items-center justify-between gap-3">
              <Label>Jugadores humanos</Label>
              <Badge variant="outline">{settings.maxPlayers}</Badge>
            </div>
            <Slider
              min={5}
              max={18}
              step={1}
              value={[settings.maxPlayers]}
              onValueChange={(value) => {
                const next = Array.isArray(value) ? value[0] : value;
                patch({ maxPlayers: clampPlayers(Number(next) || 8) });
              }}
            />
            <p className="text-xs text-muted-foreground">
              RAM recomendada: {recommendedRam(settings.maxPlayers)}. El motor
              admite hasta 18 con L4DToolZ 2.2; más de 14 suele ir mal en
              mapas estrechos.
            </p>
          </div>

          <div className="grid gap-2">
            <Label>Modo</Label>
            <Select
              value={settings.gamemode}
              onValueChange={(value) =>
                patch({ gamemode: value as ServerSettings["gamemode"] })
              }
            >
              <SelectTrigger className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {GAMEMODES.map((mode) => (
                  <SelectItem key={mode.id} value={mode.id}>
                    {mode.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <p className="text-xs text-muted-foreground">
              {GAMEMODES.find((mode) => mode.id === settings.gamemode)?.hint}
            </p>
          </div>

          <div className="grid gap-2">
            <Label>Mapa inicial</Label>
            <Select
              value={settings.startMap}
              onValueChange={(value) => patch({ startMap: String(value) })}
            >
              <SelectTrigger className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {MAPS.map((map) => (
                  <SelectItem key={map.id} value={map.id}>
                    {map.campaign} — {map.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-2">
              <Label>Región Steam</Label>
              <Select
                value={String(settings.region)}
                onValueChange={(value) =>
                  patch({ region: Number(value) })
                }
              >
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {REGIONS.map((region) => (
                    <SelectItem key={region.id} value={String(region.id)}>
                      {region.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="port">Puerto UDP</Label>
              <Input
                id="port"
                type="number"
                min={1024}
                max={65535}
                value={settings.port}
                onChange={(event) =>
                  patch({
                    port: Math.min(
                      65535,
                      Math.max(1024, Number(event.target.value) || 27015),
                    ),
                  })
                }
              />
            </div>
          </div>

          <div className="grid gap-2">
            <Label htmlFor="rcon">Contraseña RCON (mín. 8)</Label>
            <Input
              id="rcon"
              type="password"
              autoComplete="new-password"
              value={settings.rconPassword}
              onChange={(event) =>
                patch({ rconPassword: event.target.value })
              }
              placeholder="no uses la de Steam"
              aria-invalid={missingRcon}
            />
            {missingRcon ? (
              <p className="text-xs text-destructive">
                Sin RCON fuerte cualquiera en tu red puede mandar changelevel.
              </p>
            ) : null}
          </div>

          <div className="grid gap-2">
            <Label htmlFor="svpw">Contraseña de entrada (opcional)</Label>
            <Input
              id="svpw"
              type="text"
              value={settings.svPassword}
              onChange={(event) => patch({ svPassword: event.target.value })}
              placeholder="vacío = cualquiera con la IP entra"
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="group">Steam Group ID (opcional)</Label>
            <Input
              id="group"
              inputMode="numeric"
              value={settings.steamGroup}
              onChange={(event) => patch({ steamGroup: event.target.value })}
              placeholder="aparece en el menú de quien esté en el grupo"
            />
          </div>

          <div className="flex items-center justify-between gap-3 rounded-lg border border-border px-3 py-2">
            <div>
              <Label htmlFor="public">Listar en el navegador público</Label>
              <p className="text-xs text-muted-foreground">
                Mejor un grupo Steam o IP directa. El internet público de L4D2
                está lleno de servidores basura.
              </p>
            </div>
            <Switch
              id="public"
              checked={settings.publicServer}
              onCheckedChange={(checked) =>
                patch({ publicServer: Boolean(checked) })
              }
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="ip">Tu IP pública (solo para el comando)</Label>
            <Input
              id="ip"
              value={publicIp}
              onChange={(event) => setPublicIp(event.target.value)}
              placeholder="203.0.113.10"
            />
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-4">
        <div className="rounded-xl border border-primary/30 bg-primary/8 p-4 text-sm leading-relaxed">
          {lobbyNote(settings.maxPlayers, settings.gamemode)} Mapa de arranque:{" "}
          <span className="font-medium text-foreground">
            {mapLabel
              ? `${mapLabel.campaign} (${mapLabel.name})`
              : settings.startMap}
          </span>
          .
        </div>

        <div className="flex flex-wrap gap-2">
          <Button
            type="button"
            onClick={() => downloadText("server.cfg", serverCfg)}
          >
            <Download data-icon="inline-start" />
            server.cfg
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={() => downloadText(".env", envFile)}
          >
            .env
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={() => downloadText("abm.cfg", abmCfg)}
          >
            abm.cfg
          </Button>
        </div>

        <CodeBlock filename="comando para amigos" code={connect.connect} />
        <CodeBlock
          filename="forzar dedicated desde el lobby"
          code={connect.force}
        />
        <CodeBlock filename=".env" code={envFile} />
        <CodeBlock filename="server.cfg" code={serverCfg} />
        <CodeBlock filename="docker-compose (referencia)" code={compose} />
      </div>
    </div>
  );
}
