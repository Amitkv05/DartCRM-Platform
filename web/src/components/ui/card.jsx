import { cn } from "@/lib/utils";
export function Card({ className, ...props }) { return <div className={cn("rounded-2xl border border-slate-200 bg-white shadow-soft dark:border-slate-800 dark:bg-slate-900", className)} {...props} />; }
export function CardHeader({ className, ...props }) { return <div className={cn("p-5 pb-3", className)} {...props} />; }
export function CardTitle({ className, ...props }) { return <h3 className={cn("text-base font-bold text-slate-900 dark:text-white", className)} {...props} />; }
export function CardDescription({ className, ...props }) { return <p className={cn("mt-1 text-sm text-slate-500 dark:text-slate-400", className)} {...props} />; }
export function CardContent({ className, ...props }) { return <div className={cn("p-5 pt-2", className)} {...props} />; }
