import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { Search } from "lucide-react";
import { approvalApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import DataTable from "@/components/common/DataTable";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import StatusBadge from "@/components/common/StatusBadge";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { formatDateTime, titleCase } from "@/utils/format";

export default function MyRequestHistoryPage() {
  const navigate = useNavigate();
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState("");
  const q = useQuery({ queryKey: ["my-request-history", status], queryFn: () => approvalApi.mine(status ? { status } : {}) });
  const rows = (q.data?.requests || []).filter((x) => !search || `${x.request_number} ${x.module_name} ${x.last_action_by}`.toLowerCase().includes(search.toLowerCase()));
  const columns = useMemo(() => [
    { accessorKey: "request_number", header: "Request", cell: ({ row }) => <div><p className="font-mono text-xs font-bold text-brand-700">{row.original.request_number}</p><p className="text-xs text-slate-500">{titleCase(row.original.module_name)}</p></div> },
    { accessorKey: "status", header: "Status", cell: ({ getValue }) => <StatusBadge status={getValue()}/> },
    { accessorKey: "current_approver_name", header: "Current Approver", cell: ({ row }) => <div><p className="text-sm font-semibold">{row.original.current_approver_name || "—"}</p><p className="text-xs text-slate-500">{row.original.current_approver_profile_code || ""}</p></div> },
    { accessorKey: "last_action", header: "Last Action", cell: ({ row }) => <div><p className="text-sm">{row.original.last_action ? titleCase(row.original.last_action) : "—"}</p><p className="text-xs text-slate-500">{row.original.last_action_by ? `${row.original.last_action_by} (${row.original.last_action_profile_code || ""})` : ""}</p></div> },
    { accessorKey: "created_at", header: "Created", cell: ({ getValue }) => <span className="text-slate-500">{formatDateTime(getValue())}</span> },
  ], []);
  return <><PageHeader title="My Request History" description="Track customer, contact, backdate, sampling and self-stock requests through every approval level."/><div className="mb-4 flex flex-wrap gap-2"><div className="relative min-w-64 flex-1 max-w-md"><Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"/><Input className="pl-9" value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search request…"/></div><Select className="w-44" value={status} onChange={(e) => setStatus(e.target.value)}><option value="">All statuses</option><option value="PENDING">Pending</option><option value="APPROVED">Approved</option><option value="REJECTED">Rejected</option></Select></div>{q.isLoading ? <LoadingState/> : q.isError ? <ErrorState error={q.error}/> : <DataTable columns={columns} data={rows} onRowClick={(row) => navigate(`/approvals/${row.approval_id}`)}/>}</>;
}
