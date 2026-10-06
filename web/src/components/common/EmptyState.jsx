import { Inbox } from "lucide-react";
export default function EmptyState({ title = "No records found", description = "There is nothing to show here yet." }) {
  return <div className="crm-empty-state flex min-h-44 flex-col items-center justify-center rounded-[16px] border border-dashed border-white/[.09] bg-white/[.018] p-8 text-center"><div className="grid h-11 w-11 place-items-center rounded-xl border border-white/[.07] bg-white/[.035] text-slate-500"><Inbox size={19}/></div><p className="mt-3 text-[12px] font-bold text-slate-300">{title}</p><p className="mt-1 max-w-md text-[10px] leading-5 text-slate-600">{description}</p></div>;
}
