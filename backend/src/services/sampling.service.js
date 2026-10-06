import { AppError } from "../utils/AppError.js";
import { nextRequestNumber } from "./requestNumber.service.js";
import { createApproval } from "./approval.service.js";
import { getSetupMap } from "./setup.service.js";
import { assertCanViewExecutive } from "./hierarchy.service.js";

function nullable(value) {
  return value === undefined || value === "" ? null : value;
}

async function resolveSamplingType(item, executor) {
  const requestedId = Number.parseInt(item.samplingTypeId, 10);
  if (Number.isInteger(requestedId) && requestedId > 0) {
    const [rows] = await executor.execute(
      "SELECT id, name FROM sampling_types WHERE id = ? AND is_active = 1 LIMIT 1",
      [requestedId]
    );
    if (rows[0]) return rows[0];
    throw new AppError(`Sampling type ${requestedId} not found`, 400);
  }

  const name = String(item.samplingTypeName || item.samplingType || "").trim();
  if (!name) throw new AppError("Sampling type is required for every item", 400);
  const [rows] = await executor.execute(
    "SELECT id, name FROM sampling_types WHERE LOWER(name) = LOWER(?) AND is_active = 1 LIMIT 1",
    [name]
  );
  if (!rows[0]) throw new AppError(`Sampling type '${name}' not found`, 400);
  return rows[0];
}

async function validateSamplingReferences(payload, executiveId, executor) {
  const customerId = Number.parseInt(payload.customerId, 10);
  if (!Number.isInteger(customerId) || customerId <= 0) {
    throw new AppError("customerId is required", 400);
  }
  const [customers] = await executor.execute(
    "SELECT id FROM customers WHERE id = ? AND customer_status = 'ACTIVE' LIMIT 1",
    [customerId]
  );
  if (!customers[0]) throw new AppError("Customer not found or inactive", 404);

  if (!Number.isInteger(Number(executiveId)) || Number(executiveId) <= 0) {
    throw new AppError("executiveId is required", 400);
  }

  const shipmentModeId = Number.parseInt(payload.shipmentModeId, 10);
  if (!Number.isInteger(shipmentModeId) || shipmentModeId <= 0) {
    throw new AppError("Shipment Mode is required", 400);
  }
  const [modes] = await executor.execute(
    "SELECT id FROM shipment_modes WHERE id = ? AND is_active = 1 LIMIT 1",
    [shipmentModeId]
  );
  if (!modes[0]) throw new AppError("Invalid Shipment Mode", 400);

  return { customerId, shipmentModeId };
}

export async function budgetSnapshot(executiveId, items, executor) {
  const setup = await getSetupMap(executor);
  const budgetCheck = String(setup.SamplingBudgetCheckApplied || "No").toLowerCase() === "yes";
  if (!budgetCheck) return { inBudget: true, availableBudget: null, requestedBudget: null };

  const year = new Date().getUTCFullYear();
  const budgetType = String(setup.SamplingBudgetType || "units").toLowerCase();
  const budgetFor = String(setup.SamplingBudgetFor || "overall").toLowerCase();
  let inBudget = true;
  let availableBudget = 0;
  let requestedBudget = 0;

  if (budgetFor === "titlewise") {
    for (const item of items) {
      const [rows] = await executor.execute(
        `SELECT total_units, used_units, total_value, used_value
         FROM sampling_budgets WHERE executive_id = ? AND budget_year = ? AND book_id = ? LIMIT 1`,
        [executiveId, year, item.bookId]
      );
      const budget = rows[0];
      const requested = budgetType === "value" ? Number(item.requestedQty) * Number(item.unitPrice) : Number(item.requestedQty);
      const available = budget ? (budgetType === "value" ? budget.total_value - budget.used_value : budget.total_units - budget.used_units) : 0;
      requestedBudget += requested;
      availableBudget += available;
      if (requested > available) inBudget = false;
    }
  } else {
    const [rows] = await executor.execute(
      `SELECT total_units, used_units, total_value, used_value
       FROM sampling_budgets WHERE executive_id = ? AND budget_year = ? AND book_id IS NULL LIMIT 1`,
      [executiveId, year]
    );
    const budget = rows[0];
    requestedBudget = budgetType === "value"
      ? items.reduce((sum, item) => sum + Number(item.requestedQty) * Number(item.unitPrice), 0)
      : items.reduce((sum, item) => sum + Number(item.requestedQty), 0);
    availableBudget = budget ? (budgetType === "value" ? budget.total_value - budget.used_value : budget.total_units - budget.used_units) : 0;
    inBudget = requestedBudget <= availableBudget;
  }

  const allowWithoutBudget = String(setup.SamplingEntryWithoutBudget || "No").toLowerCase() === "yes";
  if (!inBudget && !allowWithoutBudget) {
    throw new AppError("Sampling request exceeds available budget", 409, { requestedBudget, availableBudget });
  }
  return { inBudget, availableBudget, requestedBudget };
}

