import { AlertTriangle, RotateCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { getErrorMessage } from "@/utils/errors";
export default function ErrorState({ error, onRetry }) { return <div className="rounded-2xl border border-red-200 bg-red-50 p-5 text-red-800 dark:border-red-900/60 dark:bg-red-950/30 dark:text-red-300"><div className="flex items-start gap-3"><AlertTriangle className="mt-0.5" size={20}/><div className="flex-1"><p className="font-semibold">Unable to load data</p><p className="mt-1 text-sm">{getErrorMessage(error)}</p>{onRetry && <Button size="sm" variant="outline" className="mt-3" onClick={onRetry}><RotateCw size={14}/>Retry</Button>}</div></div></div>; }
