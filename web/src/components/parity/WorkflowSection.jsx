import { cn } from "@/lib/utils";

export function WorkflowSection({ title, actions, children, className = "", contentClassName = "" }) {
  return (
    <section className={cn("overflow-hidden rounded-xl border border-amber-300 bg-white shadow-sm dark:border-amber-900/60 dark:bg-slate-900", className)}>
      <div className="flex min-h-11 items-center justify-between gap-3 bg-amber-400 px-4 py-2.5 text-slate-950 dark:bg-amber-500">
        <h2 className="text-sm font-bold sm:text-base">{title}</h2>
        {actions ? <div className="flex items-center gap-2">{actions}</div> : null}
      </div>
      <div className={cn("p-4 sm:p-5", contentClassName)}>{children}</div>
    </section>
  );
}

export function InfoLine({ label, value, className = "" }) {
  return (
    <div className={cn("grid gap-1 text-sm sm:grid-cols-[150px_1fr]", className)}>
      <span className="font-semibold text-slate-700 dark:text-slate-300">{label}</span>
      <span className="text-slate-600 dark:text-slate-400">{value || "—"}</span>
    </div>
  );
}

export function EmptyMessage({ children = "No data available" }) {
  return <div className="rounded-lg border border-dashed border-slate-300 px-4 py-8 text-center text-sm text-slate-500 dark:border-slate-700">{children}</div>;
}
