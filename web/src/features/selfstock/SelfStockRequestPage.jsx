import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { Boxes } from "lucide-react";
import { toast } from "sonner";
import { selfStockApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import { WorkflowSection, InfoLine } from "@/components/parity/WorkflowSection";
import ParityBookTabs from "@/components/parity/ParityBookTabs";
import { FormField } from "@/components/common/FormField";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { normalizeShipTo, shipToLabel } from "@/utils/parity";
import { formatCurrency } from "@/utils/format";
import { getErrorMessage } from "@/utils/errors";

export default function SelfStockRequestPage() {
  const nav = useNavigate();
  const qc = useQueryClient();
  const user = useSelector((s) => s.auth.user);
  const [items, setItems] = useState([]);
  const [shipTo, setShipTo] = useState("RESIDENCE_ADDRESS");
  const [shipmentModeId, setShipmentModeId] = useState("");
  const [tradeCustomerId, setTradeCustomerId] = useState("");
  const [transportOffice, setTransportOffice] = useState("");
  const [shippingAddress, setShippingAddress] = useState("");
  const [instructions, setInstructions] = useState("");
  const [remarks, setRemarks] = useState("");
  const master = useQuery({
    queryKey: ["self-stock-master", "flutter-parity"],
    queryFn: selfStockApi.masterData,
  });
  const trades = useQuery({
    queryKey: ["self-stock-trades", "flutter-parity"],
    queryFn: selfStockApi.tradeAddresses,
  });
  useEffect(() => {
    const x = master.data?.shipmentModes?.[0];
    if (x && !shipmentModeId) setShipmentModeId(String(x.shipment_mode_id));
  }, [master.data, shipmentModeId]);
  useEffect(() => {
    const first = (master.data?.shipTo || [])[0];
    if (
      first &&
      !(master.data?.shipTo || []).map(normalizeShipTo).includes(shipTo)
    )
      setShipTo(normalizeShipTo(first));
  }, [master.data, shipTo]);
  useEffect(() => {
    if (shipTo === "TRADE" && tradeCustomerId) {
      const x = (trades.data?.shipmentAddresses || []).find(
        (t) => Number(t.customer_id) === Number(tradeCustomerId),
      );
      if (x)
        setShippingAddress(
          [x.customer_name, x.shipping_address, x.customer_city, x.pincode]
            .filter(Boolean)
            .join(", "),
        );
      return;
    }
    if (shipTo === "TRANSPORT_OFFICE") {
      setShippingAddress(transportOffice);
      return;
    }
    if (shipTo === "BY_HAND") {
      setShippingAddress("By Hand");
      return;
    }
    if (shipTo !== "RESIDENCE_ADDRESS") setShippingAddress("");
  }, [shipTo, tradeCustomerId, trades.data, transportOffice]);
  const totalQty = items.reduce((s, x) => s + Number(x.requestedQty || 0), 0);
  const total = items.reduce(
    (s, x) => s + Number(x.requestedQty || 0) * Number(x.unitPrice || 0),
    0,
  );
  const invalidSubject = items.find((x) => !Number(x.subjectId));
  const submit = useMutation({
    mutationFn: () => {
      if (!items.length) throw new Error("Please select at least one book");
      if (invalidSubject)
        throw new Error(
          `SubjectId is missing for ${invalidSubject.title}. Select a catalog title that has subject mapping.`,
        );
      if (!shipmentModeId) throw new Error("Please select Shipment Mode");
      if (shipTo === "TRADE" && !tradeCustomerId)
        throw new Error("Please select Trade / Bookseller");
      if (shipTo === "TRANSPORT_OFFICE" && !transportOffice.trim())
        throw new Error("Please enter Transport Office Address");
      if (shipTo !== "BY_HAND" && !shippingAddress.trim())
        throw new Error("Shipping Address is required");
      return selfStockApi.create({
        executiveId: user?.executiveId,
        tradeCustomerId: shipTo === "TRADE" ? Number(tradeCustomerId) : null,
        shipTo,
        shippingAddress: shippingAddress.trim() || null,
        shipmentModeId: Number(shipmentModeId),
        shippingInstructions: instructions.trim() || null,
        remarks: remarks.trim() || null,
        items: items.map((x) => ({
          subjectId: Number(x.subjectId),
          seriesId: x.seriesId || null,
          bookId: Number(x.bookId),
          requestedQty: Number(x.requestedQty),
        })),
      });
    },
    onSuccess: (r) => {
      toast.success(
        `${r.message}${r.requestNumber ? ` (${r.requestNumber})` : ""}`,
      );
      qc.invalidateQueries({ queryKey: ["self-stock"] });
      nav("/requests/my-history");
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  return (
    <>
      <PageHeader
        title="Self-Stock Request"
        description="Same Self-Stock request flow as the Flutter CRM: executive → book selection → shipment → submit for approval."
      />
      <div className="space-y-5">
        <WorkflowSection title="Executive Detail">
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <InfoLine label="Executive Name" value={user?.executiveName} />
            <InfoLine label="Executive Code" value={user?.executiveCode} />
            <InfoLine
              label="Profile"
              value={`${user?.profileCode || ""}${user?.profileName ? ` - ${user.profileName}` : ""}`}
            />
            <InfoLine label="Designation" value={user?.designation} />
          </div>
        </WorkflowSection>
        <WorkflowSection title="Book Details">
          <ParityBookTabs
            items={items}
            onChange={setItems}
            maxQty={999}
            requireSubject
          />
        </WorkflowSection>
        <WorkflowSection title="Shipment Details">
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Shipment Mode" required>
              <Select
                value={shipmentModeId}
                onChange={(e) => setShipmentModeId(e.target.value)}
              >
                <option value="">--Select--</option>
                {(master.data?.shipmentModes || []).map((x) => (
                  <option key={x.shipment_mode_id} value={x.shipment_mode_id}>
                    {x.shipment_mode}
                  </option>
                ))}
              </Select>
            </FormField>
            <FormField label="Ship To" required>
              <Select
                value={shipTo}
                onChange={(e) => {
                  const next = normalizeShipTo(e.target.value);
                  setShipTo(next);
                  setTradeCustomerId("");
                  setTransportOffice("");
                  if (next === "RESIDENCE_ADDRESS") setShippingAddress("");
                }}
              >
                {(master.data?.shipTo || []).map((x) => {
                  const v = normalizeShipTo(x);
                  return (
                    <option key={v} value={v}>
                      {shipToLabel(v)}
                    </option>
                  );
                })}
              </Select>
            </FormField>
            {shipTo === "TRADE" && (
              <FormField label="Trade / Bookseller" required>
                <Select
                  value={tradeCustomerId}
                  onChange={(e) => setTradeCustomerId(e.target.value)}
                >
                  <option value="">--Select Trade--</option>
                  {(trades.data?.shipmentAddresses || []).map((x) => (
                    <option key={x.customer_id} value={x.customer_id}>
                      {x.customer_name} ({x.customer_code || ""})
                    </option>
                  ))}
                </Select>
              </FormField>
            )}
            {shipTo === "TRANSPORT_OFFICE" && (
              <FormField label="Transport Official Address" required>
                <Input
                  value={transportOffice}
                  onChange={(e) => setTransportOffice(e.target.value)}
                  placeholder="Transport office/address"
                />
              </FormField>
            )}
            <FormField
              className="md:col-span-2"
              label={
                shipTo === "RESIDENCE_ADDRESS"
                  ? "Residence Address"
                  : shipTo === "TRADE"
                    ? "Trade Address"
                    : "Shipping Address"
              }
              required={shipTo !== "BY_HAND"}
            >
              <Textarea
                value={shippingAddress}
                onChange={(e) => setShippingAddress(e.target.value)}
                disabled={
                  shipTo === "TRADE" ||
                  shipTo === "BY_HAND" ||
                  shipTo === "TRANSPORT_OFFICE"
                }
                placeholder={
                  shipTo === "RESIDENCE_ADDRESS"
                    ? "Enter residence address"
                    : "Shipping address"
                }
              />
              {shipTo === "RESIDENCE_ADDRESS" && (
                <p className="mt-1 text-xs text-slate-500">
                  Backend V4 does not expose the executive residence address, so
                  enter it here. The submitted value is stored with the request.
                </p>
              )}
            </FormField>
            <FormField label="Shipping Instructions">
              <Textarea
                value={instructions}
                onChange={(e) => setInstructions(e.target.value)}
                placeholder="Optional shipment instructions"
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
              <p className="text-xs text-slate-500">Estimated MRP</p>
              <p className="text-xl font-bold">{formatCurrency(total)}</p>
            </div>
          </div>
          {invalidSubject && (
            <div className="mt-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/20 dark:text-red-300">
              SubjectId is missing for <b>{invalidSubject.title}</b>. This
              request cannot be submitted until the catalog mapping is valid.
            </div>
          )}
          <div className="mt-5 flex justify-center">
            <Button
              className="min-w-56"
              variant="primary"
              disabled={submit.isPending || Boolean(invalidSubject)}
              onClick={() => submit.mutate()}
            >
              <Boxes size={16} />
              {submit.isPending ? "Submitting…" : "Submit Self-Stock Request"}
            </Button>
          </div>
        </WorkflowSection>
      </div>
    </>
  );
}
