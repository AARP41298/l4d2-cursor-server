import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { CodeBlock } from "@/components/code-block";

export default function ConectarPage() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-10">
      <p className="mb-2 text-xs font-medium tracking-[0.22em] text-primary uppercase">
        Lobby vs consola
      </p>
      <h1 className="text-4xl tracking-wide uppercase sm:text-5xl">
        Cómo entra gente de más
      </h1>
      <p className="mt-3 max-w-2xl text-muted-foreground">
        El matchmaking de Valve no conoce tu dedicated de 8. O engañas al
        lobby, o mandas un <code className="text-foreground">connect</code>.
        Las dos conviven.
      </p>

      <div className="mt-8 grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <Badge variant="outline">Hasta 8</Badge>
            <CardTitle>Lobby con mutación</CardTitle>
            <CardDescription>
              El host necesita el addon de Workshop «8 Player Lobby». El resto
              no.
            </CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3 text-sm leading-relaxed text-muted-foreground">
            <ol className="grid list-decimal gap-2 pl-4">
              <li>Mutations → 8 Player Lobby.</li>
              <li>Crear lobby y en settings poner Campaign (o Versus).</li>
              <li>
                Servidor: Best Available Dedicated. Nunca Official ni Local.
              </li>
              <li>En consola, antes de listo:</li>
            </ol>
            <CodeBlock
              filename="consola del host"
              code="mm_dedicated_force_servers TU.IP.PUBLICA:27016"
            />
            <p>
              Si el lobby se va a un oficial, no pegaste el force o el
              dedicated no está listo en Steam.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <Badge>El que siempre funciona</Badge>
            <CardTitle>connect directo</CardTitle>
            <CardDescription>
              Obligatorio desde el 9º. Útil también si el lobby se niega.
            </CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3 text-sm leading-relaxed text-muted-foreground">
            <p>
              Activa la consola en Opciones → Teclado. Elige la IP según
              dónde esté el juego:
            </p>
            <CodeBlock
              filename="misma PC que Docker"
              code="connect 127.0.0.1:27016"
            />
            <CodeBlock
              filename="otra PC en tu LAN"
              code="connect 192.168.68.106:27016"
            />
            <CodeBlock
              filename="amigos por Internet"
              code="connect TU.IP.PUBLICA:27016"
            />
            <p>
              No uses la IP <code className="text-foreground">172.x</code> del
              contenedor ni la pública desde la misma casa (el router no
              suele devolver el NAT). Si hay{" "}
              <code className="text-foreground">sv_password</code>, primero{" "}
              <code className="text-foreground">password la-contraseña</code>{" "}
              y luego connect. En el router, UDP y TCP 27016 hacia la máquina
              Docker. En la misma PC que el juego no uses 27015: el cliente
              ya lo tiene ocupado.
            </p>
          </CardContent>
        </Card>
      </div>

      <Card className="mt-4">
        <CardHeader>
          <CardTitle>Grupo Steam</CardTitle>
          <CardDescription>
            El servidor aparece abajo a la derecha en el menú de quien esté en
            el grupo.
          </CardDescription>
        </CardHeader>
        <CardContent className="text-sm leading-relaxed text-muted-foreground">
          Crea el grupo, copia el ID numérico (no el nombre) y pégalo en el
          asistente. Cualquiera que sepa el ID puede colgarse del mismo grupo:
          no lo publiques en un anuncio abierto si quieres partidas privadas.
        </CardContent>
      </Card>

      <Card className="mt-4">
        <CardHeader>
          <CardTitle>Addons del cliente</CardTitle>
        </CardHeader>
        <CardContent className="text-sm leading-relaxed text-muted-foreground">
          Si mezclas VPKs distintos, el 5º se queda en «failed to sync». Deja
          el dedicated con <code className="text-foreground">sv_consistency 0</code>{" "}
          (ya va en el cfg) y pide a la sala que desactive cosméticos
          conflictivos. Los plugins de SourceMod viven solo en el servidor: el
          cliente no los instala.
        </CardContent>
      </Card>
    </div>
  );
}
