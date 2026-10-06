import { cn } from "@/lib/utils";
export function Select({ className, children, ...props }) {
  return <select className={cn("crm-input h-10 w-full rounded-[10px] border border-white/[.08] bg-[#111519] px-3 text-sm text-slate-200 outline-none transition-all focus:border-cyan-400/30 focus:ring-4 focus:ring-cyan-400/[.045] disabled:cursor-not-allowed disabled:opacity-60", className)} {...props}>{children}</select>;
}
