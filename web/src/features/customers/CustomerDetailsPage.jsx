import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import { ArrowLeft, MapPin, Mail, Phone, Pencil, Plus, Trash2, UserRound } from "lucide-react";
import { toast } from "sonner";
import { customerApi, contactApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import StatusBadge from "@/components/common/StatusBadge";
import ConfirmDialog from "@/components/common/ConfirmDialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import ContactDialog from "@/features/customers/ContactDialog";
import { getErrorMessage } from "@/utils/errors";

function Info({ label, children }) { return <div><p className="text-xs font-semibold uppercase tracking-wide text-slate-400">{label}</p><div className="mt-1 text-sm font-medium text-slate-800 dark:text-slate-200">{children || "—"}</div></div>; }

export default function CustomerDetailsPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [searchParams, setSearchParams] = useSearchParams();
  const [contactOpen, setContactOpen] = useState(false);
  const [editingContact, setEditingContact] = useState(null);
  const [deleteOpen, setDeleteOpen] = useState(searchParams.get("delete") === "1");
  const query = useQuery({ queryKey: ["customer", id], queryFn: () => customerApi.get(id) });
  const master = useQuery({ queryKey: ["customer-master"], queryFn: customerApi.masterData });
  useEffect(() => { if (searchParams.get("delete") === "1") setDeleteOpen(true); }, [searchParams]);
  const deleteMutation = useMutation({ mutationFn: () => customerApi.requestDelete(id), onSuccess: (r) => { toast.success(r.message); setDeleteOpen(false); setSearchParams({}); qc.invalidateQueries({ queryKey: ["customer", id] }); qc.invalidateQueries({ queryKey: ["customers"] }); }, onError: (e) => toast.error(getErrorMessage(e)) });
  const contactDelete = useMutation({ mutationFn: (contactId) => contactApi.delete(contactId), onSuccess: () => { toast.success("Contact removed"); qc.invalidateQueries({ queryKey: ["customer", id] }); }, onError: (e) => toast.error(getErrorMessage(e)) });
  if (query.isLoading) return <LoadingState/>;
  if (query.isError) return <ErrorState error={query.error} onRetry={query.refetch}/>;
  const { customer, contacts = [], categories = [], executives = [], school } = query.data;

  return <>
    <PageHeader title={customer.customer_name} description={`${customer.customer_code || "No code"} · ${customer.customer_type}`} actions={<><Button variant="outline" onClick={() => navigate(-1)}><ArrowLeft size={16}/>Back</Button><Button variant="outline" onClick={() => navigate(`/customers/${id}/edit`)}><Pencil size={16}/>Update</Button><Button variant="danger" onClick={() => setDeleteOpen(true)}><Trash2 size={16}/>Delete Request</Button></>}/>
    <div className="grid gap-5 xl:grid-cols-[1.2fr_.8fr]">
      <Card><CardHeader className="flex-row items-center justify-between"><CardTitle>Customer Profile</CardTitle><div className="flex gap-2"><StatusBadge status={customer.validation_status}/><StatusBadge status={customer.customer_status}/></div></CardHeader><CardContent className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        <Info label="Reference Code">{customer.ref_code}</Info><Info label="City">{customer.city}</Info><Info label="Pincode">{customer.pincode}</Info><Info label="Mobile"><span className="flex items-center gap-1.5"><Phone size={14}/>{customer.mobile || "—"}</span></Info><Info label="Email"><span className="flex items-center gap-1.5"><Mail size={14}/>{customer.email || "—"}</span></Info><Info label="Key Customer">{customer.key_customer ? "Yes" : "No"}</Info><Info label="Address"><span className="flex gap-1.5"><MapPin size={14} className="mt-0.5 shrink-0"/>{customer.address}</span></Info><Info label="GST">{customer.gst_number}</Info><Info label="PAN">{customer.pan_number}</Info>
        {categories.length > 0 && <div className="sm:col-span-2 lg:col-span-3"><p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Categories</p><div className="flex flex-wrap gap-2">{categories.map((x) => <Badge key={x.id} tone="blue">{x.name}</Badge>)}</div></div>}
        {executives.length > 0 && <div className="sm:col-span-2 lg:col-span-3"><p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Assigned Executives</p><div className="flex flex-wrap gap-2">{executives.map((x) => <Badge key={x.id}>{x.executive_name}</Badge>)}</div></div>}
      </CardContent></Card>
      <Card><CardHeader><CardTitle>{customer.customer_type === "SCHOOL" ? "School Details" : "Account Status"}</CardTitle></CardHeader><CardContent className="space-y-4">{school ? <div className="grid gap-4 sm:grid-cols-2"><Info label="Board">{school.board_name || school.board_id}</Info><Info label="Class Range">{school.start_class_num_id ?? school.start_class_id} → {school.end_class_num_id ?? school.end_class_id}</Info><Info label="Medium">{school.medium_instruction}</Info><Info label="Ranking">{school.ranking}</Info><Info label="Sampling Month">{school.sampling_month}</Info><Info label="Decision Month">{school.decision_month}</Info></div> : <><Info label="Delete Request"><StatusBadge status={customer.delete_request_status || "NONE"}/></Info><Info label="Created By">Executive #{customer.created_by_executive_id || "—"}</Info></>}</CardContent></Card>
    </div>
    <Card className="mt-5"><CardHeader className="flex-row items-center justify-between"><div><CardTitle>Contacts</CardTitle><p className="mt-1 text-sm text-slate-500">Contacts can follow the backend approval rules for the logged-in profile.</p></div><Button variant="primary" size="sm" onClick={() => { setEditingContact(null); setContactOpen(true); }}><Plus size={15}/>Add Contact</Button></CardHeader><CardContent>{contacts.length ? <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">{contacts.map((c) => <div key={c.id} className="rounded-xl border border-slate-200 p-4 dark:border-slate-800"><div className="flex items-start justify-between"><div className="flex items-center gap-3"><div className="rounded-full bg-brand-50 p-2.5 text-brand-700 dark:bg-brand-950/50"><UserRound size={18}/></div><div><p className="font-semibold">{[c.first_name,c.last_name].filter(Boolean).join(" ") || "Unnamed Contact"}</p><p className="text-xs text-slate-500">{c.designation || c.designation_id || "Contact"}</p></div></div><StatusBadge status={c.validation_status}/></div><div className="mt-4 space-y-1 text-sm text-slate-600 dark:text-slate-300"><p>{c.mobile || "No mobile"}</p><p>{c.email || "No email"}</p></div><div className="mt-4 flex justify-end gap-1"><Button variant="ghost" size="sm" onClick={() => { setEditingContact(c); setContactOpen(true); }}><Pencil size={14}/>Edit</Button><Button variant="ghost" size="sm" className="text-red-600" onClick={() => { if (confirm("Delete this contact?")) contactDelete.mutate(c.id); }}><Trash2 size={14}/></Button></div></div>)}</div> : <p className="py-10 text-center text-sm text-slate-500">No contacts available for this customer.</p>}</CardContent></Card>
    <ContactDialog open={contactOpen} onOpenChange={setContactOpen} customer={customer} contact={editingContact} masterData={master.data} onSaved={() => qc.invalidateQueries({ queryKey: ["customer", id] })}/>
    <ConfirmDialog open={deleteOpen} onOpenChange={(v) => { setDeleteOpen(v); if (!v) setSearchParams({}); }} title="Request customer deletion?" description="This does not immediately delete the customer. A CUSTOMER_DELETE approval request will be created according to the hierarchy." confirmLabel="Submit Delete Request" onConfirm={() => deleteMutation.mutate()} loading={deleteMutation.isPending}/>
  </>;
}
