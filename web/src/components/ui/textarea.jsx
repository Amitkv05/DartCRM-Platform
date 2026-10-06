import { cn } from "@/lib/utils";
export function Textarea({ className, ...props }) {
  return <textarea className={cn("crm-input min-h-24 w-full rounded-[10px] border border-white/[.08] bg-white/[.028] px-3 py-2.5 text-sm text-slate-200 outline-none transition-all placeholder:text-slate-600 focus:border-cyan-400/30 focus:ring-4 focus:ring-cyan-400/[.045] disabled:cursor-not-allowed disabled:opacity-60", className)} {...props} />;
}