export async function createCustomerSampling(payload, actor, executor, originVisitId = null) {
  const actorUserId = Number.parseInt(actor?.userId, 10);
  if (!Number.isInteger(actorUserId) || actorUserId <= 0) {
    throw new AppError("Authenticated user context is missing userId", 401);
  }

  const setup = await getSetupMap(executor);
  const customerType = String(payload.customerType || "").trim().toUpperCase();
  if (!["SCHOOL", "INSTITUTE", "TRADE", "LIBRARY"].includes(customerType)) {
    throw new AppError("customerType must be SCHOOL, INSTITUTE, TRADE or LIBRARY", 400);
  }
  const maxQty = Number(setup.SamplingCustomerMaxQtyAllowed || 10);
  if (!Array.isArray(payload.items) || payload.items.length === 0) throw new AppError("items are required", 400);

  const executiveId = Number(payload.executiveId || actor.executiveId);
  await assertCanViewExecutive(actor.executiveId, executiveId, executor);
  const { customerId, shipmentModeId } = await validateSamplingReferences(payload, executiveId, executor);

  const normalizedItems = [];
  for (const item of payload.items) {
    const bookId = Number.parseInt(item.bookId, 10);
    if (!Number.isInteger(bookId) || bookId <= 0) throw new AppError("bookId is required for every item", 400);

    const qty = Number(item.requestedQty);
    if (!Number.isFinite(qty) || qty <= 0 || qty > maxQty) {
      throw new AppError(`requestedQty must be between 1 and ${maxQty}`, 400);
    }

    const [bookRows] = await executor.execute(
      "SELECT id, list_price, series_id FROM books WHERE id = ? AND is_active = 1 LIMIT 1",
      [bookId]
    );
    const book = bookRows[0];
    if (!book) throw new AppError(`Book ${bookId} not found`, 404);

    const samplingType = await resolveSamplingType(item, executor);
    const sampleToContactId = Number.parseInt(item.sampleToContactId, 10);
    const safeContactId = Number.isInteger(sampleToContactId) && sampleToContactId > 0 ? sampleToContactId : null;
    if (safeContactId != null) {
      const [contacts] = await executor.execute(
        "SELECT id FROM customer_contacts WHERE id = ? AND customer_id = ? AND contact_status <> 'DELETED' LIMIT 1",
        [safeContactId, customerId]
      );
      if (!contacts[0]) throw new AppError(`Contact ${safeContactId} does not belong to this customer`, 400);
    }

    const sampleGiven = String(item.sampleGiven || "TO_BE_DISPATCHED").trim().toUpperCase();
    if (!["SAMPLE_GIVEN", "TO_BE_DISPATCHED"].includes(sampleGiven)) {
      throw new AppError("sampleGiven must be SAMPLE_GIVEN or TO_BE_DISPATCHED", 400);
    }

    normalizedItems.push({
      seriesId: nullable(item.seriesId) ?? book.series_id ?? null,
      bookId,
      requestedQty: qty,
      samplingTypeId: samplingType.id,
      sampleToContactId: safeContactId,
      sampleGiven,
      shipTo: nullable(item.shipTo),
      shippingAddress: nullable(item.shippingAddress),
      unitPrice: Number(item.unitPrice ?? book.list_price),
    });
  }

  const budget = await budgetSnapshot(executiveId, normalizedItems, executor);
  const requestNumber = await nextRequestNumber("CS", executor);
  const totalQty = normalizedItems.reduce((sum, item) => sum + item.requestedQty, 0);
  const totalPrice = normalizedItems.reduce((sum, item) => sum + item.requestedQty * item.unitPrice, 0);

  const [result] = await executor.execute(
    `INSERT INTO customer_sampling_requests
      (request_number, customer_id, customer_type, executive_id, created_by_user_id, origin_visit_id,
       shipment_mode_id, shipping_instructions, request_remarks, total_qty, total_price,
       in_budget, available_budget, requested_budget, request_status, approval_status)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING_APPROVAL', 'PENDING')`,
    [requestNumber, customerId, customerType, executiveId,
     actorUserId, originVisitId ?? null, shipmentModeId, nullable(payload.shippingInstructions),
     nullable(payload.requestRemarks), totalQty, totalPrice, budget.inBudget ? 1 : 0,
     budget.availableBudget ?? null, budget.requestedBudget ?? null]
  );

  for (const item of normalizedItems) {
    await executor.execute(
      `INSERT INTO customer_sampling_request_items
        (request_id, series_id, book_id, requested_qty, previous_approved_qty, approved_qty,
         sampling_type_id, sample_to_contact_id, sample_given, ship_to, shipping_address, unit_price)
       VALUES (?, ?, ?, ?, 0, NULL, ?, ?, ?, ?, ?, ?)`,
      [result.insertId, item.seriesId ?? null, item.bookId, item.requestedQty,
       item.samplingTypeId, item.sampleToContactId ?? null, item.sampleGiven,
       item.shipTo ?? null, item.shippingAddress ?? null, item.unitPrice]
    );
  }

  const approval = await createApproval({
    moduleName: "CUSTOMER_SAMPLING",
    entityId: result.insertId,
    requestNumber,
    requestedByExecutiveId: executiveId,
  }, executor);

  if (approval.autoApproved) {
    await executor.execute(
      "UPDATE customer_sampling_requests SET request_status = 'APPROVED', approval_status = 'APPROVED' WHERE id = ?",
      [result.insertId]
    );
  } else {
    await executor.execute(
      "UPDATE customer_sampling_requests SET request_status = ? WHERE id = ?",
      [`PENDING_LEVEL_${approval.level}`, result.insertId]
    );
  }

  return { id: result.insertId, requestNumber, totalQty, totalPrice, budget, approval };
}
