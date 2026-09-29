import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { useSelector } from "react-redux";
import { KeyRound, ShieldCheck, UserRound } from "lucide-react";
import { toast } from "sonner";
import { authApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { getErrorMessage } from "@/utils/errors";

export default function SettingsPage() {
  const user = useSelector((s) => s.auth.user); const [form, setForm] = useState({ currentPassword:"", newPassword:"", confirmPassword:"" });
  const mutation = useMutation({ mutationFn: () => authApi.changePassword({ currentPassword: form.currentPassword, newPassword: form.newPassword }), onSuccess: (r) => { toast.success(r.message || "Password changed"); setForm({currentPassword:"",newPassword:"",confirmPassword:""}); }, onError:(e)=>toast.error(getErrorMessage(e)) });
  const submit = () => { if (!form.currentPassword || form.newPassword.length < 8) return toast.error("Enter current password and a new password of at least 8 characters"); if (form.newPassword !== form.confirmPassword) return toast.error("New passwords do not match"); mutation.mutate(); };
  return <><PageHeader title="Profile & Settings" description="Your CRM identity and account security."/><div className="grid gap-5 lg:grid-cols-2"><Card><CardHeader><CardTitle className="flex items-center gap-2"><UserRound size={19}/>Executive Profile</CardTitle></CardHeader><CardContent className="space-y-4"><div className="grid gap-3 sm:grid-cols-2">{[["Name",user?.executiveName],["Executive Code",user?.executiveCode],["Designation",user?.designation],["Mobile",user?.mobile],["Profile",user?.profileName || user?.profileCode],["Level",`L${user?.profileRank ?? "—"}`]].map(([k,v])=><div key={k} className="rounded-xl bg-slate-50 p-3 dark:bg-slate-800"><p className="text-xs uppercase text-slate-400">{k}</p><p className="mt-1 font-semibold">{v || "—"}</p></div>)}</div><div className="flex gap-2"><Badge tone={user?.approvalEnabled ? "green":"slate"}>{user?.approvalEnabled ? "Approval Enabled":"Request-only"}</Badge>{user?.isAdmin && <Badge tone="purple"><ShieldCheck size={12}/>Admin</Badge>}</div></CardContent></Card><Card><CardHeader><CardTitle className="flex items-center gap-2"><KeyRound size={19}/>Change Password</CardTitle></CardHeader><CardContent className="space-y-3"><Input type="password" placeholder="Current password" value={form.currentPassword} onChange={(e)=>setForm(f=>({...f,currentPassword:e.target.value}))}/><Input type="password" placeholder="New password (min 8 characters)" value={form.newPassword} onChange={(e)=>setForm(f=>({...f,newPassword:e.target.value}))}/><Input type="password" placeholder="Confirm new password" value={form.confirmPassword} onChange={(e)=>setForm(f=>({...f,confirmPassword:e.target.value}))}/><Button variant="primary" className="w-full" disabled={mutation.isPending} onClick={submit}>{mutation.isPending ? "Updating…":"Update Password"}</Button></CardContent></Card></div></>;
}
