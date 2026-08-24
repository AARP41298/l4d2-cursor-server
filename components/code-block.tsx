"use client";

import { CopyButton } from "@/components/copy-button";

export function CodeBlock({
  code,
  filename,
}: {
  code: string;
  filename?: string;
}) {
  return (
    <div className="overflow-hidden rounded-lg border border-border bg-black/40">
      <div className="flex items-center justify-between gap-2 border-b border-border px-3 py-1.5">
        <span className="font-mono text-[11px] tracking-wide text-muted-foreground uppercase">
          {filename ?? "consola"}
        </span>
        <CopyButton text={code} />
      </div>
      <pre className="overflow-x-auto p-3 font-mono text-[12px] leading-relaxed text-primary/90 md:text-[13px]">
        <code>{code}</code>
      </pre>
    </div>
  );
}
