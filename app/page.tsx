import Link from "next/link";
import {
  ArrowRight,
  House,
  Monitor,
  Server,
  TriangleAlert,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { StackDiagram } from "@/components/stack-diagram";
import { CodeBlock } from "@/components/code-block";

export default function HomePage() {
  return (
    <div>
      <section className="mx-auto max-w-6xl px-4 py-10 md:py-16">
        <p className="mb-3 text-xs font-medium tracking-[0.22em] text-primary uppercase">
          Manual de campaña · 2026
        </p>
        <h1 className="max-w-3xl text-4xl leading-[0.95] tracking-wide uppercase sm:text-6xl">
          Más de 4 en L4D2 no se parchea en el lobby. Se hostea.
        </h1>
        <p className="mt-5 max-w-2xl text-base leading-relaxed text-muted-foreground sm:text-lg">
          Valve dejó campaña en 4 y Versus en 8. La forma que aguanta una
          noche entera con 8, 10 o 12 es un{" "}
          <strong className="font-medium text-foreground">
            servidor dedicado Linux
          </strong>
          , no “Local server” desde el menú. Encima van L4DToolZ (abre el
          cupo) y ABM (spawnea supervivientes de más).
        </p>
        <div className="mt-6 flex flex-wrap gap-2">
          <Button nativeButton={false} render={<Link href="/asistente" />}>
            Armar configs
            <ArrowRight data-icon="inline-end" />
          </Button>
          <Button
            nativeButton={false}
            variant="outline"
            render={<Link href="/conectar" />}
          >
            Cómo hace join el 5º
          </Button>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-4 pb-12">
        <h2 className="mb-4 text-2xl tracking-wide uppercase">
          Tres formas. Una es la buena.
        </h2>
        <div className="grid gap-3 md:grid-cols-3">
          <Card className="opacity-80">
            <CardHeader>
              <Monitor className="size-4 text-muted-foreground" />
              <CardTitle>Listen / Local server</CardTitle>
              <CardDescription>Una noche, y ya.</CardDescription>
            </CardHeader>
            <CardContent className="text-sm leading-relaxed text-muted-foreground">
              Metes SourceMod en el cliente con{" "}
              <code className="text-foreground">-insecure</code>. El host no
              puede alt-tab en paz, si se cae se acaba la run, y SourceMod
              avisa que no soporta listen. Sirve para probar plugins, no para
              8 amigos cada viernes.
            </CardContent>
          </Card>
          <Card className="ring-primary/40">
            <CardHeader>
              <div className="flex items-center justify-between gap-2">
                <Server className="size-4 text-primary" />
                <Badge>Recomendado</Badge>
              </div>
              <CardTitle>Dedicated Linux + Docker</CardTitle>
              <CardDescription>Este repo.</CardDescription>
            </CardHeader>
            <CardContent className="text-sm leading-relaxed text-muted-foreground">
              SteamCMD instala el dedicated (gratis). Docker lo deja
              reproducible. Plugins en un volumen. El que hostea puede jugar
              desde otro PC. 2 vCPU y 4 GB bastan para 8 en campaña.
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <House className="size-4 text-muted-foreground" />
              <CardTitle>Hosting de juegos</CardTitle>
              <CardDescription>Si no quieres SSH.</CardDescription>
            </CardHeader>
            <CardContent className="text-sm leading-relaxed text-muted-foreground">
              Pides un slot de L4D2 con SourceMod, subes L4DToolZ y ABM, y
              pones <code className="text-foreground">-maxplayers 8</code> en
              el comando de arranque. Más caro, mismo stack. No hace magia:
              sin L4DToolZ el 5º sigue fuera.
            </CardContent>
          </Card>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-4 pb-12">
        <h2 className="mb-2 text-2xl tracking-wide uppercase">
          El stack que realmente desbloquea el 5º
        </h2>
        <p className="mb-5 max-w-2xl text-sm leading-relaxed text-muted-foreground">
          Subir <code>sv_maxplayers</code> no alcanza: el binario rechaza la
          quinta conexión. Hace falta un unlocker de motor y un plugin que
          cree personajes. SuperVersus sirve; ABM se porta mejor en campaña
          8+.
        </p>
        <StackDiagram />
      </section>

      <section className="mx-auto grid max-w-6xl gap-4 px-4 pb-16 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Qué corre este kit</CardTitle>
            <CardDescription>
              <code>docker compose up</code> descarga ~10 GB la primera vez.
            </CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3 text-sm leading-relaxed text-muted-foreground">
            <p>
              SteamCMD anónimo, MetaMod 1.12, SourceMod 1.12 y L4DToolZ 2.2.0
              (fork de accelerator74; el zip viejo de AlliedModders ya no
              carga). ABM lo dejas tú en{" "}
              <code className="text-foreground">server/addons-drop</code>{" "}
              porque AlliedModders bloquea descargas automáticas.
            </p>
            <CodeBlock
              filename="en la raíz del repo"
              code={`cp .env.example .env
# edita hostname, RCON y jugadores
docker compose up --build`}
            />
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <TriangleAlert className="size-4 text-destructive" />
              <CardTitle>Lo que la gente pifia</CardTitle>
            </div>
          </CardHeader>
          <CardContent className="text-sm leading-relaxed text-muted-foreground">
            <ul className="grid gap-2">
              <li>
                Usar <code className="text-foreground">+maxplayers</code>.
                L4DToolZ 2.2 solo lee <code className="text-foreground">-maxplayers</code>.
              </li>
              <li>
                Instalar L4DToolZ en{" "}
                <code className="text-foreground">sourcemod/extensions</code>.
                Es un plugin de MetaMod: va en{" "}
                <code className="text-foreground">addons/l4dtoolz</code> +{" "}
                <code className="text-foreground">addons/metamod/l4dtoolz.vdf</code>.
              </li>
              <li>
                Mezclar binarios Windows (.dll) en un VPS Linux (.so).
              </li>
              <li>
                Olvidar UDP 27015 en el router. TCP solo no alcanza.
              </li>
            </ul>
          </CardContent>
        </Card>
      </section>
    </div>
  );
}
