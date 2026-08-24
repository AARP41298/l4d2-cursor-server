import Link from "next/link";

export function SiteFooter() {
  return (
    <footer className="mt-auto border-t border-border/80">
      <div className="mx-auto flex max-w-6xl flex-col gap-2 px-4 py-6 text-sm text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
        <p>
          Kit para Left 4 Dead 2. No está afiliado a Valve. Respeta las
          licencias de Steam, SourceMod y cada plugin.
        </p>
        <Link href="/asistente" className="text-primary hover:underline">
          Generar configs
        </Link>
      </div>
    </footer>
  );
}
