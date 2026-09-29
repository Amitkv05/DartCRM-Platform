import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Plus, Trash2 } from "lucide-react";
import { visitApi } from "@/api/crmApi";
import { WorkflowSection, EmptyMessage } from "@/components/parity/WorkflowSection";
import { FormField } from "@/components/common/FormField";
import { Select } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";

export default function FollowUpPanel({ departments = [], visitDate, rows, onChange }) {
  const [departmentId, setDepartmentId] = useState("");
  const [executiveId, setExecutiveId] = useState("");
  const [followUpDate, setFollowUpDate] = useState("");
  const [action, setAction] = useState("");
  const execs = useQuery({ queryKey: ["followup-executives", departmentId], queryFn: () => visitApi.followUpExecutives(departmentId), enabled: Boolean(departmentId) });
  const add = () => {
    if (!departmentId || !executiveId || !followUpDate || !action.trim()) return toast.error("Department, executive, follow-up date and action are required");
    if (visitDate && followUpDate < visitDate) return toast.error("Follow-up date cannot be before visit date");
    const dept = departments.find((x) => Number(x.id) === Number(departmentId));
    const exe = (execs.data?.executives || []).find((x) => Number(x.executive_id) === Number(executiveId));
    onChange([...rows, { departmentId: Number(departmentId), followUpExecutiveId: Number(executiveId), followUpDate, action: action.trim(), departmentName: dept?.department || `Department ${departmentId}`, executiveName: exe?.executive_name || `Executive ${executiveId}` }]);
    setExecutiveId(""); setFollowUpDate(""); setAction("");
  };
  return <WorkflowSection title="Follow Up Action"><div className="space-y-4">
    <div className="grid gap-3 md:grid-cols-4"><FormField label="Department"><Select value={departmentId} onChange={(e) => { setDepartmentId(e.target.value); setExecutiveId(""); }}><option value="">--Select--</option>{departments.map((x) => <option key={x.id} value={x.id}>{x.department}</option>)}</Select></FormField><FormField label="Executive"><Select value={executiveId} onChange={(e) => setExecutiveId(e.target.value)}><option value="">--Select--</option>{(execs.data?.executives || []).map((x) => <option key={x.executive_id} value={x.executive_id}>{x.executive_name}</option>)}</Select></FormField><FormField label="Follow Up Date"><Input type="date" min={visitDate || undefined} value={followUpDate} onChange={(e) => setFollowUpDate(e.target.value)}/></FormField><FormField label="Follow Up Action"><Textarea className="min-h-10" value={action} onChange={(e) => setAction(e.target.value)}/></FormField></div>
    <div className="flex justify-end"><Button type="button" variant="outline" onClick={add}><Plus size={15}/>Add Follow Up</Button></div>
    {!rows.length ? <EmptyMessage>No follow-up actions added.</EmptyMessage> : <div className="overflow-x-auto"><table className="w-full min-w-[720px] text-sm"><thead className="bg-amber-100 dark:bg-amber-950/30"><tr><th className="p-2 text-left">S.No</th><th className="p-2 text-left">Department</th><th className="p-2 text-left">Executive</th><th className="p-2 text-left">Date</th><th className="p-2 text-left">Action</th><th className="p-2"></th></tr></thead><tbody>{rows.map((r, i) => <tr key={`${r.followUpExecutiveId}-${r.followUpDate}-${i}`} className="border-t dark:border-slate-800"><td className="p-2">{i+1}</td><td className="p-2">{r.departmentName}</td><td className="p-2">{r.executiveName}</td><td className="p-2">{r.followUpDate}</td><td className="p-2">{r.action}</td><td className="p-2 text-right"><Button type="button" size="icon" variant="ghost" className="text-red-600" onClick={() => onChange(rows.filter((_, idx) => idx !== i))}><Trash2 size={15}/></Button></td></tr>)}</tbody></table></div>}
  </div></WorkflowSection>;
}
