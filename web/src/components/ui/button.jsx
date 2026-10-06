import { Slot } from "@radix-ui/react-slot";
import { cva } from "class-variance-authority";
import { Children, isValidElement, useEffect, useRef, useState } from "react";
import { cn } from "@/lib/utils";

const variants = cva(
  "crm-button inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-[10px] text-xs font-semibold transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/35 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "border border-brand-500/45 bg-gradient-to-br from-brand-500 to-brand-700 text-white shadow-glow hover:-translate-y-0.5 hover:brightness-110",
        primary: "border border-brand-500/45 bg-gradient-to-br from-brand-500 to-brand-700 text-white shadow-glow hover:-translate-y-0.5 hover:brightness-110",
        secondary: "border border-white/10 bg-white/[.055] text-slate-200 hover:border-white/15 hover:bg-white/[.09]",
        outline: "border border-white/10 bg-white/[.025] text-slate-300 hover:border-white/20 hover:bg-white/[.06] hover:text-white",
        ghost: "border border-transparent bg-transparent text-slate-400 hover:bg-white/[.055] hover:text-white",
        danger: "border border-red-500/35 bg-red-500/15 text-red-300 hover:bg-red-500/24 hover:text-red-200",
      },
      size: {
        sm: "h-8 px-3",
        md: "h-10 px-4",
        lg: "h-11 px-5",
        icon: "h-10 w-10 p-0",
      },
    },
    defaultVariants: { variant: "default", size: "md" },
  },
);

function textFromChildren(value) {
  return Children.toArray(value)
    .map((child) => {
      if (typeof child === "string" || typeof child === "number") return String(child);
      if (isValidElement(child)) return textFromChildren(child.props?.children);
      return "";
    })
    .join(" ")
    .trim();
}

const loadingWords = /(?:loading|uploading|saving|signing|submitting|requesting|updating|working|processing|deleting|creating|sending|approving|rejecting|removing|inviting|generating|syncing|publishing|checking\s*(?:in|out)?)[.….]*$/i;

export function Button({
  className,
  variant,
  size,
  asChild = false,
  loading,
  onClick,
  children,
  ...props
}) {
  const [clicked, setClicked] = useState(false);
  const timer = useRef(null);
  const inferredLoading = loading ?? loadingWords.test(textFromChildren(children));

  useEffect(() => () => window.clearTimeout(timer.current), []);

  if (asChild) {
    return (
      <Slot className={cn(variants({ variant, size }), className)} {...props}>
        {children}
      </Slot>
    );
  }

  const handleClick = (event) => {
    if (!props.disabled && !inferredLoading) {
      setClicked(false);
      window.clearTimeout(timer.current);
      window.requestAnimationFrame(() => {
        setClicked(true);
        timer.current = window.setTimeout(() => setClicked(false), 520);
      });
    }
    onClick?.(event);
  };

  return (
    <button
      className={cn(variants({ variant, size }), clicked && "crm-button-clicked", className)}
      data-loading={inferredLoading ? "true" : "false"}
      aria-busy={inferredLoading || undefined}
      onClick={handleClick}
      {...props}
    >
      <span className="crm-button-fill" aria-hidden="true" />
      <span className="crm-button-content">{children}</span>
      <span className="crm-button-progress" aria-hidden="true" />
    </button>
  );
}
