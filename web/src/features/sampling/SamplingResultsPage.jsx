import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import { contactApi, customerApi, setupApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import CustomerResultsTable from "@/components/parity/CustomerResultsTable";
import { customerRow } from "@/utils/parity";
import { samplingTypeInfo } from "@/features/sampling/SamplingSearchPage";

export default function SamplingResultsPage() {
  const nav = useNavigate();
  const { type: routeType } = useParams();
  const [sp] = useSearchParams();
  const info = samplingTypeInfo(routeType);
  const contactName = String(sp.get("contactName") || "").trim().toLowerCase();
  const customers = useQuery({ queryKey:["sampling-search", info.type], queryFn:()=>customerApi.list({customerType:info.type,validationStatus:"VALIDATED"}) });
  const geography = useQuery({ queryKey:["geography","sampling-results"], queryFn:()=>setupApi.geography() });

  const prelim = useMemo(()=>{
    const cityMeta = new Map((geography.data?.geography || []).map((g)=>[Number(g.city_id),g]));
    const name=String(sp.get("customerName")||"").trim().toLowerCase();
    const code=String(sp.get("customerCode")||"").trim().toLowerCase();
    const cityId=Number(sp.get("cityId")||0); const districtId=Number(sp.get("districtId")||0); const stateId=Number(sp.get("stateId")||0); const countryId=Number(sp.get("countryId")||0);
    return (customers.data?.customers||[]).map((raw)=>{const row=customerRow(raw);const g=cityMeta.get(row.cityId);return {...row,city:row.city||g?.city||"",state:row.state||g?.state||"",_geo:g};}).filter((x)=>{
      if(name&&!x.name.toLowerCase().includes(name))return false;
      if(code&&!`${x.code} ${x.refCode}`.toLowerCase().includes(code))return false;
      if(cityId&&x.cityId!==cityId)return false;
      if(districtId&&Number(x._geo?.district_id)!==districtId)return false;
      if(stateId&&Number(x._geo?.state_id)!==stateId)return false;
      if(countryId&&Number(x._geo?.country_id)!==countryId)return false;
      return true;
    });
  },[customers.data,geography.data,sp]);

  const contactMatches = useQuery({
    queryKey:["sampling-contact-search",info.type,contactName,prelim.map(x=>x.id).join(",")],
    enabled:Boolean(contactName&&prelim.length),
    queryFn:async()=>{
      const matches=[];
      for(const row of prelim){
        try{
          const r=await contactApi.list(row.id); const contacts=r?.contacts||[];
          if(contacts.some(c=>`${c.first_name||""} ${c.last_name||""} ${c.email||""} ${c.mobile||""}`.toLowerCase().includes(contactName))) matches.push(row.id);
        } catch { /* keep search resilient */ }
      }
      return matches;
    }
  });
  const rows=contactName?(contactMatches.data?prelim.filter(x=>contactMatches.data.includes(x.id)):[]):prelim;
  if(customers.isLoading||geography.isLoading||(contactName&&contactMatches.isLoading))return <LoadingState/>;
  if(customers.isError)return <ErrorState error={customers.error}/>;
  return <>
    <PageHeader title={`${info.label} Sampling`} description={`Select a ${info.label.toLowerCase()} to enter the customer sampling request.`}/>
    <CustomerResultsTable title={`${info.label} Sampling - List`} rows={rows} onBackToSearch={()=>nav(`/sampling/${info.slug}`)} onRowClick={(row)=>nav(`/sampling/${info.slug}/customer/${row.id}`)}/>
  </>;
}
