import { ConfigWizard } from "@/components/config-wizard";

export default function AsistentePage() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-10">
      <p className="mb-2 text-xs font-medium tracking-[0.22em] text-primary uppercase">
        Paso 2 · configs
      </p>
      <h1 className="text-4xl tracking-wide uppercase sm:text-5xl">
        Asistente de servidor
      </h1>
      <p className="mt-3 max-w-2xl text-muted-foreground">
        Genera el <code className="text-foreground">.env</code>, el{" "}
        <code className="text-foreground">server.cfg</code> y los comandos de
        conexión. El Compose del repo ya lee esas variables: no hace falta
        reescribir el YAML a mano.
      </p>
      <div className="mt-8">
        <ConfigWizard />
      </div>
    </div>
  );
}
