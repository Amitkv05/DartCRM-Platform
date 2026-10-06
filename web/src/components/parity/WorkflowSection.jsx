import { cn } from "@/lib/utils";

export function WorkflowSection({ title, actions, children, className = "", contentClassName = "" }) {
  return (
    <section className={cn("crm-workflow overflow-hidden rounded-[16px] border border-white/[.085] bg-white/[.018] shadow-glass backdrop-blur-xl", className)}>
      <div className="crm-workflow-head flex min-h-12 items-center justify-between gap-3 border-b border-white/[.06] px-4 py-2.5 sm:px-5">
        <div className="flex items-center gap-2.5"><span className="h-1.5 w-1.5 rounded-full bg-brand-500 shadow-[0_0_10px_rgba(255,91,80,.65)]"/><h2 className="text-[11px] font-bold tracking-[.02em] text-slate-200 sm:text-[12px]">{title}</h2></div>
        {actions ? <div className="flex items-center gap-2">{actions}</div> : null}
      </div>
      <div className={cn("p-4 sm:p-5", contentClassName)}>{children}</div>
    </section>
  );
}

export function InfoLine({ label, value, className = "" }) {
  return (
    <div className={cn("grid gap-1.5 text-[11px] sm:grid-cols-[150px_1fr]", className)}>
      <span className="font-semibold text-slate-500">{label}</span>
      <span className="text-slate-300">{value || "—"}</span>
    </div>
  );
}

export function EmptyMessage({ children = "No data available" }) {
  return <div className="rounded-xl border border-dashed border-white/[.08] bg-white/[.012] px-4 py-8 text-center text-[10px] text-slate-600">{children}</div>;
}
