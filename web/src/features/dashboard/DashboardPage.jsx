import { useQueries } from "@tanstack/react-query";
import { useSelector } from "react-redux";
import { Building2, ClipboardCheck, Package, Boxes, Bell, MapPin, ArrowRight } from "lucide-react";
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, BarChart, Bar, CartesianGrid, XAxis, YAxis } from "recharts";
import { customerApi, approvalApi, samplingApi, selfStockApi, notificationApi, planApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import StatCard from "@/components/common/StatCard";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import StatusBadge from "@/components/common/StatusBadge";
import LoadingState from "@/components/common/LoadingState";
import { Link } from "react-router-dom";
import { formatDate } from "@/utils/format";

const colors = ["#35c9ec", "#8c6df2", "#47db7c", "#ff8c61"];

export default function DashboardPage() {
  const user = useSelector((s) => s.auth.user);
  const results = useQueries({ queries: [
    { queryKey: ["customers", "all-dashboard"], queryFn: () => customerApi.list({}) },
    { queryKey: ["approvals", "all"], queryFn: () => approvalApi.list() },
    { queryKey: ["sampling", "requests"], queryFn: samplingApi.requests },
    { queryKey: ["self-stock", "requests"], queryFn: selfStockApi.requests },
    { queryKey: ["notifications"], queryFn: notificationApi.list },
    { queryKey: ["plans", "dashboard"], queryFn: () => planApi.list({}) },
  ]});
  if (results.some((q) => q.isLoading)) return <LoadingState label="Loading dashboard…"/>;

  const customers = results[0].data?.customers || [];
  const approvals = results[1].data?.approvals || [];
  const sampling = results[2].data?.requests || [];
  const selfStock = results[3].data?.requests || [];
  const notifications = results[4].data?.notifications || [];
  const plans = [...(results[5].data?.todayPlan || []), ...(results[5].data?.tomorrowPlan || []), ...(results[5].data?.travelPlan || [])];
  const unread = notifications.filter((x) => !x.read_at && !x.is_read).length;
  const customerTypes = ["SCHOOL", "TRADE", "LIBRARY", "INSTITUTE"].map((type) => ({ name: type, value: customers.filter((c) => c.customer_type === type).length })).filter((x) => x.value);
  const requestBars = [
    { name: "Sampling", Pending: sampling.filter((x) => String(x.request_status).includes("PENDING")).length, Approved: sampling.filter((x) => String(x.request_status).includes("APPROVED")).length },
    { name: "Self-Stock", Pending: selfStock.filter((x) => String(x.request_status).includes("PENDING")).length, Approved: selfStock.filter((x) => String(x.request_status).includes("APPROVED")).length },
  ];

  return <>
    <PageHeader title={`Welcome, ${user?.executiveName || "Executive"}`} description="Live operational overview from CRM Backend V4." actions={<Button asChild variant="outline"><Link to="/requests/my-history">View Request History <ArrowRight size={15}/></Link></Button>}/>
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
      <StatCard icon={Building2} label="Customers" value={customers.length} helper="Validated & visible"/>
      <StatCard icon={ClipboardCheck} label="Pending Approvals" value={approvals.length} helper={user?.approvalEnabled ? "Assigned to you" : "Request-only role"} tone="text-amber-300"/>
      <StatCard icon={Package} label="Sampling Requests" value={sampling.length} helper={`${sampling.filter((x) => String(x.request_status).includes("PENDING")).length} pending`} tone="text-emerald-300"/>
      <StatCard icon={Boxes} label="Self-Stock" value={selfStock.length} helper={`${selfStock.filter((x) => String(x.request_status).includes("PENDING")).length} pending`} tone="text-violet-300"/>
      <StatCard icon={Bell} label="Unread Alerts" value={unread} helper="Notifications" tone="text-red-300"/>
    </div>

    <div className="mt-5 grid gap-5 xl:grid-cols-[1.3fr_.7fr]">
      <Card><CardHeader><CardTitle>Request Performance</CardTitle><CardDescription>Pending vs approved requests currently visible to your account.</CardDescription></CardHeader><CardContent><div className="h-72"><ResponsiveContainer width="100%" height="100%"><BarChart data={requestBars}><CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(255,255,255,.06)"/><XAxis dataKey="name"/><YAxis allowDecimals={false}/><Tooltip/><Bar dataKey="Approved" fill="#47db7c" radius={[6,6,0,0]}/><Bar dataKey="Pending" fill="#ff8c61" radius={[6,6,0,0]}/></BarChart></ResponsiveContainer></div></CardContent></Card>
      <Card><CardHeader><CardTitle>Customer Mix</CardTitle><CardDescription>Visible customer master distribution.</CardDescription></CardHeader><CardContent><div className="h-72"><ResponsiveContainer width="100%" height="100%"><PieChart><Pie data={customerTypes} dataKey="value" nameKey="name" innerRadius={58} outerRadius={88} paddingAngle={3}>{customerTypes.map((_, i) => <Cell key={i} fill={colors[i % colors.length]}/>)}</Pie><Tooltip/></PieChart></ResponsiveContainer></div><div className="grid grid-cols-2 gap-2">{customerTypes.map((x,i) => <div key={x.name} className="flex items-center justify-between rounded-lg bg-slate-50 px-3 py-2 text-sm dark:bg-slate-800"><span className="flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-full" style={{background:colors[i%colors.length]}}/>{x.name}</span><b>{x.value}</b></div>)}</div></CardContent></Card>
    </div>

    <div className="mt-5 grid gap-5 lg:grid-cols-2">
      <Card><CardHeader className="flex-row items-center justify-between"><div><CardTitle>Recent Approvals</CardTitle><CardDescription>Requests currently waiting for you.</CardDescription></div><Button asChild variant="ghost" size="sm"><Link to="/approvals">Open Inbox</Link></Button></CardHeader><CardContent>{approvals.length ? <div className="space-y-2">{approvals.slice(0,5).map((a) => <Link key={a.approval_id} to={`/approvals/${a.approval_id}`} className="flex items-center justify-between rounded-xl border border-slate-100 p-3 hover:bg-slate-50 dark:border-slate-800 dark:hover:bg-slate-800"><div><p className="text-sm font-semibold">{a.request_number}</p><p className="text-xs text-slate-500">{a.module_name} · {a.requested_by}</p></div><StatusBadge status={a.status}/></Link>)}</div> : <p className="py-8 text-center text-sm text-slate-500">No pending approvals.</p>}</CardContent></Card>
      <Card><CardHeader><CardTitle>Plan Snapshot</CardTitle><CardDescription>Latest plan entries from your CRM account.</CardDescription></CardHeader><CardContent>{plans.length ? <div className="space-y-2">{plans.slice(0,5).map((p,i) => <div key={p.id || i} className="flex items-center gap-3 rounded-xl border border-slate-100 p-3 dark:border-slate-800"><div className="rounded-lg bg-blue-50 p-2 text-brand-700 dark:bg-brand-950/50"><MapPin size={16}/></div><div className="min-w-0"><p className="truncate text-sm font-semibold">{p.customer_name || p.customerName || `Plan #${p.id}`}</p><p className="text-xs text-slate-500">{formatDate(p.plan_date || p.planDate || p.visit_date)}</p></div></div>)}</div> : <p className="py-8 text-center text-sm text-slate-500">No plan entries found.</p>}</CardContent></Card>
    </div>
  </>;
}
