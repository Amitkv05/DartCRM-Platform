import { cn } from "@/lib/utils";
export function Input({ className, ...props }) {
  return <input className={cn("crm-input h-10 w-full rounded-[10px] border border-white/[.08] bg-white/[.028] px-3 text-sm text-slate-200 outline-none transition-all placeholder:text-slate-600 focus:border-cyan-400/30 focus:bg-white/[.04] focus:ring-4 focus:ring-cyan-400/[.045] disabled:cursor-not-allowed disabled:opacity-60", className)} {...props} />;
}
