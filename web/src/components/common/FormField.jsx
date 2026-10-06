export function FormField({ label, error, required, hint, children, className = "" }) {
  return (
    <label className={`block ${className}`}>
      <span className="mb-1.5 block text-[10px] font-semibold text-slate-400">{label}{required && <span className="ml-1 text-brand-400">*</span>}</span>
      {children}
      {hint && !error && <span className="mt-1.5 block text-[9px] leading-4 text-slate-600">{hint}</span>}
      {error && <span className="mt-1.5 block text-[9px] font-semibold text-red-300">{error}</span>}
    </label>
  );
}
