import { cn } from "@/lib/utils";
export function Checkbox({ className, ...props }) {
  return <input type="checkbox" className={cn("h-4 w-4 rounded border-white/20 bg-white/[.04] text-brand-500 accent-brand-500 focus:ring-brand-500/30", className)} {...props} />;
}
