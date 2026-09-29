import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Bell, CheckCheck, ExternalLink } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { notificationApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import EmptyState from "@/components/common/EmptyState";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { formatDateTime, titleCase } from "@/utils/format";
import { getErrorMessage } from "@/utils/errors";

export default function NotificationsPage() {
  const nav = useNavigate(); const qc = useQueryClient();
  const q = useQuery({ queryKey: ["notifications"], queryFn: notificationApi.list });
  const read = useMutation({ mutationFn: notificationApi.markRead, onSuccess: () => qc.invalidateQueries({ queryKey: ["notifications"] }), onError: (e) => toast.error(getErrorMessage(e)) });
  const open = async (n) => { if (!n.read_at) await read.mutateAsync(n.id).catch(() => {}); if (n.approval_id) nav(`/approvals/${n.approval_id}`); };
  const rows = q.data?.notifications || [];
  return <><PageHeader title="Notifications" description="Approval assignments and CRM activity addressed to your account."/>{q.isLoading ? <LoadingState/> : q.isError ? <ErrorState error={q.error}/> : !rows.length ? <EmptyState title="No notifications" description="You're all caught up."/> : <div className="space-y-3">{rows.map((n) => <Card key={n.id} className={!n.read_at ? "border-brand-200 bg-brand-50/40 dark:border-brand-900 dark:bg-brand-950/20" : ""}><CardContent className="flex items-start gap-4 p-4 sm:p-5"><div className={`mt-0.5 grid h-10 w-10 shrink-0 place-items-center rounded-xl ${n.read_at ? "bg-slate-100 text-slate-500 dark:bg-slate-800" : "bg-brand-100 text-brand-700 dark:bg-brand-950"}`}><Bell size={18}/></div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><p className="font-bold">{n.title}</p>{!n.read_at && <span className="h-2 w-2 rounded-full bg-brand-600"/>}</div><p className="mt-1 text-sm text-slate-600 dark:text-slate-300">{n.message}</p><p className="mt-2 text-xs text-slate-400">{titleCase(n.module_name || "CRM")} · {formatDateTime(n.created_at)}</p></div><div className="flex gap-1">{!n.read_at && <Button size="icon" variant="ghost" title="Mark read" onClick={() => read.mutate(n.id)}><CheckCheck size={17}/></Button>}{n.approval_id && <Button size="icon" variant="ghost" title="Open request" onClick={() => open(n)}><ExternalLink size={17}/></Button>}</div></CardContent></Card>)}</div>}</>;
}
