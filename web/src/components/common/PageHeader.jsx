export default function PageHeader({ title, description, actions }) {
  return (
    <div className="crm-page-header mb-5 flex flex-wrap items-end justify-between gap-4 px-1 sm:mb-6">
      <div className="min-w-0">
        <div className="mb-2 flex items-center gap-2">
          <span className="h-1.5 w-1.5 rounded-full bg-brand-500 shadow-[0_0_12px_rgba(255,91,80,.8)]" />
          <span className="text-[8px] font-bold uppercase tracking-[.22em] text-slate-600">DartCRM Workspace</span>
        </div>
        <h1 className="text-[22px] font-black tracking-[-.035em] text-slate-950 dark:text-slate-100 sm:text-[26px]">{title}</h1>
        {description && <p className="mt-1.5 max-w-3xl text-[11px] leading-5 text-slate-500">{description}</p>}
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
    </div>
  );
}
