import { useEffect, useMemo } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { ArrowLeft, Save } from "lucide-react";
import { toast } from "sonner";
import { customerApi } from "@/api/crmApi";
import { customerSchema } from "@/schemas/customerSchemas";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import { FormField } from "@/components/common/FormField";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { getErrorMessage } from "@/utils/errors";

const empty = { customerType: "SCHOOL", customerName: "", address: "", cityId: "", pincode: "", customerStatus: "ACTIVE", refCode: "", email: "", mobile: "", keyCustomer: false, latitude: "", longitude: "", gstNumber: "", panNumber: "", school: { boardId: "", chainSchoolId: "", startClassId: "", endClassId: "", mediumInstruction: "English", ranking: "", samplingMonth: "", decisionMonth: "", purchaseModeId: "" } };

export default function CustomerFormPage() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const master = useQuery({ queryKey: ["customer-master"], queryFn: customerApi.masterData });
  const cities = useQuery({ queryKey: ["customer-cities"], queryFn: customerApi.cities });
  const existing = useQuery({ queryKey: ["customer", id], queryFn: () => customerApi.get(id), enabled: isEdit });
  const defaults = useMemo(() => ({ ...empty, customerType: searchParams.get("type") || "SCHOOL" }), [searchParams]);
  const { register, handleSubmit, reset, watch, formState: { errors } } = useForm({ resolver: zodResolver(customerSchema), defaultValues: defaults });
  const type = watch("customerType");

  useEffect(() => {
    if (!existing.data) return;
    const c = existing.data.customer;
    reset({
      customerType: c.customer_type, customerName: c.customer_name || "", address: c.address || "", cityId: c.city_id || "", pincode: c.pincode || "", customerStatus: c.customer_status || "ACTIVE", refCode: c.ref_code || "", email: c.email || "", mobile: c.mobile || "", keyCustomer: Boolean(c.key_customer), latitude: c.latitude || "", longitude: c.longitude || "", gstNumber: c.gst_number || "", panNumber: c.pan_number || "",
      school: existing.data.school ? { boardId: existing.data.school.board_id || "", chainSchoolId: existing.data.school.chain_school_id || "", startClassId: existing.data.school.start_class_id || "", endClassId: existing.data.school.end_class_id || "", mediumInstruction: existing.data.school.medium_instruction || "", ranking: existing.data.school.ranking || "", samplingMonth: existing.data.school.sampling_month || "", decisionMonth: existing.data.school.decision_month || "", purchaseModeId: existing.data.school.purchase_mode_id || "" } : empty.school,
    });
  }, [existing.data, reset]);

  const mutation = useMutation({ mutationFn: (payload) => isEdit ? customerApi.update(id, payload) : customerApi.create(payload), onSuccess: (resp) => { toast.success(resp.message || (isEdit ? "Update request submitted" : "Customer created")); qc.invalidateQueries({ queryKey: ["customers"] }); navigate(isEdit ? `/customers/${id}` : `/customers/${resp.customerId}`); }, onError: (e) => toast.error(getErrorMessage(e)) });
  const isLoading = master.isLoading || cities.isLoading || existing.isLoading;
  if (isLoading) return <LoadingState/>;
  const md = master.data || {};

  return <>
    <PageHeader title={isEdit ? "Update Customer" : `Create ${type === "SCHOOL" ? "School" : "Customer"}`} description={isEdit ? "Non-admin changes are staged for approval before they affect live customer data." : "Create a CRM customer. Approval is automatically applied according to the logged-in profile."} actions={<Button variant="outline" onClick={() => navigate(-1)}><ArrowLeft size={16}/>Back</Button>}/>
    <form onSubmit={handleSubmit((v) => mutation.mutate(v))} className="space-y-5">
      <Card><CardHeader><CardTitle>Customer Details</CardTitle></CardHeader><CardContent className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <FormField label="Customer Type" required error={errors.customerType?.message}><Select {...register("customerType")}><option value="SCHOOL">School</option><option value="TRADE">Trade</option><option value="LIBRARY">Library</option><option value="INSTITUTE">Institute</option></Select></FormField>
        <FormField label="Customer Name" required error={errors.customerName?.message}><Input {...register("customerName")}/></FormField>
        <FormField label="Reference Code"><Input {...register("refCode")}/></FormField>
        <FormField label="Mobile"><Input {...register("mobile")}/></FormField>
        <FormField label="Email" error={errors.email?.message}><Input {...register("email")}/></FormField>
        <FormField label="Status"><Select {...register("customerStatus")}><option value="ACTIVE">Active</option><option value="INACTIVE">Inactive</option></Select></FormField>
        <FormField label="City" required error={errors.cityId?.message}><Select {...register("cityId")}><option value="">Select city</option>{(cities.data?.cities || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select></FormField>
        <FormField label="Pincode" required error={errors.pincode?.message}><Input {...register("pincode")}/></FormField>
        <FormField label="GST Number"><Input {...register("gstNumber")}/></FormField>
        <FormField label="PAN Number"><Input {...register("panNumber")}/></FormField>
        <FormField label="Latitude"><Input type="number" step="any" {...register("latitude")}/></FormField>
        <FormField label="Longitude"><Input type="number" step="any" {...register("longitude")}/></FormField>
        <FormField className="md:col-span-2 xl:col-span-3" label="Address" required error={errors.address?.message}><Textarea {...register("address")}/></FormField>
        <label className="flex items-center gap-2 text-sm font-medium"><Checkbox {...register("keyCustomer")}/>Key Customer</label>
      </CardContent></Card>
      {type === "SCHOOL" && <Card><CardHeader><CardTitle>School Details</CardTitle></CardHeader><CardContent className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <FormField label="Board"><Select {...register("school.boardId")}><option value="">Select board</option>{(md.boards || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select></FormField>
        <FormField label="Chain School"><Select {...register("school.chainSchoolId")}><option value="">None</option>{(md.chainSchools || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select></FormField>
        <FormField label="Start Class"><Select {...register("school.startClassId")}><option value="">Select</option>{(md.classes || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select></FormField>
        <FormField label="End Class"><Select {...register("school.endClassId")}><option value="">Select</option>{(md.classes || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select></FormField>
        <FormField label="Medium"><Input {...register("school.mediumInstruction")}/></FormField>
        <FormField label="Ranking"><Input {...register("school.ranking")}/></FormField>
        <FormField label="Sampling Month"><Input type="number" min="1" max="12" {...register("school.samplingMonth")}/></FormField>
        <FormField label="Decision Month"><Input type="number" min="1" max="12" {...register("school.decisionMonth")}/></FormField>
        <FormField label="Purchase Mode"><Select {...register("school.purchaseModeId")}><option value="">Select</option>{(md.purchaseModes || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select></FormField>
      </CardContent></Card>}
      <div className="flex justify-end gap-2"><Button type="button" variant="outline" onClick={() => navigate(-1)}>Cancel</Button><Button type="submit" variant="primary" disabled={mutation.isPending}><Save size={16}/>{mutation.isPending ? "Saving…" : isEdit ? "Submit Update Request" : "Create Customer"}</Button></div>
    </form>
  </>;
}
