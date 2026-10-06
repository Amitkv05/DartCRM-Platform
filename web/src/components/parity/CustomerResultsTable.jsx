import { Search } from "lucide-react";
import { useMemo, useState } from "react";
import { WorkflowSection, EmptyMessage } from "@/components/parity/WorkflowSection";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Button } from "@/components/ui/button";

export default function CustomerResultsTable({ title, rows = [], onRowClick, onBackToSearch }) {
  const [pageSize, setPageSize] = useState(25);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const filtered = useMemo(() => rows.filter((r) => !search || `${r.name} ${r.code} ${r.refCode} ${r.address} ${r.city} ${r.state}`.toLowerCase().includes(search.toLowerCase())), [rows, search]);
  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const safePage = Math.min(page, totalPages);
  const visible = filtered.slice((safePage - 1) * pageSize, safePage * pageSize);

  return (
    <WorkflowSection title={title} actions={<Button size="sm" variant="secondary" onClick={onBackToSearch}><Search size={15}/>Search</Button>}>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <label className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400">Show <Select className="w-24" value={pageSize} onChange={(e) => { setPageSize(Number(e.target.value)); setPage(1); }}><option>10</option><option>25</option><option>50</option><option>100</option></Select> entries</label>
        <label className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400">Search: <Input className="w-56" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }}/></label>
      </div>
      {!visible.length ? <EmptyMessage>No customers found. Change the search filters and try again.</EmptyMessage> : <div className="crm-table-shell overflow-x-auto rounded-xl border border-white/[.08] bg-white/[.012]"><table className="w-full min-w-[900px] border-collapse text-left text-sm"><thead className="border-b border-white/[.06] bg-black/15 text-[9px] uppercase tracking-[.1em] text-slate-600"><tr><th className="p-3">S.No</th><th className="p-3">Customer Name</th><th className="p-3">Customer Code</th><th className="p-3">Address</th><th className="p-3">City</th><th className="p-3">State</th></tr></thead><tbody>{visible.map((r, idx) => <tr key={r.id} className="cursor-pointer border-t border-white/[.045] transition-colors odd:bg-white/[.008] hover:bg-white/[.04]" onClick={() => onRowClick(r)}><td className="p-3">{(safePage - 1) * pageSize + idx + 1}</td><td className="p-3 font-semibold">{r.name}</td><td className="p-3 font-semibold text-cyan-300">{r.code || "—"}</td><td className="max-w-md p-3">{r.address || "—"}</td><td className="p-3">{r.city || "—"}</td><td className="p-3">{r.state || "—"}</td></tr>)}</tbody></table></div>}
      <div className="mt-4 flex flex-wrap items-center justify-between gap-3 text-sm"><span className="text-slate-500">Showing {visible.length ? (safePage - 1) * pageSize + 1 : 0} to {Math.min(safePage * pageSize, filtered.length)} of {filtered.length}</span><div className="flex items-center gap-2"><Button size="sm" variant="outline" disabled={safePage <= 1} onClick={() => setPage((p) => Math.max(1, p - 1))}>Previous</Button><span>Page {safePage} of {totalPages}</span><Button size="sm" variant="outline" disabled={safePage >= totalPages} onClick={() => setPage((p) => Math.min(totalPages, p + 1))}>Next</Button></div></div>
    </WorkflowSection>
  );
}
