import { LoaderCircle } from "lucide-react";
export default function LoadingState({ label = "Loading…" }) {
  return <div className="flex min-h-48 items-center justify-center"><div className="crm-loading-card flex items-center gap-3 rounded-xl border border-white/[.07] bg-white/[.022] px-4 py-3 text-[10px] font-semibold text-slate-500"><LoaderCircle className="animate-spin text-brand-400" size={17}/>{label}<span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-400" /></div></div>;
}
