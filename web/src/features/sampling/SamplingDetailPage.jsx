import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, PackageCheck } from "lucide-react";
import { toast } from "sonner";
import { catalogApi, customerApi, samplingApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import { WorkflowSection, InfoLine } from "@/components/parity/WorkflowSection";
import ParityBookTabs from "@/components/parity/ParityBookTabs";
import SamplingContainers, {
  buildSamplingPayloadItems,
  validateSamplingContainers,
} from "@/components/parity/SamplingContainers";
import { FormField } from "@/components/common/FormField";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import samplingTypeInfo from "@/features/sampling/SamplingSearchPage";
import { formatCurrency } from "@/utils/format";
import { getErrorMessage } from "@/utils/errors";

export default function SamplingDetailPage() {
  const nav = useNavigate();
  const qc = useQueryClient();
  const { type: routeType, customerId } = useParams();
  const id = Number(customerId);
  const info = samplingTypeInfo(routeType);
  const [items, setItems] = useState([]);
  const [containerSettings, setContainerSettings] = useState({});
  const [shipmentModeId, setShipmentModeId] = useState("");
  const [instructions, setInstructions] = useState("");
  const [remarks, setRemarks] = useState("");
  const customer = useQuery({
    queryKey: ["customer", id, "sampling"],
    queryFn: () => customerApi.get(id),
    enabled: Boolean(id),
  });
  const details = useQuery({
    queryKey: ["sampling-details", id],
    queryFn: () => samplingApi.details({ customerId: id }),
    enabled: Boolean(id),
  });
  const modes = useQuery({
    queryKey: ["shipment-modes"],
    queryFn: catalogApi.shipmentModes,
  });
  useEffect(() => {
    const x = modes.data?.shipmentModes?.[0];
    if (x && !shipmentModeId) setShipmentModeId(String(x.shipment_mode_id));
  }, [modes.data, shipmentModeId]);
  const totalQty = items.reduce((s, x) => s + Number(x.requestedQty || 0), 0);
  const total = items.reduce(
    (s, x) => s + Number(x.requestedQty || 0) * Number(x.unitPrice || 0),
    0,
  );
  const maxQty = Number(details.data?.titles?.[0]?.max_sampling_qty || 10);
  const submit = useMutation({
    mutationFn: () => {
      const containerError = validateSamplingContainers(
        items,
        containerSettings,
      );
      if (containerError) throw new Error(containerError);
      if (!shipmentModeId) throw new Error("Please select Shipment Mode");
      return samplingApi.create({
        customerId: id,
        customerType: info.type,
        shipmentModeId: Number(shipmentModeId),
        shippingInstructions: instructions.trim() || null,
        requestRemarks: remarks.trim() || null,
        items: buildSamplingPayloadItems(items, containerSettings),
      });
    },
    onSuccess: (r) => {
      toast.success(
        `${r.message}${r.requestNumber ? ` (${r.requestNumber})` : ""}`,
      );
      qc.invalidateQueries({ queryKey: ["sampling"] });
      nav("/requests/my-history");
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });
  if (customer.isLoading || details.isLoading) return <LoadingState />;
  if (customer.isError) return <ErrorState error={customer.error} />;
  if (details.isError) return <ErrorState error={details.error} />;
  const c = customer.data?.customer || {};
  const contacts = customer.data?.contacts || [];
  const primary =
    contacts.find((x) => Number(x.primary_contact) === 1) || contacts[0];
  return (
    <>
      <PageHeader
        title={`${info.label} Sampling`}
        description="Flutter-parity Customer Sampling: customer detail, title containers, Sample To / Ship To, shipment mode and approval request."
        actions={
          <Button variant="outline" onClick={() => nav(-1)}>
            <ArrowLeft size={15} />
            Back
          </Button>
        }
      />
      <div className="space-y-5">
        <WorkflowSection title={`${info.label} Detail`}>
          <div className="grid gap-3 md:grid-cols-2">
            <InfoLine label="Customer Name" value={c.customer_name} />
            <InfoLine label="Customer Code" value={c.customer_code} />
            <InfoLine
              label="Address"
              value={[c.address, c.city, c.pincode].filter(Boolean).join(", ")}
            />
            <InfoLine
              label={info.contactLabel}
              value={[primary?.first_name, primary?.last_name]
                .filter(Boolean)
                .join(" ")}
            />
            <InfoLine label="Mobile" value={primary?.mobile || c.mobile} />
            <InfoLine label="Email" value={primary?.email || c.email} />
          </div>
        </WorkflowSection>
        <WorkflowSection title="Select Books">
          <ParityBookTabs items={items} onChange={setItems} maxQty={maxQty} />
        </WorkflowSection>
        {items.length > 0 && (
          <WorkflowSection title="Sampling Details">
            <SamplingContainers
              customerId={id}
              items={items}
              settings={containerSettings}
              onChange={setContainerSettings}
              samplingTypes={details.data?.samplingTypes || []}
              sampleGivenOptions={details.data?.sampleGiven || []}
              sampleToOptions={details.data?.sampleTo || []}
            />
          </WorkflowSection>
        )}
        <WorkflowSection title="Shipment & Remarks">
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Shipment Mode" required>
              <Select
                value={shipmentModeId}
                onChange={(e) => setShipmentModeId(e.target.value)}
              >
                <option value="">--Select--</option>
                {(modes.data?.shipmentModes || []).map((x) => (
                  <option key={x.shipment_mode_id} value={x.shipment_mode_id}>
                    {x.shipment_mode}
                  </option>
                ))}
              </Select>
            </FormField>
            <div />
            <FormField label="Shipping Instructions">
              <Textarea
                value={instructions}
                onChange={(e) => setInstructions(e.target.value)}
                placeholder="Optional shipping instructions"
              />
            </FormField>
            <FormField label="Remarks">
              <Textarea
                value={remarks}
                onChange={(e) => setRemarks(e.target.value)}
                placeholder="Request remarks"
              />
            </FormField>
          </div>
        </WorkflowSection>
        <WorkflowSection title="Request Summary">
          <div className="grid gap-4 sm:grid-cols-3">
            <div>
              <p className="text-xs text-slate-500">Titles</p>
              <p className="text-xl font-bold">{items.length}</p>
            </div>
            <div>
              <p className="text-xs text-slate-500">Total Quantity</p>
              <p className="text-xl font-bold">{totalQty}</p>
            </div>
            <div>
              <p className="text-xs text-slate-500">Total MRP</p>
              <p className="text-xl font-bold">{formatCurrency(total)}</p>
            </div>
          </div>
          <div className="mt-5 flex justify-center">
            <Button
              variant="primary"
              className="min-w-56"
              disabled={submit.isPending || !items.length}
              onClick={() => submit.mutate()}
            >
              <PackageCheck size={16} />
              {submit.isPending ? "Submitting…" : "Submit Sampling Request"}
            </Button>
          </div>
        </WorkflowSection>
      </div>
    </>
  );
}
