import * as DialogPrimitive from "@radix-ui/react-dialog";
import { X } from "lucide-react";
import { cn } from "@/lib/utils";

export const Dialog = DialogPrimitive.Root;
export const DialogTrigger = DialogPrimitive.Trigger;
export const DialogClose = DialogPrimitive.Close;
export function DialogContent({ className, children, ...props }) {
  return (
    <DialogPrimitive.Portal>
      <DialogPrimitive.Overlay className="fixed inset-0 z-50 bg-black/70 backdrop-blur-md data-[state=open]:animate-in data-[state=closed]:animate-out" />
      <DialogPrimitive.Content className={cn("crm-dialog fixed left-1/2 top-1/2 z-50 max-h-[90vh] w-[calc(100%-2rem)] max-w-2xl -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-[18px] border border-white/[.11] bg-[#111519]/95 p-6 text-slate-200 shadow-2xl outline-none backdrop-blur-2xl", className)} {...props}>
        {children}
        <DialogPrimitive.Close className="absolute right-4 top-4 grid h-8 w-8 place-items-center rounded-lg border border-white/[.07] bg-white/[.025] text-slate-500 transition hover:bg-white/[.07] hover:text-white"><X size={16} /></DialogPrimitive.Close>
      </DialogPrimitive.Content>
    </DialogPrimitive.Portal>
  );
}
export function DialogTitle({ className, ...props }) { return <DialogPrimitive.Title className={cn("text-[15px] font-bold text-white", className)} {...props} />; }
export function DialogDescription({ className, ...props }) { return <DialogPrimitive.Description className={cn("mt-1.5 text-[11px] leading-5 text-slate-500", className)} {...props} />; }
