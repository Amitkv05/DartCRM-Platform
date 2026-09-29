import { flexRender, getCoreRowModel, useReactTable } from "@tanstack/react-table";
import EmptyState from "@/components/common/EmptyState";

export default function DataTable({ columns, data = [], onRowClick, selectedRows, setSelectedRows, getRowId }) {
  const stableRowId = getRowId || ((row, index) => String(row.approval_id ?? row.history_id ?? row.executive_id ?? row.id ?? index));
  const table = useReactTable({ data, columns, getRowId: stableRowId, getCoreRowModel: getCoreRowModel(), state: selectedRows ? { rowSelection: selectedRows } : undefined, onRowSelectionChange: setSelectedRows, enableRowSelection: Boolean(setSelectedRows) });
  if (!data.length) return <EmptyState />;
  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white dark:border-slate-800 dark:bg-slate-900">
      <div className="overflow-x-auto scrollbar-thin">
        <table className="w-full min-w-[760px] text-left text-sm">
          <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500 dark:bg-slate-950/60">
            {table.getHeaderGroups().map((hg) => <tr key={hg.id}>{hg.headers.map((h) => <th key={h.id} className="px-4 py-3 font-semibold">{h.isPlaceholder ? null : flexRender(h.column.columnDef.header, h.getContext())}</th>)}</tr>)}
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
            {table.getRowModel().rows.map((row) => <tr key={row.id} className={onRowClick ? "cursor-pointer transition hover:bg-slate-50 dark:hover:bg-slate-800/60" : ""} onClick={() => onRowClick?.(row.original)}>{row.getVisibleCells().map((cell) => <td key={cell.id} className="px-4 py-3 align-middle">{flexRender(cell.column.columnDef.cell, cell.getContext())}</td>)}</tr>)}
          </tbody>
        </table>
      </div>
    </div>
  );
}
