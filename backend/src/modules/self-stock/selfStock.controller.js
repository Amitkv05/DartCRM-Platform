import { db, withTransaction } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { getSetupMap } from "../../services/setup.service.js";
import { nextRequestNumber } from "../../services/requestNumber.service.js";
import { createApproval } from "../../services/approval.service.js";
import { budgetSnapshot } from "../../services/sampling.service.js";

export async function masterData(req, res) {
  const [shipmentModes] = await db.execute("SELECT id AS shipment_mode_id, name AS shipment_mode FROM shipment_modes WHERE is_active = 1 ORDER BY id");
  res.json({
    status: "success",
    shipmentModes,
    shipTo: ["RESIDENCE_ADDRESS", "BY_HAND", "TRADE", "TRANSPORT_OFFICE"],
  });
}

export async function tradeAddresses(req, res) {
  const [rows] = await db.execute(
    `SELECT c.id AS customer_id, c.customer_name, c.customer_code, c.customer_type,
            c.address AS shipping_address, ci.name AS customer_city, c.pincode
     FROM customers c LEFT JOIN cities ci ON ci.id = c.city_id
     WHERE c.customer_type = 'TRADE' AND c.customer_status = 'ACTIVE' AND c.validation_status = 'VALIDATED'
     ORDER BY c.customer_name`
  );
  res.json({ status: "success", shipmentAddresses: rows });
}

export async function create(req, res) {
  const result = await withTransaction(async (connection) => {
    const setup = await getSetupMap(connection);
    const maxQty = Number(setup.SamplingSelfStockMaxQtyAllowed || 999);
    if (!Array.isArray(req.body.items) || req.body.items.length === 0) throw new AppError("items are required", 400);
    const normalizedItems = [];
    for (const item of req.body.items) {
      const qty = Number(item.requestedQty);
      if (!Number.isFinite(qty) || qty <= 0 || qty > maxQty) throw new AppError(`requestedQty must be between 1 and ${maxQty}`, 400);
      const [books] = await connection.execute("SELECT id, list_price FROM books WHERE id = ? AND is_active = 1 LIMIT 1", [item.bookId]);
      if (!books[0]) throw new AppError(`Book ${item.bookId} not found`, 404);
      normalizedItems.push({ ...item, requestedQty: qty, unitPrice: Number(books[0].list_price) });
    }
    const budget = await budgetSnapshot(req.body.executiveId || req.user.executiveId, normalizedItems, connection);
    const requestNumber = await nextRequestNumber("SS", connection);
    const [insert] = await connection.execute(
      `INSERT INTO self_stock_requests
       (request_number, executive_id, created_by_user_id, trade_customer_id, ship_to, shipping_address,
        shipment_mode_id, shipping_instructions, request_remarks, in_budget, available_budget, requested_budget,
        request_status, approval_status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING_APPROVAL', 'PENDING')`,
      [requestNumber, req.body.executiveId || req.user.executiveId, req.user.userId, req.body.tradeCustomerId || null,
       req.body.shipTo, req.body.shippingAddress || null, req.body.shipmentModeId,
       req.body.shippingInstructions || null, req.body.remarks || null, budget.inBudget ? 1 : 0,
       budget.availableBudget, budget.requestedBudget]
    );
    for (const item of normalizedItems) {
      await connection.execute(
        `INSERT INTO self_stock_request_items
         (request_id, subject_id, series_id, book_id, requested_qty, previous_approved_qty, approved_qty, unit_price)
         VALUES (?, ?, ?, ?, ?, 0, NULL, ?)`,
        [insert.insertId, item.subjectId || null, item.seriesId || null, item.bookId, item.requestedQty, item.unitPrice]
      );
    }
    const approval = await createApproval({
      moduleName: "SELF_STOCK",
      entityId: insert.insertId,
      requestNumber,
      requestedByExecutiveId: req.body.executiveId || req.user.executiveId,
    }, connection);
    if (approval.autoApproved) {
      await connection.execute("UPDATE self_stock_requests SET request_status='APPROVED', approval_status='APPROVED' WHERE id = ?", [insert.insertId]);
    } else {
      await connection.execute("UPDATE self_stock_requests SET request_status = ? WHERE id = ?", [`PENDING_LEVEL_${approval.level}`, insert.insertId]);
    }
    return { id: insert.insertId, requestNumber, budget, approval };
  });
  res.status(201).json({ status: "success", message: "Self Stock request submitted successfully", ...result });
}

export async function myRequests(req, res) {
  const [rows] = await db.execute("SELECT * FROM self_stock_requests WHERE executive_id = ? ORDER BY created_at DESC", [req.user.executiveId]);
  res.json({ status: "success", requests: rows });
}

export async function approvalList(req, res) {
  const [rows] = await db.execute(
    `SELECT ar.id AS approval_id, ar.current_level,
            ss.id AS request_id, ss.request_number, ss.created_at AS request_date, ss.request_status,
            e.executive_name, e.executive_code, e.mobile, e.email
     FROM approval_requests ar
     JOIN self_stock_requests ss ON ss.id = ar.entity_id
     JOIN executives e ON e.id = ss.executive_id
     WHERE ar.module_name = 'SELF_STOCK' AND ar.current_approver_executive_id = ? AND ar.status = 'PENDING'
     ORDER BY ss.created_at DESC`, [req.user.executiveId]
  );
  res.json({ status: "success", approvalList: rows });
}

export async function requestDetails(req, res) {
  const [rows] = await db.execute(
    `SELECT ss.*, e.executive_name, e.executive_code, sm.name AS shipment_mode,
            tc.customer_name AS trade_customer_name
     FROM self_stock_requests ss JOIN executives e ON e.id = ss.executive_id
     LEFT JOIN shipment_modes sm ON sm.id = ss.shipment_mode_id
     LEFT JOIN customers tc ON tc.id = ss.trade_customer_id
     WHERE ss.id = ? LIMIT 1`, [req.params.id]
  );
  if (!rows[0]) throw new AppError("Self Stock request not found", 404);
  const [items] = await db.execute(
    `SELECT i.*, b.title, b.isbn, b.author, b.book_type, b.book_num, s.name AS series_name
     FROM self_stock_request_items i JOIN books b ON b.id = i.book_id
     LEFT JOIN series s ON s.id = i.series_id WHERE i.request_id = ? ORDER BY i.id`, [req.params.id]
  );
  const [approval] = await db.execute("SELECT * FROM approval_requests WHERE module_name='SELF_STOCK' AND entity_id = ? LIMIT 1", [req.params.id]);
  res.json({ status: "success", request: rows[0], items, approval: approval[0] || null });
}
