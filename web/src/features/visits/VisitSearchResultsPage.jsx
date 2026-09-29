import { useMemo } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { customerApi, setupApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import CustomerResultsTable from "@/components/parity/CustomerResultsTable";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import { customerRow } from "@/utils/parity";

export default function VisitSearchResultsPage() {
  const nav = useNavigate();
  const [sp] = useSearchParams();
  const type = String(sp.get("customerType") || "SCHOOL").toUpperCase();
  const customers = useQuery({ queryKey: ["visit-search", type], queryFn: () => customerApi.list({ customerType: type, validationStatus: "VALIDATED" }) });
  const geo = useQuery({ queryKey: ["geography", "visit-results"], queryFn: () => setupApi.geography() });
  const rows = useMemo(() => {
    const cityMeta = new Map((geo.data?.geography || []).map((g) => [Number(g.city_id), g]));
    const name = String(sp.get("customerName") || "").trim().toLowerCase();
    const code = String(sp.get("customerCode") || "").trim().toLowerCase();
    const contact = String(sp.get("contactName") || "").trim().toLowerCase();
    const cityId = Number(sp.get("cityId") || 0);
    const districtId = Number(sp.get("districtId") || 0);
    const stateId = Number(sp.get("stateId") || 0);
    const countryId = Number(sp.get("countryId") || 0);
    return (customers.data?.customers || []).map((r) => {
      const x = customerRow(r); const m = cityMeta.get(x.cityId);
      if (!x.state && m?.state) x.state = m.state;
      if (!x.city && m?.city) x.city = m.city;
      return { ...x, _geo: m };
    }).filter((x) => {
      if (name && !x.name.toLowerCase().includes(name)) return false;
      if (code && !`${x.code} ${x.refCode}`.toLowerCase().includes(code)) return false;
      if (contact && x.contactName && !x.contactName.toLowerCase().includes(contact)) return false;
      if (cityId && x.cityId !== cityId) return false;
      if (districtId && Number(x._geo?.district_id) !== districtId) return false;
      if (stateId && Number(x._geo?.state_id) !== stateId) return false;
      if (countryId && Number(x._geo?.country_id) !== countryId) return false;
      return true;
    });
  }, [customers.data, geo.data, sp]);
  if (customers.isLoading || geo.isLoading) return <LoadingState/>;
  if (customers.isError) return <ErrorState error={customers.error}/>;
  return <><PageHeader title="School Visit" description="Select a customer to open the Visit Entry detail screen."/><CustomerResultsTable title="School Visit - List" rows={rows} onBackToSearch={() => nav("/visits/new")} onRowClick={(row) => nav(`/visits/customer/${row.id}`, { state: { customer: row.raw } })}/></>;
}
