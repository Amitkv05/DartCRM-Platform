import { useEffect, useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Search } from "lucide-react";
import { setupApi } from "@/api/crmApi";
import { WorkflowSection } from "@/components/parity/WorkflowSection";
import { FormField } from "@/components/common/FormField";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Button } from "@/components/ui/button";

function uniq(rows, key, label) {
  const seen = new Set();
  return rows.reduce((out, row) => {
    const id = row[key];
    if (id == null || seen.has(String(id))) return out;
    seen.add(String(id));
    out.push({ id: String(id), label: String(row[label] || "") });
    return out;
  }, []);
}

export default function CustomerSearchForm({
  title,
  customerType = "",
  onSearch,
  contactLabel = "Contact Name",
  showContact = true,
  defaultCountry = "India",
}) {
  const [form, setForm] = useState({
    customerName: "",
    customerCode: "",
    countryId: "",
    stateId: "",
    districtId: "",
    cityId: "",
    contactName: "",
  });
  const geo = useQuery({
    queryKey: ["geography", "workflow-search"],
    queryFn: () => setupApi.geography(),
  });
  const rows = useMemo(() => geo.data?.geography || [], [geo.data?.geography]);
  const countries = useMemo(() => uniq(rows, "country_id", "country"), [rows]);
  useEffect(() => {
    if (form.countryId || !defaultCountry || !countries.length) return;
    const match = countries.find(
      (x) => x.label.toLowerCase() === String(defaultCountry).toLowerCase(),
    );
    if (match) setForm((old) => ({ ...old, countryId: match.id }));
  }, [countries, defaultCountry, form.countryId]);
  const states = useMemo(
    () =>
      uniq(
        rows.filter(
          (r) => !form.countryId || String(r.country_id) === form.countryId,
        ),
        "state_id",
        "state",
      ),
    [rows, form.countryId],
  );
  const districts = useMemo(
    () =>
      uniq(
        rows.filter(
          (r) => !form.stateId || String(r.state_id) === form.stateId,
        ),
        "district_id",
        "district",
      ),
    [rows, form.stateId],
  );
  const cities = useMemo(
    () =>
      uniq(
        rows.filter(
          (r) =>
            (!form.stateId || String(r.state_id) === form.stateId) &&
            (!form.districtId || String(r.district_id) === form.districtId),
        ),
        "city_id",
        "city",
      ),
    [rows, form.stateId, form.districtId],
  );

  const patch = (key, value) => setForm((old) => ({ ...old, [key]: value }));

  return (
    <WorkflowSection title={title}>
      <div className="grid gap-x-8 gap-y-4 lg:grid-cols-2">
        <FormField label="Customer Name">
          <Input
            placeholder="Customer Name"
            value={form.customerName}
            onChange={(e) => patch("customerName", e.target.value)}
          />
        </FormField>
        <FormField label="Customer Code / Ref Code">
          <Input
            placeholder="Customer Code / Ref Code"
            value={form.customerCode}
            onChange={(e) => patch("customerCode", e.target.value)}
          />
        </FormField>
        <FormField label="Country Name">
          <Select
            value={form.countryId}
            onChange={(e) =>
              setForm((f) => ({
                ...f,
                countryId: e.target.value,
                stateId: "",
                districtId: "",
                cityId: "",
              }))
            }
          >
            <option value="">--Select--</option>
            {countries.map((x) => (
              <option key={x.id} value={x.id}>
                {x.label}
              </option>
            ))}
          </Select>
        </FormField>
        <FormField
          label="Region Name"
          hint="Region is not a separate master in Backend V4."
        >
          <Select disabled>
            <option>--Not configured--</option>
          </Select>
        </FormField>
        <FormField label="State Name">
          <Select
            value={form.stateId}
            onChange={(e) =>
              setForm((f) => ({
                ...f,
                stateId: e.target.value,
                districtId: "",
                cityId: "",
              }))
            }
          >
            <option value="">--Select--</option>
            {states.map((x) => (
              <option key={x.id} value={x.id}>
                {x.label}
              </option>
            ))}
          </Select>
        </FormField>
        <FormField
          label="Area Name"
          hint="Area is not a separate master in Backend V4."
        >
          <Select disabled>
            <option>--Not configured--</option>
          </Select>
        </FormField>
        <FormField label="District Name">
          <Select
            value={form.districtId}
            onChange={(e) =>
              setForm((f) => ({ ...f, districtId: e.target.value, cityId: "" }))
            }
          >
            <option value="">--Select--</option>
            {districts.map((x) => (
              <option key={x.id} value={x.id}>
                {x.label}
              </option>
            ))}
          </Select>
        </FormField>
        <FormField
          label="Territory Name"
          hint="Access is enforced by the logged-in executive's territory permissions."
        >
          <Select disabled>
            <option>--From account access--</option>
          </Select>
        </FormField>
        <FormField label="City Name">
          <Select
            value={form.cityId}
            onChange={(e) => patch("cityId", e.target.value)}
          >
            <option value="">--Select--</option>
            {cities.map((x) => (
              <option key={x.id} value={x.id}>
                {x.label}
              </option>
            ))}
          </Select>
        </FormField>
        {showContact ? (
          <FormField label={contactLabel}>
            <Input
              placeholder={contactLabel}
              value={form.contactName}
              onChange={(e) => patch("contactName", e.target.value)}
            />
          </FormField>
        ) : null}
      </div>
      <div className="mt-6 flex justify-center border-t border-slate-100 pt-5 dark:border-slate-800">
        <Button
          type="button"
          variant="primary"
          className="min-w-32"
          onClick={() => onSearch({ ...form, customerType })}
        >
          <Search size={16} />
          Search
        </Button>
      </div>
    </WorkflowSection>
  );
}
