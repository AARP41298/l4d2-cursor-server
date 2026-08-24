import { Layers, Puzzle, Server, Unlock } from "lucide-react";

const LAYERS = [
  {
    icon: Server,
    title: "srcds Linux",
    body: "Left 4 Dead 2 Dedicated Server (app 222860) vía SteamCMD. El cliente no hostea. El servidor sigue vivo si alguien se cae.",
  },
  {
    icon: Puzzle,
    title: "MetaMod + SourceMod",
    body: "Cargan plugins en el motor. En un listen server (Local) SourceMod no está soportado de forma estable.",
  },
  {
    icon: Unlock,
    title: "L4DToolZ",
    body: "Quiebra el tope duro de jugadores. Sin esto el 5º recibe Session is full aunque hayas tocado sv_maxplayers.",
  },
  {
    icon: Layers,
    title: "ABM (o SuperVersus)",
    body: "Spawnea supervivientes extra, les asigna modelo y escala infectados. Si no está, los huecos extra entran como espectadores.",
  },
];

export function StackDiagram() {
  return (
    <ol className="grid gap-3 md:grid-cols-2">
      {LAYERS.map((layer, index) => (
        <li
          key={layer.title}
          className="flex gap-3 rounded-xl border border-border bg-card/70 p-4"
        >
          <span className="font-heading flex size-9 shrink-0 items-center justify-center rounded-md bg-primary/15 text-sm text-primary">
            {index + 1}
          </span>
          <div className="min-w-0">
            <div className="mb-1 flex items-center gap-2">
              <layer.icon className="size-4 text-primary" />
              <h3 className="font-heading text-base tracking-wide uppercase">
                {layer.title}
              </h3>
            </div>
            <p className="text-sm leading-relaxed text-muted-foreground">
              {layer.body}
            </p>
          </div>
        </li>
      ))}
    </ol>
  );
}
