import { flexRender, getCoreRowModel, useReactTable } from "@tanstack/react-table";
import EmptyState from "@/components/common/EmptyState";

export default function DataTable({ columns, data = [], onRowClick, selectedRows, setSelectedRows, getRowId }) {
  const stableRowId = getRowId || ((row, index) => String(row.approval_id ?? row.history_id ?? row.executive_id ?? row.id ?? index));
  const table = useReactTable({ data, columns, getRowId: stableRowId, getCoreRowModel: getCoreRowModel(), state: selectedRows ? { rowSelection: selectedRows } : undefined, onRowSelectionChange: setSelectedRows, enableRowSelection: Boolean(setSelectedRows) });
  if (!data.length) return <EmptyState />;
  return (
    <div className="crm-table-shell overflow-hidden rounded-[16px] border border-white/[.08] bg-white/[.018]">
      <div className="scrollbar-thin overflow-x-auto">
        <table className="w-full min-w-[760px] text-left text-[11px]">
          <thead className="border-b border-white/[.06] bg-black/15 text-[8px] uppercase tracking-[.12em] text-slate-600">
            {table.getHeaderGroups().map((hg) => <tr key={hg.id}>{hg.headers.map((h) => <th key={h.id} className="px-4 py-3.5 font-semibold">{h.isPlaceholder ? null : flexRender(h.column.columnDef.header, h.getContext())}</th>)}</tr>)}
          </thead>
          <tbody className="divide-y divide-white/[.045]">
            {table.getRowModel().rows.map((row) => <tr key={row.id} className={onRowClick ? "cursor-pointer transition-colors hover:bg-white/[.035]" : "transition-colors hover:bg-white/[.015]"} onClick={() => onRowClick?.(row.original)}>{row.getVisibleCells().map((cell) => <td key={cell.id} className="px-4 py-3.5 align-middle text-slate-400">{flexRender(cell.column.columnDef.cell, cell.getContext())}</td>)}</tr>)}
          </tbody>
        </table>
      </div>
    </div>
  );
}
