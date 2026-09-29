import { cn } from "@/lib/utils";
export function Select({ className, children, ...props }) {
  return <select className={cn("h-10 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm outline-none transition focus:border-brand-500 focus:ring-2 focus:ring-brand-100 dark:border-slate-700 dark:bg-slate-950 dark:focus:ring-brand-950", className)} {...props}>{children}</select>;
}
