import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { CodeBlock } from "@/components/code-block";

export default function ProblemasPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 py-10">
      <p className="mb-2 text-xs font-medium tracking-[0.22em] text-primary uppercase">
        Diagnóstico
      </p>
      <h1 className="text-4xl tracking-wide uppercase sm:text-5xl">
        Si no entra el 5º
      </h1>
      <p className="mt-3 text-muted-foreground">
        Casi siempre es L4DToolZ que no cargó, binario de otro SO, o el puerto
        UDP cerrado. La consola del dedicated miente menos que el cliente.
      </p>

      <Accordion className="mt-8 rounded-xl border border-border bg-card px-4">
        <AccordionItem value="full">
          <AccordionTrigger>
            «Session is full» / Valve_Reject_Server_Full
          </AccordionTrigger>
          <AccordionContent>
            <p>
              El motor sigue en 4. En la consola del servidor:
            </p>
            <CodeBlock code={"meta list\nsm plugins list\nstatus"} />
            <p>
              L4DToolZ tiene que salir Running. Si no está, el tar no se
              extrajo en <code>left4dead2/addons</code> o metiste el .dll en
              Linux. Confirma{" "}
              <code>-maxplayers 8</code> en el comando, no{" "}
              <code>+maxplayers</code>.
            </p>
          </AccordionContent>
        </AccordionItem>
        <AccordionItem value="spec">
          <AccordionTrigger>
            Entra y se queda espectador
          </AccordionTrigger>
          <AccordionContent>
            <p>
              L4DToolZ abrió el hueco; nadie creó el quinto superviviente. Falta
              ABM (o SuperVersus). El .smx va en{" "}
              <code>addons/sourcemod/plugins</code> y el gamedata{" "}
              <code>abm.txt</code> en{" "}
              <code>addons/sourcemod/gamedata</code>. Reinicia, no basta un
              sm plugins reload la primera vez.
            </p>
          </AccordionContent>
        </AccordionItem>
        <AccordionItem value="timeout">
          <AccordionTrigger>Timeout / no aparece en Steam</AccordionTrigger>
          <AccordionContent>
            <p>
              Prueba primero en LAN con la IP local. Si LAN funciona y WAN no,
              el router no reenvía UDP 27015. En VPS abre el security group.
              Docker tiene que publicar UDP y TCP; solo TCP no sirve.
            </p>
          </AccordionContent>
        </AccordionItem>
        <AccordionItem value="crash">
          <AccordionTrigger>Crash al 5º o en The Passing</AccordionTrigger>
          <AccordionContent>
            <p>
              Modelos L4D1 (Bill, Francis, Louis, Zoey) en The Passing siguen
              rotos. ABM + identity fix ayudan y no curan del todo. Evita
              Passing con 8+ o usa un identity fix actualizado. Si pega SIGALRM
              en Docker, el entrypoint ya pasa <code>-nowatchdog</code>.
            </p>
          </AccordionContent>
        </AccordionItem>
        <AccordionItem value="insecure">
          <AccordionTrigger>VAC / insecure al usar listen</AccordionTrigger>
          <AccordionContent>
            <p>
              SourceMod en el cliente exige <code>-insecure</code> y te saca de
              oficiales. Por eso el dedicated: los jugadores entran VAC-safe al
              tuyo. No mezcles este server con matchmaking oficial.
            </p>
          </AccordionContent>
        </AccordionItem>
        <AccordionItem value="items">
          <AccordionTrigger>Solo 4 kits / 4 pistolas</AccordionTrigger>
          <AccordionContent>
            <p>
              El mapa spawnea loot para cuatro. ABM puede dar arma primaria al
              extra; para kits y ammo packs extra conviene{" "}
              <code>l4d2_extraplayeritems</code> de Jackz más Left 4 DHooks.
              No es obligatorio para que entren: es para que no se peleen el
              único defibrilador.
            </p>
          </AccordionContent>
        </AccordionItem>
      </Accordion>

      <div className="mt-8 text-sm text-muted-foreground">
        <p className="mb-2 font-medium text-foreground">Comprobación rápida</p>
        <CodeBlock
          filename="dentro del contenedor"
          code={`meta version
meta list
sm version
status`}
        />
      </div>
    </div>
  );
}
