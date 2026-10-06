/* eslint-disable react-refresh/only-export-components */

import { useEffect, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { toast } from "sonner";
import { samplingApi } from "@/api/crmApi";
import { FormField } from "@/components/common/FormField";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";

export function samplingGroupKey(item) {
  const seriesId = Number(item?.seriesId || 0);
  return seriesId > 0
    ? `series:${seriesId}`
    : `book:${Number(item?.bookId || 0)}`;
}

export function groupSamplingItems(items = []) {
  const map = new Map();
  items.forEach((item) => {
    const key = samplingGroupKey(item);
    if (!map.has(key))
      map.set(key, {
        key,
        label:
          Number(item.seriesId || 0) > 0
            ? item.seriesName || `Series ${item.seriesId}`
            : item.title || "Title not in Series",
        items: [],
      });
    map.get(key).items.push(item);
  });
  return [...map.values()];
}

export function buildSamplingPayloadItems(items = [], settings = {}) {
  return items.map((item) => {
    const config = settings[samplingGroupKey(item)] || {};
    return {
      seriesId: item.seriesId || null,
      bookId: Number(item.bookId),
      requestedQty: Number(item.requestedQty),
      samplingTypeId: Number(config.samplingTypeId),
      sampleToContactId: Number(config.sampleToContactId) || null,
      sampleGiven: config.sampleGiven || "TO_BE_DISPATCHED",
      shipTo:
        config.shipToChoice ||
        (config.sampleGiven === "SAMPLE_GIVEN" ? "BY_HAND" : null),
      shippingAddress: config.shippingAddress || null,
      unitPrice: Number(item.unitPrice || 0),
    };
  });
}

export function validateSamplingContainers(items = [], settings = {}) {
  if (!items.length) return "Please select at least one title";
  const groups = groupSamplingItems(items);
  for (let index = 0; index < groups.length; index += 1) {
    const group = groups[index];
    const c = settings[group.key] || {};
    if (!c.samplingTypeId)
      return `Please select Sampling Type for container ${index + 1}`;
    if (
      c.sampleToContactId === undefined ||
      c.sampleToContactId === null ||
      c.sampleToContactId === ""
    )
      return `Please select Sample To for container ${index + 1}`;
    if (!c.sampleGiven)
      return `Please select Sample Given for container ${index + 1}`;
    if (!c.shipToChoice)
      return `Please select Ship To for container ${index + 1}`;
    if (!String(c.shippingAddress || "").trim())
      return `Please select a valid shipping address for container ${index + 1}`;
  }
  return null;
}

export default function SamplingContainers({
  customerId,
  items = [],
  settings = {},
  onChange,
  samplingTypes = [],
  sampleGivenOptions = [],
  sampleToOptions = [],
}) {
  const groups = useMemo(() => groupSamplingItems(items), [items]);
  function update(key, patch) {
    onChange({ ...settings, [key]: { ...(settings[key] || {}), ...patch } });
  }
  function changeSampleTo(key, value) {
    const numeric = Number(value);
    if (
      numeric > 0 &&
      Object.entries(settings).some(
        ([otherKey, valueMap]) =>
          otherKey !== key && Number(valueMap?.sampleToContactId) === numeric,
      )
    ) {
      toast.error(
        "This Sample To is already used in another selected series/title container",
      );
      return;
    }
    update(key, {
      sampleToContactId: value,
      shipToChoice: "",
      shippingAddress: "",
    });
  }
  return (
    <div className="space-y-4">
      {groups.map((group, index) => (
        <SamplingContainer
          key={group.key}
          index={index}
          group={group}
          customerId={customerId}
          config={settings[group.key] || {}}
          samplingTypes={samplingTypes}
          sampleGivenOptions={sampleGivenOptions}
          sampleToOptions={sampleToOptions}
          onUpdate={(patch) => update(group.key, patch)}
          onSampleTo={(value) => changeSampleTo(group.key, value)}
        />
      ))}
    </div>
  );
}

function SamplingContainer({
  index,
  group,
  customerId,
  config,
  samplingTypes,
  sampleGivenOptions,
  sampleToOptions,
  onUpdate,
  onSampleTo,
}) {
  const sampleTo = config.sampleToContactId;
  const sampleGiven = config.sampleGiven || "TO_BE_DISPATCHED";
  const shipQ = useQuery({
    queryKey: ["sampling-container-ship-to", customerId, sampleTo, sampleGiven],
    queryFn: () =>
      samplingApi.shipTo({
        customerId,
        customerContactId: sampleTo || 0,
        sampleGiven,
      }),
    enabled: Boolean(
      customerId &&
      sampleTo !== undefined &&
      sampleTo !== null &&
      sampleTo !== "",
    ),
  });
  const ship = shipQ.data?.shipTo || {};
  useEffect(() => {
    if (!config.sampleGiven) onUpdate({ sampleGiven: "TO_BE_DISPATCHED" });
  }, [config.sampleGiven]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => {
    if (sampleGiven === "SAMPLE_GIVEN") {
      if (
        config.shipToChoice !== "BY_HAND" ||
        config.shippingAddress !== "By Hand"
      )
        onUpdate({ shipToChoice: "BY_HAND", shippingAddress: "By Hand" });
      return;
    }
    if (
      config.shipToChoice === "RESIDENTIAL_ADDRESS" &&
      ship.residentialAddress &&
      config.shippingAddress !== ship.residentialAddress
    ) {
      onUpdate({ shippingAddress: ship.residentialAddress });
      return;
    }
    if (
      config.shipToChoice === "OFFICE_ADDRESS" &&
      ship.officeAddress &&
      config.shippingAddress !== ship.officeAddress
    ) {
      onUpdate({ shippingAddress: ship.officeAddress });
      return;
    }
    if (!config.shipToChoice) {
      if (ship.officeAddress)
        onUpdate({
          shipToChoice: "OFFICE_ADDRESS",
          shippingAddress: ship.officeAddress,
        });
      else if (ship.residentialAddress)
        onUpdate({
          shipToChoice: "RESIDENTIAL_ADDRESS",
          shippingAddress: ship.residentialAddress,
        });
    }
  }, [
    sampleGiven,
    ship.officeAddress,
    ship.residentialAddress,
    config.shipToChoice,
    config.shippingAddress,
    onUpdate,
  ]);

  function chooseShip(value) {
    if (value === "OFFICE_ADDRESS")
      onUpdate({
        shipToChoice: value,
        shippingAddress: ship.officeAddress || "",
      });
    else if (value === "RESIDENTIAL_ADDRESS")
      onUpdate({
        shipToChoice: value,
        shippingAddress: ship.residentialAddress || "",
      });
    else if (value === "BY_HAND")
      onUpdate({ shipToChoice: value, shippingAddress: "By Hand" });
  }
  return (
    <div className="rounded-xl border border-white/[.08] bg-white/[.018] p-4">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-2 border-b border-white/[.06] pb-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-wide text-brand-300">
            Container {index + 1}
          </p>
          <h4 className="font-bold">{group.label}</h4>
        </div>
        <p className="text-xs text-slate-500">
          {group.items.length} title{group.items.length === 1 ? "" : "s"} · Qty{" "}
          {group.items.reduce((s, x) => s + Number(x.requestedQty || 0), 0)}
        </p>
      </div>
      <div className="grid gap-4 md:grid-cols-2">
        <FormField label="Sampling Type" required>
          <Select
            value={config.samplingTypeId || ""}
            onChange={(e) => onUpdate({ samplingTypeId: e.target.value })}
          >
            <option value="">--Select--</option>
            {samplingTypes.map((x) => (
              <option key={x.id} value={x.id}>
                {x.name}
              </option>
            ))}
          </Select>
        </FormField>
        <FormField label="Sample Given" required>
          <Select
            value={sampleGiven}
            onChange={(e) =>
              onUpdate({
                sampleGiven: e.target.value,
                shipToChoice: "",
                shippingAddress: "",
              })
            }
          >
            {sampleGivenOptions.map((x) => (
              <option key={x.value} value={x.value}>
                {x.label}
              </option>
            ))}
          </Select>
        </FormField>
        <FormField label="Sample To" required>
          <Select
            value={config.sampleToContactId ?? ""}
            onChange={(e) => onSampleTo(e.target.value)}
          >
            <option value="">--Select--</option>
            {sampleToOptions.map((x) => (
              <option key={x.customer_contact_id} value={x.customer_contact_id}>
                {x.customer_name}
              </option>
            ))}
          </Select>
        </FormField>
        <FormField label="Ship To" required>
          <Select
            value={config.shipToChoice || ""}
            onChange={(e) => chooseShip(e.target.value)}
            disabled={shipQ.isFetching || sampleGiven === "SAMPLE_GIVEN"}
          >
            <option value="">
              {shipQ.isFetching ? "Loading addresses…" : "--Select--"}
            </option>
            {sampleGiven === "SAMPLE_GIVEN" ? (
              <option value="BY_HAND">By Hand</option>
            ) : (
              <>
                <option value="OFFICE_ADDRESS" disabled={!ship.officeAddress}>
                  Official Address
                </option>
                <option
                  value="RESIDENTIAL_ADDRESS"
                  disabled={!ship.residentialAddress}
                >
                  Residential Address
                </option>
              </>
            )}
          </Select>
        </FormField>
        <FormField className="md:col-span-2" label="Shipping Address" required>
          <Textarea
            value={config.shippingAddress || ""}
            onChange={(e) => onUpdate({ shippingAddress: e.target.value })}
            placeholder="Shipping address"
          />
        </FormField>
      </div>
    </div>
  );
}
