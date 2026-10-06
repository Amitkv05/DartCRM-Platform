import { cn } from "@/lib/utils";

export function Card({ className, ...props }) {
  return <div className={cn("crm-card", className)} {...props} />;
}
export function CardHeader({ className, ...props }) {
  return <div className={cn("p-5 pb-3 sm:p-5 sm:pb-3", className)} {...props} />;
}
export function CardTitle({ className, ...props }) {
  return <h3 className={cn("text-[13px] font-bold tracking-[.01em] text-slate-900 dark:text-slate-100", className)} {...props} />;
}
export function CardDescription({ className, ...props }) {
  return <p className={cn("mt-1.5 text-[11px] leading-5 text-slate-500 dark:text-slate-500", className)} {...props} />;
}
export function CardContent({ className, ...props }) {
  return <div className={cn("p-5 pt-2", className)} {...props} />;
}
