import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { Search } from "lucide-react";
import { customerApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import { WorkflowSection } from "@/components/parity/WorkflowSection";
import { FormField } from "@/components/common/FormField";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";

export function samplingTypeInfo(customerType = "SCHOOL") {
  const type = String(customerType || "SCHOOL").toUpperCase();
  if (type === "TRADE")
    return {
      type,
      label: "Trade",
      slug: "trade",
      contactLabel: "Contact Name",
    };
  if (type === "LIBRARY")
    return {
      type,
      label: "Library",
      slug: "library",
      contactLabel: "Contact Name",
    };
  return {
    type: "SCHOOL",
    label: "School",
    slug: "school",
    contactLabel: "Principal / Teacher Name",
  };
}

function setupFlag(setup, key) {
  const value = setup?.[key];
  return (
    value === true ||
    value === 1 ||
    String(value || "").toLowerCase() === "true" ||
    String(value || "") === "1"
  );
}

export default function SamplingSearchPage({ customerType = "SCHOOL" }) {
  const nav = useNavigate();
  const info = samplingTypeInfo(customerType);
  const setup = useSelector((s) => s.auth.applicationSetup) || {};
  const [customerName, setCustomerName] = useState("");
  const [customerCode, setCustomerCode] = useState("");
  const [contactName, setContactName] = useState("");
  const [cityId, setCityId] = useState("");
  const cities = useQuery({
    queryKey: ["customer-search-cities", "sampling", info.type],
    queryFn: customerApi.cities,
  });
  const cityRows = useMemo(() => cities.data?.cities || [], [cities.data]);
  const required = {
    name: setupFlag(setup, "CustomerNameRequired"),
    code: setupFlag(setup, "CustomerCodeRequired"),
    city: setupFlag(setup, "CityRequired"),
  };

  function search() {
    if (required.name && !customerName.trim())
      return toast.error("Customer Name is required");
    if (required.code && !customerCode.trim())
      return toast.error("Customer Code is required");
    if (required.city && !cityId)
      return toast.error("Please select a valid city");
    const sp = new URLSearchParams();
    const values = {
      customerType: info.type,
      customerName: customerName.trim(),
      customerCode: customerCode.trim(),
      contactName: contactName.trim(),
      cityId,
    };
    Object.entries(values).forEach(([k, v]) => {
      if (v != null && String(v).trim() !== "") sp.set(k, String(v));
    });
    nav(`/sampling/${info.slug}/results?${sp.toString()}`);
  }

  return (
    <>
      <PageHeader
        title={`${info.label} Sampling - Search`}
        description={`Same ${info.label.toLowerCase()} sampling search flow as the Flutter CRM.`}
      />
      <WorkflowSection title="Customer Details">
        <div className="grid gap-4 md:grid-cols-2">
          <FormField label="Customer Name" required={required.name}>
            <Input
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              placeholder="Customer Name"
            />
          </FormField>
          <FormField label="Customer Code" required={required.code}>
            <Input
              value={customerCode}
              onChange={(e) => setCustomerCode(e.target.value)}
              placeholder="Customer Code"
            />
          </FormField>
          <FormField label={info.contactLabel}>
            <Input
              value={contactName}
              onChange={(e) => setContactName(e.target.value)}
              placeholder={info.contactLabel}
            />
          </FormField>
        </div>
        <div className="my-5 border-t border-slate-200 dark:border-slate-800" />
        <h3 className="mb-4 text-sm font-bold text-slate-700 dark:text-slate-200">
          Location
        </h3>
        <div className="max-w-xl">
          <FormField label="City" required={required.city}>
            <Select value={cityId} onChange={(e) => setCityId(e.target.value)}>
              <option value="">--Select City--</option>
              {cityRows.map((x) => (
                <option key={x.id} value={x.id}>
                  {x.name}
                </option>
              ))}
            </Select>
          </FormField>
        </div>
        <div className="mt-6 flex justify-center">
          <Button
            type="button"
            variant="primary"
            className="min-w-36"
            onClick={search}
          >
            <Search size={16} />
            Search
          </Button>
        </div>
      </WorkflowSection>
    </>
  );
}
