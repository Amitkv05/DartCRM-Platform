import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { PackageCheck } from "lucide-react";
import { toast } from "sonner";
import { customerApi, samplingApi, catalogApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import BookPicker from "@/components/common/BookPicker";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { FormField } from "@/components/common/FormField";
import { getErrorMessage } from "@/utils/errors";
import { formatCurrency } from "@/utils/format";

export default function SamplingRequestPage({ customerType = "SCHOOL" }) {
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [customerId, setCustomerId] = useState("");
  const [items, setItems] = useState([]);
  const [sampleTo, setSampleTo] = useState("");
  const [sampleGiven, setSampleGiven] = useState("TO_BE_DISPATCHED");
  const [shipTo, setShipTo] = useState("");
  const [shipmentModeId, setShipmentModeId] = useState("");
  const [samplingTypeId, setSamplingTypeId] = useState("");
  const [instructions, setInstructions] = useState("");
  const customers = useQuery({
    queryKey: ["customers", customerType, "sampling"],
    queryFn: () =>
      customerApi.list({ customerType, validationStatus: "VALIDATED" }),
  });
  const details = useQuery({
    queryKey: ["sampling-details", customerId],
    queryFn: () => samplingApi.details({ customerId }),
    enabled: Boolean(customerId),
  });
  const shipmentModes = useQuery({
    queryKey: ["shipment-modes"],
    queryFn: catalogApi.shipmentModes,
  });
  const ship = useQuery({
    queryKey: ["sampling-ship-to", customerId, sampleTo, sampleGiven],
    queryFn: () =>
      samplingApi.shipTo({
        customerId,
        customerContactId: sampleTo || 0,
        sampleGiven,
      }),
    enabled: Boolean(customerId),
  });
  useEffect(() => {
    const first = details.data?.sampleTo?.[0];
    if (first && !sampleTo) setSampleTo(String(first.customer_contact_id));
  }, [details.data, sampleTo]);
  useEffect(() => {
    const first = details.data?.samplingTypes?.[0];
    if (first && !samplingTypeId) setSamplingTypeId(String(first.id));
  }, [details.data, samplingTypeId]);
  useEffect(() => {
    const first = shipmentModes.data?.shipmentModes?.[0];
    if (first && !shipmentModeId)
      setShipmentModeId(String(first.shipment_mode_id));
  }, [shipmentModes.data, shipmentModeId]);
  useEffect(() => {
    const s = ship.data?.shipTo;
    if (!s) return;
    setShipTo(s.residentialAddress || s.officeAddress || "");
  }, [ship.data]);
  const totalQty = items.reduce((s, i) => s + Number(i.requestedQty || 0), 0);
  const total = items.reduce(
    (s, i) => s + Number(i.requestedQty || 0) * Number(i.unitPrice || 0),
    0,
  );
  const mutation = useMutation({
    mutationFn: () =>
      samplingApi.create({
        customerId: Number(customerId),
        customerType,
        shipmentModeId: Number(shipmentModeId),
        shippingInstructions: instructions || null,
        requestRemarks: instructions || null,
        items: items.map((i) => ({
          seriesId: i.seriesId || null,
          bookId: Number(i.bookId),
          requestedQty: Number(i.requestedQty),
          samplingTypeId: Number(samplingTypeId),
          sampleToContactId: Number(sampleTo) || null,
          sampleGiven,
          shipTo: sampleGiven === "SAMPLE_GIVEN" ? "BY_HAND" : "DISPATCH",
          shippingAddress: shipTo || null,
          unitPrice: Number(i.unitPrice),
        })),
      }),
    onSuccess: (r) => {
      toast.success(`${r.message} (${r.requestNumber})`);
      qc.invalidateQueries({ queryKey: ["sampling"] });
      navigate("/requests/my-history");
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });
  const label =
    customerType === "SCHOOL"
      ? "School"
      : customerType === "TRADE"
        ? "Trade"
        : "Library";

  return (
    <>
      <PageHeader
        title={`${label} Sampling Request`}
        description="Select books from the shared catalog and submit them into the multi-level approval workflow."
      />
      <div className="grid gap-5 xl:grid-cols-[1.2fr_.8fr]">
        <div className="space-y-5">
          <Card>
            <CardHeader>
              <CardTitle>Customer & Delivery</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-2">
              <FormField label={label} required>
                <Select
                  value={customerId}
                  onChange={(e) => {
                    setCustomerId(e.target.value);
                    setItems([]);
                    setSampleTo("");
                  }}
                >
                  <option value="">Select customer</option>
                  {(customers.data?.customers || []).map((x) => (
                    <option key={x.id} value={x.id}>
                      {x.customer_name} ({x.customer_code})
                    </option>
                  ))}
                </Select>
              </FormField>
              <FormField label="Sampling Type" required>
                <Select
                  value={samplingTypeId}
                  onChange={(e) => setSamplingTypeId(e.target.value)}
                >
                  <option value="">Select</option>
                  {(details.data?.samplingTypes || []).map((x) => (
                    <option key={x.id} value={x.id}>
                      {x.name}
                    </option>
                  ))}
                </Select>
              </FormField>
              <FormField label="Sample To">
                <Select
                  value={sampleTo}
                  onChange={(e) => setSampleTo(e.target.value)}
                >
                  <option value="">Customer Office</option>
                  {(details.data?.sampleTo || []).map((x) => (
                    <option
                      key={x.customer_contact_id}
                      value={x.customer_contact_id}
                    >
                      {x.customer_name}
                    </option>
                  ))}
                </Select>
              </FormField>
              <FormField label="Sample Status">
                <Select
                  value={sampleGiven}
                  onChange={(e) => setSampleGiven(e.target.value)}
                >
                  {(details.data?.sampleGiven || []).map((x) => (
                    <option key={x.value} value={x.value}>
                      {x.label}
                    </option>
                  ))}
                </Select>
              </FormField>
              <FormField label="Shipment Mode">
                <Select
                  value={shipmentModeId}
                  onChange={(e) => setShipmentModeId(e.target.value)}
                >
                  <option value="">Select</option>
                  {(shipmentModes.data?.shipmentModes || []).map((x) => (
                    <option key={x.shipment_mode_id} value={x.shipment_mode_id}>
                      {x.shipment_mode}
                    </option>
                  ))}
                </Select>
              </FormField>
              <FormField label="Ship To">
                <Textarea
                  value={shipTo}
                  onChange={(e) => setShipTo(e.target.value)}
                  placeholder="Shipping address"
                />
              </FormField>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle>Books</CardTitle>
            </CardHeader>
            <CardContent>
              {customerId ? (
                <BookPicker
                  items={items}
                  onChange={setItems}
                  maxQty={Number(
                    details.data?.titles?.[0]?.max_sampling_qty || 10,
                  )}
                />
              ) : (
                <p className="py-12 text-center text-sm text-slate-500">
                  Select a customer first.
                </p>
              )}
            </CardContent>
          </Card>
        </div>
        <div className="space-y-5">
          <Card className="sticky top-24">
            <CardHeader>
              <CardTitle>Request Summary</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Books</span>
                <b>{items.length}</b>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Total Qty</span>
                <b>{totalQty}</b>
              </div>
              <div className="flex justify-between border-t pt-4 text-sm dark:border-slate-800">
                <span className="text-slate-500">Request Value</span>
                <b className="text-lg">{formatCurrency(total)}</b>
              </div>
              <FormField label="Instructions / Remarks">
                <Textarea
                  value={instructions}
                  onChange={(e) => setInstructions(e.target.value)}
                  placeholder="Optional shipment instructions…"
                />
              </FormField>
              <Button
                className="w-full"
                variant="primary"
                disabled={
                  !customerId ||
                  !items.length ||
                  !shipmentModeId ||
                  mutation.isPending
                }
                onClick={() => mutation.mutate()}
              >
                <PackageCheck size={16} />
                {mutation.isPending ? "Submitting…" : "Submit Sampling Request"}
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  );
}
