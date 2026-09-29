import { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { catalogApi, samplingApi } from "@/api/crmApi";
import ParityBookTabs from "@/components/parity/ParityBookTabs";
import SamplingContainers from "@/components/parity/SamplingContainers";
import { WorkflowSection } from "@/components/parity/WorkflowSection";
import { FormField } from "@/components/common/FormField";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";

export default function VisitSamplingPanel({ customerId, value, onChange }) {
  const details=useQuery({queryKey:["visit-sampling-details",customerId],queryFn:()=>samplingApi.details({customerId}),enabled:Boolean(customerId)});
  const modes=useQuery({queryKey:["shipment-modes"],queryFn:catalogApi.shipmentModes});
  useEffect(()=>{const first=modes.data?.shipmentModes?.[0];if(first&&!value.shipmentModeId)onChange({...value,shipmentModeId:String(first.shipment_mode_id)});},[modes.data,value,onChange]);
  const maxQty=Number(details.data?.titles?.[0]?.max_sampling_qty||10);
  return <WorkflowSection title="Sampling Done"><div className="space-y-5">
    <ParityBookTabs items={value.items||[]} onChange={(items)=>onChange({...value,items})} maxQty={maxQty}/>
    {(value.items||[]).length>0&&<SamplingContainers customerId={customerId} items={value.items||[]} settings={value.containerSettings||{}} onChange={(containerSettings)=>onChange({...value,containerSettings})} samplingTypes={details.data?.samplingTypes||[]} sampleGivenOptions={details.data?.sampleGiven||[]} sampleToOptions={details.data?.sampleTo||[]}/>} 
    <div className="grid gap-4 md:grid-cols-2">
      <FormField label="Shipment Mode" required><Select value={value.shipmentModeId||""} onChange={e=>onChange({...value,shipmentModeId:e.target.value})}><option value="">--Select--</option>{(modes.data?.shipmentModes||[]).map(x=><option key={x.shipment_mode_id} value={x.shipment_mode_id}>{x.shipment_mode}</option>)}</Select></FormField><div/>
      <FormField label="Shipping Instructions"><Textarea className="min-h-20" value={value.shippingInstructions||""} onChange={e=>onChange({...value,shippingInstructions:e.target.value})}/></FormField>
      <FormField label="Remarks"><Textarea className="min-h-20" value={value.requestRemarks||""} onChange={e=>onChange({...value,requestRemarks:e.target.value})}/></FormField>
    </div>
  </div></WorkflowSection>;
}
