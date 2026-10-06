import { cn } from "@/lib/utils";
const tones = {
  slate: "border-white/[.08] bg-white/[.05] text-slate-400",
  blue: "border-cyan-400/15 bg-cyan-400/[.08] text-cyan-300",
  green: "border-emerald-400/15 bg-emerald-400/[.09] text-emerald-300",
  amber: "border-amber-400/15 bg-amber-400/[.09] text-amber-300",
  red: "border-red-400/15 bg-red-400/[.09] text-red-300",
  purple: "border-violet-400/15 bg-violet-400/[.09] text-violet-300",
};
export function Badge({ tone = "slate", className, ...props }) {
  return <span className={cn("inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-[10px] font-semibold tracking-wide", tones[tone] || tones.slate, className)} {...props} />;
}
