import { useNavigate } from "react-router-dom";
import PageHeader from "@/components/common/PageHeader";
import CustomerSearchForm from "@/components/parity/CustomerSearchForm";

export default function VisitSearchPage() {
  const navigate = useNavigate();
  const submit = (form) => {
    const p = new URLSearchParams();
    Object.entries(form).forEach(([k, v]) => { if (v != null && String(v).trim() !== "") p.set(k, String(v)); });
    navigate(`/visits/search-results?${p.toString()}`);
  };
  return <><PageHeader title="School Visit" description="Search the customer first, then open the same Visit / DSR entry flow used by the Flutter CRM."/><CustomerSearchForm title="School Visit - Search" customerType="SCHOOL" contactLabel="Principal / Teacher Name" showContact={false} onSearch={submit}/></>;
}
