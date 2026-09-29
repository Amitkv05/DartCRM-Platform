import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { eProductApi } from "@/api/crmApi";
import { WorkflowSection, EmptyMessage } from "@/components/parity/WorkflowSection";
import { FormField } from "@/components/common/FormField";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";

export default function EProductPanel({ dsr, customerId, academicSessionId, rows, onChange }) {
  const [brandId, setBrandId] = useState("");
  const [productId, setProductId] = useState("");
  const [stageId, setStageId] = useState("");
  const [prospectId, setProspectId] = useState("");
  const [classIds, setClassIds] = useState([]);
  const [remarks, setRemarks] = useState("");
  const products = useQuery({ queryKey: ["e-products", brandId], queryFn: () => eProductApi.productsByBrand(brandId), enabled: Boolean(brandId) });
  const detail = useQuery({ queryKey: ["e-product-detail", productId, academicSessionId, customerId], queryFn: () => eProductApi.details(productId, { academicSessionId, customerId }), enabled: Boolean(productId && academicSessionId && customerId) });
  const add = () => {
    if (!brandId || !productId || !stageId || !prospectId) return toast.error("Brand, product, sales stage and prospect are required");
    const p=(products.data?.productList||[]).find((x)=>Number(x.id)===Number(productId));
    const b=(dsr?.brands||[]).find((x)=>Number(x.id)===Number(brandId));
    const s=(dsr?.salesStage||[]).find((x)=>Number(x.id)===Number(stageId));
    const pr=(dsr?.prospects||[]).find((x)=>Number(x.id)===Number(prospectId));
    onChange([...rows,{ brandId:Number(brandId),eProductId:Number(productId),salesStageId:Number(stageId),prospectId:Number(prospectId),classIds:classIds.map(Number),remarks:remarks||null,_brand:b?.brand_name,_product:p?.product_name,_stage:s?.stage_name,_prospect:pr?.prospect_name }]);
    setProductId(""); setStageId(""); setProspectId(""); setClassIds([]); setRemarks("");
  };
  return <WorkflowSection title="E-Product Promotion"><div className="space-y-4">
    <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4"><FormField label="Brand" required><Select value={brandId} onChange={(e)=>{setBrandId(e.target.value);setProductId("");setClassIds([]);}}><option value="">--Select--</option>{(dsr?.brands||[]).map(x=><option key={x.id} value={x.id}>{x.brand_name}</option>)}</Select></FormField><FormField label="Product" required><Select value={productId} onChange={(e)=>{setProductId(e.target.value);setClassIds([]);}}><option value="">--Select--</option>{(products.data?.productList||[]).map(x=><option key={x.id} value={x.id}>{x.product_name}</option>)}</Select></FormField><FormField label="Sales Stage" required><Select value={stageId} onChange={(e)=>setStageId(e.target.value)}><option value="">--Select--</option>{(dsr?.salesStage||[]).map(x=><option key={x.id} value={x.id}>{x.stage_name}</option>)}</Select></FormField><FormField label="Prospect" required><Select value={prospectId} onChange={(e)=>setProspectId(e.target.value)}><option value="">--Select--</option>{(dsr?.prospects||[]).map(x=><option key={x.id} value={x.id}>{x.prospect_name}</option>)}</Select></FormField></div>
    {(detail.data?.previousSalesStage || detail.data?.previous_sales_stage) && <div className="rounded-lg bg-slate-50 p-3 text-sm dark:bg-slate-800"><b>Previous Sales Stage:</b> {detail.data.previousSalesStage?.stageName || detail.data.previous_sales_stage}</div>}
    {(detail.data?.classes||[]).length>0&&<div><p className="mb-2 text-sm font-semibold">Classes</p><div className="flex flex-wrap gap-2">{detail.data.classes.map(c=><label key={c.classNumId??c.class_num_id} className="flex items-center gap-2 rounded-lg border px-3 py-2 text-sm dark:border-slate-700"><Checkbox checked={classIds.includes(c.classNumId??c.class_num_id)} onChange={(e)=>{const id=c.classNumId??c.class_num_id;setClassIds(v=>e.target.checked?[...v,id]:v.filter(x=>x!==id));}}/>{c.className??c.class_name}</label>)}</div></div>}
    <div className="grid gap-3 md:grid-cols-[1fr_auto]"><FormField label="Remarks"><Textarea className="min-h-20" value={remarks} onChange={(e)=>setRemarks(e.target.value)}/></FormField><Button className="self-end" type="button" variant="outline" onClick={add}><Plus size={15}/>Add Product</Button></div>
    {!rows.length?<EmptyMessage>No E-Products added.</EmptyMessage>:<div className="space-y-2">{rows.map((r,i)=><div key={`${r.eProductId}-${i}`} className="flex items-center justify-between rounded-lg border p-3 text-sm dark:border-slate-800"><div><p className="font-semibold">{r._brand} · {r._product}</p><p className="text-xs text-slate-500">{r._stage} · {r._prospect} · {r.classIds.length} class(es)</p></div><Button type="button" size="icon" variant="ghost" className="text-red-600" onClick={()=>onChange(rows.filter((_,idx)=>idx!==i))}><Trash2 size={15}/></Button></div>)}</div>}
  </div></WorkflowSection>;
}
