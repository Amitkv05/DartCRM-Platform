import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { CalendarClock } from "lucide-react";
import { toast } from "sonner";
import { visitApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import DataTable from "@/components/common/DataTable";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import StatusBadge from "@/components/common/StatusBadge";
import { formatDate, formatDateTime } from "@/utils/format";
import { getErrorMessage } from "@/utils/errors";

export default function BackdateRequestPage() {
  const qc = useQueryClient(); const [visitDate,setVisitDate]=useState(""); const [reason,setReason]=useState("");
  const q = useQuery({ queryKey:["visit-backdates"], queryFn:visitApi.backdateRequests });
  const m = useMutation({ mutationFn:()=>visitApi.requestBackdate({visitDate,reason}), onSuccess:()=>{toast.success("Backdate request submitted");setVisitDate("");setReason("");qc.invalidateQueries({queryKey:["visit-backdates"]});qc.invalidateQueries({queryKey:["my-request-history"]});}, onError:(e)=>toast.error(getErrorMessage(e)) });
  const columns=useMemo(()=>[{accessorKey:"requested_visit_date",header:"Visit Date",cell:({getValue})=>formatDate(getValue())},{accessorKey:"reason",header:"Reason"},{accessorKey:"status",header:"Status",cell:({getValue})=><StatusBadge status={getValue()}/>},{accessorKey:"current_level",header:"Approval Level",cell:({getValue})=>getValue()?`L${getValue()}`:"—"},{accessorKey:"created_at",header:"Requested",cell:({getValue})=>formatDateTime(getValue())}],[]);
  return <><PageHeader title="Visit Backdate Request" description="Request permission for a visit date outside the normal DSR entry window."/><div className="grid gap-5 xl:grid-cols-[.8fr_1.2fr]"><Card><CardHeader><CardTitle>New Request</CardTitle></CardHeader><CardContent className="space-y-4"><div><p className="mb-1.5 text-sm font-semibold">Visit Date</p><Input type="date" value={visitDate} onChange={(e)=>setVisitDate(e.target.value)}/></div><div><p className="mb-1.5 text-sm font-semibold">Reason</p><Textarea value={reason} onChange={(e)=>setReason(e.target.value)} placeholder="Why is this backdated entry required?"/></div><Button className="w-full" variant="primary" disabled={!visitDate||!reason.trim()||m.isPending} onClick={()=>m.mutate()}><CalendarClock size={16}/>{m.isPending?"Submitting…":"Submit Request"}</Button></CardContent></Card><div>{q.isLoading?<p className="p-8 text-center text-sm text-slate-500">Loading…</p>:<DataTable columns={columns} data={q.data?.requests||[]}/>}</div></div></>;
}
