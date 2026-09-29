import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { CheckCircle2, Clock3, LocateFixed, LogIn, LogOut } from "lucide-react";
import { toast } from "sonner";
import { attendanceApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { formatDateTime } from "@/utils/format";
import { getErrorMessage } from "@/utils/errors";

function getPosition() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) return reject(new Error("Geolocation is not supported by this browser"));
    navigator.geolocation.getCurrentPosition((p) => resolve({ latitude: p.coords.latitude, longitude: p.coords.longitude }), reject, { enableHighAccuracy: true, timeout: 15000 });
  });
}

export default function AttendancePage() {
  const qc = useQueryClient();
  const [address, setAddress] = useState("");
  const q = useQuery({ queryKey: ["attendance", "today"], queryFn: attendanceApi.today });
  const action = useMutation({
    mutationFn: async (type) => { const coords = await getPosition(); return type === "in" ? attendanceApi.checkIn({ ...coords, address: address || undefined }) : attendanceApi.checkOut({ ...coords, address: address || undefined }); },
    onSuccess: (r) => { toast.success(r.message); qc.invalidateQueries({ queryKey: ["attendance"] }); },
    onError: (e) => toast.error(getErrorMessage(e)),
  });
  if (q.isLoading) return <LoadingState/>;
  if (q.isError) return <ErrorState error={q.error} onRetry={q.refetch}/>;
  const a = q.data?.attendance;
  return <>
    <PageHeader title="Attendance" description="GPS-backed daily check-in and checkout from your browser."/>
    <div className="grid gap-5 lg:grid-cols-[1fr_.8fr]">
      <Card><CardHeader><CardTitle>Today's Status</CardTitle></CardHeader><CardContent>
        <div className="grid gap-4 sm:grid-cols-2"><div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5 dark:border-emerald-900 dark:bg-emerald-950/30"><div className="flex items-center gap-2 text-emerald-700"><LogIn size={20}/><b>Check In</b></div><p className="mt-4 text-lg font-black">{a?.check_in_at ? formatDateTime(a.check_in_at) : "Not checked in"}</p><p className="mt-1 text-xs text-slate-500">{a?.check_in_address || "Location address not provided"}</p></div><div className="rounded-2xl border border-blue-100 bg-blue-50 p-5 dark:border-blue-900 dark:bg-blue-950/30"><div className="flex items-center gap-2 text-brand-700"><LogOut size={20}/><b>Check Out</b></div><p className="mt-4 text-lg font-black">{a?.check_out_at ? formatDateTime(a.check_out_at) : "Not checked out"}</p><p className="mt-1 text-xs text-slate-500">{a?.check_out_address || "Location address not provided"}</p></div></div>
      </CardContent></Card>
      <Card><CardHeader><CardTitle className="flex items-center gap-2"><LocateFixed size={18}/>Attendance Action</CardTitle></CardHeader><CardContent className="space-y-4"><p className="text-sm text-slate-500">Allow browser location access. Coordinates are captured only when you press an attendance action.</p><div><p className="mb-1.5 text-sm font-semibold">Address / Landmark (optional)</p><Input value={address} onChange={(e) => setAddress(e.target.value)} placeholder="Office, customer site, landmark…"/></div>{!a?.check_in_at ? <Button className="w-full" variant="primary" disabled={action.isPending} onClick={() => action.mutate("in")}><CheckCircle2 size={17}/>Check In</Button> : !a?.check_out_at ? <Button className="w-full" variant="primary" disabled={action.isPending} onClick={() => action.mutate("out")}><Clock3 size={17}/>Check Out</Button> : <div className="rounded-xl bg-emerald-50 p-4 text-center text-sm font-semibold text-emerald-700 dark:bg-emerald-950/30">Attendance completed for today.</div>}</CardContent></Card>
    </div>
  </>;
}
