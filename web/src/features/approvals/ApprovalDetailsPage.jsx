import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, CheckCircle2, XCircle } from "lucide-react";
import { toast } from "sonner";
import { approvalApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import StatusBadge from "@/components/common/StatusBadge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { formatCurrency, formatDateTime, titleCase } from "@/utils/format";
import { getErrorMessage } from "@/utils/errors";

function KeyValueGrid({ value }) {
  if (!value || typeof value !== "object") return null;
  return (
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
      {Object.entries(value)
        .filter(
          ([, v]) => v !== null && v !== undefined && typeof v !== "object",
        )
        .map(([k, v]) => (
          <div
            key={k}
            className="rounded-xl bg-slate-50 p-3 dark:bg-slate-800/60"
          >
            <p className="text-[11px] font-bold uppercase tracking-wide text-slate-400">
              {titleCase(k)}
            </p>
            <p className="mt-1 break-words text-sm font-medium">{String(v)}</p>
          </div>
        ))}
    </div>
  );
}

function CustomerUpdateDiff({ change }) {
  if (!change) return null;
  const original = change.original_snapshot?.customer || {};
  const proposed = change.proposed_payload || {};
  const keys = [
    ...new Set([...Object.keys(original), ...Object.keys(proposed)]),
  ].filter((k) => proposed[k] !== undefined && typeof proposed[k] !== "object");
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b text-left text-xs uppercase text-slate-400">
            <th className="py-2">Field</th>
            <th className="py-2">Current</th>
            <th className="py-2">Proposed</th>
          </tr>
        </thead>
        <tbody>
          {keys.map((k) => (
            <tr
              key={k}
              className="border-b border-slate-100 dark:border-slate-800"
            >
              <td className="py-3 font-semibold">{titleCase(k)}</td>
              <td className="py-3 text-slate-500">
                {String(original[k] ?? "—")}
              </td>
              <td className="py-3 font-medium text-brand-700">
                {String(proposed[k] ?? "—")}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function ApprovalDetailsPage() {
  const { approvalId } = useParams();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [remarks, setRemarks] = useState("");
  const [sendNext, setSendNext] = useState(true);
  const [qty, setQty] = useState({});
  const query = useQuery({
    queryKey: ["approval", approvalId],
    queryFn: () => approvalApi.details(approvalId),
  });
  const items = useMemo(
    () => query.data?.requestData?.items || [],
    [query.data?.requestData?.items],
  );
  useEffect(() => {
    if (items.length)
      setQty(
        Object.fromEntries(
          items.map((i) => [
            i.item_id,
            Number(i.approved_qty ?? i.requested_qty ?? 0),
          ]),
        ),
      );
  }, [items]);
  const mutation = useMutation({
    mutationFn: (action) =>
      approvalApi.action(approvalId, {
        action,
        remarks: remarks || undefined,
        sendToNextLevel: action === "APPROVE" ? sendNext : false,
        ...(action === "APPROVE" &&
        query.data?.capabilities?.supportsEditableQuantities
          ? {
              items: items.map((i) => ({
                itemId: i.item_id,
                approvedQty: Number(qty[i.item_id] ?? i.requested_qty),
              })),
            }
          : {}),
      }),
    onSuccess: (r) => {
      toast.success(r.message);
      qc.invalidateQueries({ queryKey: ["approvals"] });
      qc.invalidateQueries({ queryKey: ["approval", approvalId] });
      navigate(-1);
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });
  if (query.isLoading) return <LoadingState />;
  if (query.isError)
    return <ErrorState error={query.error} onRetry={query.refetch} />;
  const {
    approval,
    requestData = {},
    history = [],
    itemHistory = [],
    capabilities = {},
  } = query.data;
  const primary =
    requestData.customer ||
    requestData.contact ||
    requestData.backdateRequest ||
    requestData.request ||
    requestData.changeRequest;
  const title = `${titleCase(approval.module_name)} · ${approval.request_number}`;

  return (
    <>
      <PageHeader
        title={title}
        description={`Requested by ${approval.requested_by_name} (${approval.requested_by_code})`}
        actions={
          <>
            <StatusBadge status={approval.status} />
            <Button variant="outline" onClick={() => navigate(-1)}>
              <ArrowLeft size={16} />
              Back
            </Button>
          </>
        }
      />
      <div className="grid gap-5 xl:grid-cols-[1.25fr_.75fr]">
        <div className="space-y-5">
          <Card>
            <CardHeader>
              <CardTitle>Request Details</CardTitle>
            </CardHeader>
            <CardContent>
              {approval.module_name === "CUSTOMER_UPDATE" ? (
                <CustomerUpdateDiff change={requestData.changeRequest} />
              ) : (
                <KeyValueGrid value={primary} />
              )}
            </CardContent>
          </Card>
          {items.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Requested Items</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="overflow-x-auto">
                  <table className="w-full min-w-[700px] text-sm">
                    <thead>
                      <tr className="border-b text-left text-xs uppercase text-slate-400">
                        <th className="py-2">Book</th>
                        <th>Requested</th>
                        <th>Previous</th>
                        <th>Approve Qty</th>
                        <th>Value</th>
                      </tr>
                    </thead>
                    <tbody>
                      {items.map((i) => (
                        <tr
                          key={i.item_id}
                          className="border-b border-slate-100 dark:border-slate-800"
                        >
                          <td className="py-3">
                            <p className="font-semibold">{i.title}</p>
                            <p className="text-xs text-slate-500">
                              {i.isbn || i.series_name || ""}
                            </p>
                          </td>
                          <td>{i.requested_qty}</td>
                          <td>
                            {i.approved_qty ?? i.previous_approved_qty ?? "—"}
                          </td>
                          <td>
                            {capabilities.canAct ? (
                              <Input
                                className="w-28"
                                type="number"
                                min="0"
                                max={i.requested_qty}
                                value={qty[i.item_id] ?? ""}
                                onChange={(e) =>
                                  setQty((q) => ({
                                    ...q,
                                    [i.item_id]: e.target.value,
                                  }))
                                }
                              />
                            ) : (
                              (i.approved_qty ?? "—")
                            )}
                          </td>
                          <td>
                            {formatCurrency(
                              Number(i.unit_price || 0) *
                                Number(
                                  (qty[i.item_id] ?? i.requested_qty) || 0,
                                ),
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          )}
          {capabilities.canAct && (
            <Card>
              <CardHeader>
                <CardTitle>Approval Action</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <p className="mb-1.5 text-sm font-semibold">Remarks</p>
                  <Textarea
                    value={remarks}
                    onChange={(e) => setRemarks(e.target.value)}
                    placeholder="Add approval or rejection remarks…"
                  />
                </div>
                {capabilities.canSendToNextLevel && (
                  <label className="flex items-start gap-3 rounded-xl border border-brand-100 bg-brand-50 p-4 text-sm dark:border-brand-900 dark:bg-brand-950/30">
                    <Checkbox
                      checked={sendNext}
                      onChange={(e) => setSendNext(e.target.checked)}
                    />
                    <div>
                      <p className="font-semibold">
                        Approve and send to next level
                      </p>
                      <p className="mt-1 text-xs text-slate-500">
                        If unchecked, approval becomes final at your level. Next
                        eligible approver:{" "}
                        {capabilities.nextEligibleApprover?.executiveName ||
                          capabilities.nextEligibleApprover?.executive_name ||
                          "next manager"}
                        .
                      </p>
                    </div>
                  </label>
                )}
                <div className="flex flex-wrap justify-end gap-2">
                  <Button
                    variant="danger"
                    disabled={mutation.isPending}
                    onClick={() => {
                      if (!remarks.trim())
                        return toast.error(
                          "Remarks are required for rejection",
                        );
                      mutation.mutate("REJECT");
                    }}
                  >
                    <XCircle size={16} />
                    Reject
                  </Button>
                  <Button
                    variant="primary"
                    disabled={mutation.isPending}
                    onClick={() => mutation.mutate("APPROVE")}
                  >
                    <CheckCircle2 size={16} />
                    {sendNext && capabilities.canSendToNextLevel
                      ? "Approve & Forward"
                      : "Final Approve"}
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
        <div className="space-y-5">
          <Card>
            <CardHeader>
              <CardTitle>Approval Tracker</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Current Level</span>
                <Badge tone="purple">L{approval.current_level}</Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Current Approver</span>
                <span className="text-sm font-semibold">
                  {approval.current_approver_name || "—"}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Created</span>
                <span className="text-sm">
                  {formatDateTime(approval.created_at)}
                </span>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle>Action History</CardTitle>
            </CardHeader>
            <CardContent>
              {history.length ? (
                <div className="space-y-4">
                  {/* {history.map((h, idx) => ( */}
                  {history.map((h) => (
                    <div
                      key={h.id}
                      className="relative border-l-2 border-slate-200 pl-4 dark:border-slate-700"
                    >
                      <span className="absolute -left-[5px] top-1 h-2 w-2 rounded-full bg-brand-600" />
                      <div className="flex flex-wrap items-center gap-2">
                        <StatusBadge status={h.action} />
                        <span className="text-xs text-slate-500">
                          L{h.approval_level}
                        </span>
                      </div>
                      <p className="mt-1 text-sm font-semibold">
                        {h.action_by_name}
                      </p>
                      <p className="text-xs text-slate-500">
                        {formatDateTime(h.created_at)}
                      </p>
                      {h.remarks && (
                        <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">
                          {h.remarks}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <p className="py-4 text-center text-sm text-slate-500">
                  No actions recorded yet.
                </p>
              )}
            </CardContent>
          </Card>
          {itemHistory.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Quantity History</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                {itemHistory.map((h) => (
                  <div
                    key={h.id}
                    className="rounded-xl bg-slate-50 p-3 text-sm dark:bg-slate-800"
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-semibold">Book #{h.book_id}</span>
                      <Badge tone="blue">L{h.approval_level}</Badge>
                    </div>
                    <p className="mt-1 text-xs text-slate-500">
                      {h.previous_approved_qty ?? 0} →{" "}
                      <b className="text-slate-800 dark:text-white">
                        {h.approved_qty}
                      </b>{" "}
                      by {h.approved_by_name}
                    </p>
                  </div>
                ))}
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </>
  );
}
