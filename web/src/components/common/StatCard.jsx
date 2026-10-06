import { ArrowUpRight } from "lucide-react";
import { Card } from "@/components/ui/card";

export default function StatCard({ icon: Icon, label, value, helper, tone = "text-cyan-300" }) {
  return (
    <Card className="crm-stat-card relative min-h-[118px] overflow-hidden p-4 sm:p-5">
      <div className="crm-stat-glow" />
      <div className="relative z-10 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-[10px] font-semibold text-slate-500">{label}</p>
          <p className="mt-2 text-[24px] font-black tracking-[-.045em] text-slate-100">{value}</p>
          {helper && <p className="mt-2 flex items-center gap-1.5 text-[9px] text-slate-600"><ArrowUpRight size={11} className="text-emerald-400" />{helper}</p>}
        </div>
        <div className={`crm-stat-icon ${tone}`}><Icon size={18} /></div>
      </div>
    </Card>
  );
}
