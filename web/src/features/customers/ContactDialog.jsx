import { useEffect } from "react";
import { useMutation } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { contactApi } from "@/api/crmApi";
import { contactSchema } from "@/schemas/customerSchemas";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "@/components/ui/dialog";
import { FormField } from "@/components/common/FormField";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Button } from "@/components/ui/button";
import { getErrorMessage } from "@/utils/errors";

const defaults = { firstName: "", lastName: "", designationId: "", salutationId: "", email: "", mobile: "", contactStatus: "ACTIVE", primaryContact: false, residentialAddress: "", residentialCityId: "", residentialPincode: "", birthday: "", anniversary: "", dataSourceId: "" };
export default function ContactDialog({ open, onOpenChange, customer, contact, masterData = {}, onSaved }) {
  const { register, handleSubmit, reset, formState: { errors } } = useForm({ resolver: zodResolver(contactSchema), defaultValues: defaults });
  useEffect(() => { if (!open) return; reset(contact ? { firstName: contact.first_name || "", lastName: contact.last_name || "", designationId: contact.designation_id || "", salutationId: contact.salutation_id || "", email: contact.email || "", mobile: contact.mobile || "", contactStatus: contact.contact_status || "ACTIVE", primaryContact: Boolean(contact.primary_contact), residentialAddress: contact.residential_address || "", residentialCityId: contact.residential_city_id || "", residentialPincode: contact.residential_pincode || "", birthday: contact.birthday?.slice?.(0,10) || "", anniversary: contact.anniversary?.slice?.(0,10) || "", dataSourceId: contact.data_source_id || "" } : defaults); }, [open, contact, reset]);
  const mutation = useMutation({ mutationFn: (values) => { const payload = { ...values, customerId: customer.id, customerType: customer.customer_type }; return contact ? contactApi.update(contact.id, payload) : contactApi.create(payload); }, onSuccess: (r) => { toast.success(r.message || (contact ? "Contact updated" : "Contact submitted")); onSaved?.(); onOpenChange(false); }, onError: (e) => toast.error(getErrorMessage(e)) });
  return <Dialog open={open} onOpenChange={onOpenChange}><DialogContent><DialogTitle>{contact ? "Edit Contact" : "Add Contact"}</DialogTitle><DialogDescription>{contact ? "Update the selected customer contact." : "Create a contact. It may require approval based on your CRM profile."}</DialogDescription><form className="mt-5 grid gap-4 sm:grid-cols-2" onSubmit={handleSubmit((v) => mutation.mutate(v))}>
    <FormField label="Salutation"><Select {...register("salutationId")}><option value="">Select</option>{(masterData?.salutations || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select></FormField>
    <FormField label="Designation" required error={errors.designationId?.message}><Select {...register("designationId")}><option value="">Select</option>{(masterData?.contactDesignations || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select></FormField>
    <FormField label="First Name" required error={errors.firstName?.message}><Input {...register("firstName")}/></FormField><FormField label="Last Name"><Input {...register("lastName")}/></FormField>
    <FormField label="Mobile"><Input {...register("mobile")}/></FormField><FormField label="Email" error={errors.email?.message}><Input {...register("email")}/></FormField>
    <FormField label="Status"><Select {...register("contactStatus")}><option value="ACTIVE">Active</option><option value="INACTIVE">Inactive</option></Select></FormField>
    <FormField label="Data Source"><Select {...register("dataSourceId")}><option value="">Select</option>{(masterData?.dataSources || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select></FormField>
    <FormField className="sm:col-span-2" label="Residential Address"><Textarea {...register("residentialAddress")}/></FormField>
    <FormField label="Residential Pincode"><Input {...register("residentialPincode")}/></FormField><FormField label="Birthday"><Input type="date" {...register("birthday")}/></FormField><FormField label="Anniversary"><Input type="date" {...register("anniversary")}/></FormField>
    <label className="flex items-center gap-2 pt-7 text-sm font-semibold"><Checkbox {...register("primaryContact")}/>Primary Contact</label>
    <div className="sm:col-span-2 flex justify-end gap-2 pt-2"><Button type="button" variant="outline" onClick={() => onOpenChange(false)}>Cancel</Button><Button variant="primary" disabled={mutation.isPending}>{mutation.isPending ? "Saving…" : contact ? "Save Contact" : "Submit Contact"}</Button></div>
  </form></DialogContent></Dialog>;
}
