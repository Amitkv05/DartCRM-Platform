import { AlertTriangle, RotateCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { getErrorMessage } from "@/utils/errors";
export default function ErrorState({ error, onRetry }) {
  return <div className="rounded-[16px] border border-red-400/15 bg-red-400/[.055] p-5 text-red-200"><div className="flex items-start gap-3"><div className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-red-400/10"><AlertTriangle size={18}/></div><div className="min-w-0 flex-1"><p className="text-[12px] font-bold">Unable to load data</p><p className="mt-1 text-[10px] leading-5 text-red-300/70">{getErrorMessage(error)}</p>{onRetry && <Button size="sm" variant="outline" className="mt-3" onClick={onRetry}><RotateCw size={13}/>Retry</Button>}</div></div></div>;
}
