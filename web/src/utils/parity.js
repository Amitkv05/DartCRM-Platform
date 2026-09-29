export function pick(obj, ...keys) {
  for (const key of keys) {
    if (obj?.[key] !== undefined && obj?.[key] !== null) return obj[key];
  }
  return undefined;
}

export function customerRow(raw = {}) {
  return {
    id: Number(pick(raw, "id", "customer_id", "CustomerId") || 0),
    name: String(pick(raw, "customer_name", "CustomerName", "SchoolName") || ""),
    code: String(pick(raw, "customer_code", "CustomerCode", "SchoolCode") || ""),
    type: String(pick(raw, "customer_type", "CustomerType") || "").toUpperCase(),
    refCode: String(pick(raw, "ref_code", "RefCode") || ""),
    address: String(pick(raw, "address", "Address") || ""),
    cityId: Number(pick(raw, "city_id", "CityId") || 0),
    city: String(pick(raw, "city", "City") || ""),
    state: String(pick(raw, "state", "State") || ""),
    contactName: String(pick(raw, "contact_name", "CustomerContactName") || ""),
    validationStatus: String(pick(raw, "validation_status", "ValidationStatus") || ""),
    raw,
  };
}

export function planRow(raw = {}) {
  return {
    id: Number(pick(raw, "id", "plan_id") || 0),
    customerId: Number(pick(raw, "customer_id", "CustomerId") || 0),
    customerName: String(pick(raw, "customer_name", "CustomerName") || ""),
    customerCode: String(pick(raw, "customer_code", "CustomerCode") || ""),
    customerType: String(pick(raw, "customer_type", "CustomerType") || ""),
    address: String(pick(raw, "address", "Address") || ""),
    city: String(pick(raw, "city", "City") || ""),
    state: String(pick(raw, "state", "State") || ""),
    email: String(pick(raw, "email", "email_id", "EmailId") || ""),
    mobile: String(pick(raw, "mobile", "phone", "Phone") || ""),
    visitPurpose: String(pick(raw, "visit_purpose", "VisitPurpose") || "General Visit"),
    planDate: pick(raw, "plan_date", "PlanDate"),
    raw,
  };
}

export function normalizeShipTo(value = "") {
  const v = String(value || "").toUpperCase().replace(/[\s-]+/g, "_");
  if (v === "RESIDENCE_ADDRESS" || v === "RESIDENTIAL_ADDRESS") return "RESIDENCE_ADDRESS";
  if (v === "BY_HAND") return "BY_HAND";
  if (v === "TRADE") return "TRADE";
  if (v === "TRANSPORT_OFFICE") return "TRANSPORT_OFFICE";
  return v;
}

export function shipToLabel(value = "") {
  return String(value || "")
    .toLowerCase()
    .split("_")
    .filter(Boolean)
    .map((s) => s.charAt(0).toUpperCase() + s.slice(1))
    .join(" ");
}

export function todayIso(offset = 0) {
  const d = new Date();
  d.setDate(d.getDate() + offset);
  const local = new Date(d.getTime() - d.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 10);
}

export function isDateInsideRanges(date, ranges = []) {
  if (!date || !ranges.length) return true;
  return ranges.some((r) => date >= String(r.fromDate || "") && date <= String(r.toDate || ""));
}
