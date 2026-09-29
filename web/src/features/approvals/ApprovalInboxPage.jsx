import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { CheckCircle2, Eye, Search, XCircle } from "lucide-react";
import { toast } from "sonner";
import { approvalApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import DataTable from "@/components/common/DataTable";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import StatusBadge from "@/components/common/StatusBadge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { getErrorMessage } from "@/utils/errors";
import { titleCase, formatDateTime } from "@/utils/format";

const approvalTitles = {
  CUSTOMER_CREATE: [
    "Customer Create Approvals",
    "Review new customer/school/trade/library creation requests.",
  ],
  CUSTOMER_UPDATE: [
    "Customer Update Approvals",
    "Compare current data against proposed customer changes.",
  ],
  CUSTOMER_DELETE: [
    "Customer Delete Approvals",
    "Review customer deactivation/delete requests.",
  ],
  CONTACT_CREATE: [
    "Contact Approvals",
    "Validate new customer contacts created by junior executives.",
  ],
  VISIT_BACKDATE: [
    "Visit Backdate Approvals",
    "Approve or reject requested visit dates outside the normal entry window.",
  ],
  CUSTOMER_SAMPLING: [
    "Customer Sampling Approvals",
    "Review requested books and customise approved quantities.",
  ],
  SELF_STOCK: [
    "Self-Stock Approvals",
    "Review stock requests and customise approved quantities.",
  ],
};

export default function ApprovalInboxPage({ module }) {
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [search, setSearch] = useState("");
  const [selection, setSelection] = useState({});
  const query = useQuery({
    queryKey: ["approvals", module || "ALL"],
    queryFn: () => approvalApi.list(module),
  });
  const bulk = useMutation({
    mutationFn: (action) =>
      approvalApi.bulkAction({
        approvalIds: Object.keys(selection)
          .filter((k) => selection[k])
          .map((k) => Number(k)),
        action,
        sendToNextLevel: true,
        remarks:
          action === "REJECT"
            ? "Bulk rejected from web CRM"
            : "Bulk approved from web CRM",
      }),
    onSuccess: () => {
      toast.success("Selected approvals processed");
      setSelection({});
      qc.invalidateQueries({ queryKey: ["approvals"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });
  const rows = (query.data?.approvals || []).filter(
    (x) =>
      !search ||
      `${x.request_number} ${x.requested_by} ${x.module_name}`
        .toLowerCase()
        .includes(search.toLowerCase()),
  );
  const columns = useMemo(
    () => [
      {
        id: "select",
        header: ({ table }) => (
          <Checkbox
            checked={table.getIsAllRowsSelected()}
            onChange={table.getToggleAllRowsSelectedHandler()}
          />
        ),
        cell: ({ row }) => (
          <Checkbox
            checked={row.getIsSelected()}
            onChange={row.getToggleSelectedHandler()}
            onClick={(e) => e.stopPropagation()}
          />
        ),
      },
      {
        accessorKey: "request_number",
        header: "Request",
        cell: ({ row }) => (
          <div>
            <p className="font-mono text-xs font-bold text-brand-700">
              {row.original.request_number}
            </p>
            <p className="mt-1 text-xs text-slate-500">
              {titleCase(row.original.module_name)}
            </p>
          </div>
        ),
      },
      {
        accessorKey: "requested_by",
        header: "Requested By",
        cell: ({ row }) => (
          <div>
            <p className="font-semibold">{row.original.requested_by}</p>
            <p className="text-xs text-slate-500">
              {row.original.requested_by_code}
            </p>
          </div>
        ),
      },
      {
        accessorKey: "current_level",
        header: "Level",
        cell: ({ getValue }) => <Badge tone="purple">L{getValue()}</Badge>,
      },
      {
        accessorKey: "status",
        header: "Status",
        cell: ({ getValue }) => <StatusBadge status={getValue()} />,
      },
      {
        accessorKey: "created_at",
        header: "Created",
        cell: ({ getValue }) => (
          <span className="text-sm text-slate-500">
            {formatDateTime(getValue())}
          </span>
        ),
      },
      {
        id: "action",
        header: "",
        cell: ({ row }) => (
          <Button
            size="sm"
            variant="outline"
            onClick={(e) => {
              e.stopPropagation();
              navigate(`/approvals/${row.original.approval_id}`);
            }}
          >
            <Eye size={14} />
            Review
          </Button>
        ),
      },
    ],
    [navigate],
  );
  const title = approvalTitles[module] || [
    "My Approval Inbox",
    "All approval requests currently assigned to you.",
  ];
  const selectedCount = Object.values(selection).filter(Boolean).length;

  return (
    <>
      <PageHeader
        title={title[0]}
        description={title[1]}
        actions={<Badge tone="amber">{rows.length} pending</Badge>}
      />
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <div className="relative min-w-64 flex-1 max-w-md">
          <Search
            size={16}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
          />
          <Input
            className="pl-9"
            placeholder="Search request or executive…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        {selectedCount > 0 && (
          <>
            <span className="text-sm text-slate-500">
              {selectedCount} selected
            </span>
            <Button
              size="sm"
              variant="outline"
              className="text-emerald-700"
              onClick={() => bulk.mutate("APPROVE")}
              disabled={bulk.isPending}
            >
              <CheckCircle2 size={15} />
              Bulk Approve
            </Button>
            <Button
              size="sm"
              variant="outline"
              className="text-red-700"
              onClick={() => bulk.mutate("REJECT")}
              disabled={bulk.isPending}
            >
              <XCircle size={15} />
              Bulk Reject
            </Button>
          </>
        )}
      </div>
      {query.isLoading ? (
        <LoadingState />
      ) : query.isError ? (
        <ErrorState error={query.error} onRetry={query.refetch} />
      ) : (
        <DataTable
          columns={columns}
          data={rows}
          selectedRows={selection}
          setSelectedRows={setSelection}
          onRowClick={(row) => navigate(`/approvals/${row.approval_id}`)}
        />
      )}
    </>
  );
}
