import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Plus, Search, Eye, Pencil, Trash2 } from "lucide-react";
import { customerApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import DataTable from "@/components/common/DataTable";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import StatusBadge from "@/components/common/StatusBadge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";

const copy = {
  SCHOOL: ["Schools", "Manage validated and pending school customers."],
  TRADE: ["Trade Customers", "Booksellers, distributors and trade accounts."],
  LIBRARY: ["Libraries", "Library customer master and approval lifecycle."],
  INSTITUTE: ["Institutes", "Institute and higher-education customer accounts."],
};

export default function CustomersPage({ customerType }) {
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();
  const [search, setSearch] = useState(params.get("search") || "");
  const query = useQuery({ queryKey: ["customers", customerType, params.get("search") || ""], queryFn: () => customerApi.list({ customerType, search: params.get("search") || undefined }) });
  const columns = useMemo(() => [
    { accessorKey: "customer_code", header: "Code", cell: ({ row }) => <span className="font-mono text-xs font-semibold text-brand-700">{row.original.customer_code || "—"}</span> },
    { accessorKey: "customer_name", header: "Customer", cell: ({ row }) => <div><p className="font-semibold">{row.original.customer_name}</p><p className="text-xs text-slate-500">{row.original.ref_code || row.original.customer_type}</p></div> },
    { accessorKey: "city", header: "City" },
    { accessorKey: "address", header: "Address", cell: ({ getValue }) => <span className="block max-w-xs truncate text-slate-600 dark:text-slate-300">{getValue() || "—"}</span> },
    { accessorKey: "validation_status", header: "Validation", cell: ({ getValue }) => <StatusBadge status={getValue()}/> },
    { accessorKey: "customer_status", header: "Status", cell: ({ getValue }) => <StatusBadge status={getValue()}/> },
    { id: "actions", header: "", cell: ({ row }) => <div className="flex justify-end gap-1" onClick={(e) => e.stopPropagation()}><Button size="icon" variant="ghost" title="View" onClick={() => navigate(`/customers/${row.original.id}`)}><Eye size={16}/></Button><Button size="icon" variant="ghost" title="Edit" onClick={() => navigate(`/customers/${row.original.id}/edit`)}><Pencil size={16}/></Button><Button size="icon" variant="ghost" title="Delete request" className="text-red-600" onClick={() => navigate(`/customers/${row.original.id}?delete=1`)}><Trash2 size={16}/></Button></div> },
  ], [navigate]);
  const meta = copy[customerType] || ["Customers", "CRM customer master."];

  return <>
    <PageHeader title={meta[0]} description={meta[1]} actions={<><Badge tone="blue">{query.data?.customers?.length || 0} records</Badge><Button variant="primary" onClick={() => navigate(`/customers/new?type=${customerType}`)}><Plus size={16}/>Add {customerType === "SCHOOL" ? "School" : "Customer"}</Button></>}/>
    <form className="mb-4 flex max-w-lg gap-2" onSubmit={(e) => { e.preventDefault(); const next = new URLSearchParams(params); search ? next.set("search", search) : next.delete("search"); setParams(next); }}><div className="relative flex-1"><Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"/><Input className="pl-9" value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search name, code or reference…"/></div><Button variant="outline">Search</Button></form>
    {query.isLoading ? <LoadingState/> : query.isError ? <ErrorState error={query.error} onRetry={query.refetch}/> : <DataTable columns={columns} data={query.data?.customers || []} onRowClick={(row) => navigate(`/customers/${row.id}`)}/>} 
  </>;
}
