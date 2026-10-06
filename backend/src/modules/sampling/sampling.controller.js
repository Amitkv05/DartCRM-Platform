import { db, withTransaction } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { createCustomerSampling } from "../../services/sampling.service.js";
import { assertCanViewExecutive } from "../../services/hierarchy.service.js";

export async function samplingDetails(req, res) {
  if (!req.query.customerId) throw new AppError("customerId is required", 400);
  const [samplingTypes] = await db.execute("SELECT id, name FROM sampling_types WHERE is_active = 1 ORDER BY name");
  let [contacts] = await db.execute(
    `SELECT id AS customer_contact_id,
            TRIM(CONCAT(COALESCE(first_name,''),' ',COALESCE(last_name,''))) AS customer_name
     FROM customer_contacts
     WHERE customer_id = ? AND contact_status <> 'DELETED'
     ORDER BY primary_contact DESC, id`,
    [req.query.customerId]
  );
  // Sampling must remain usable even when the customer has no contact record.
  // A synthetic id=0 means "customer/office address" and is never stored as an FK.
  if (contacts.length === 0) {
    const [customerRows] = await db.execute(
      `SELECT customer_name FROM customers
       WHERE id = ? AND customer_status = 'ACTIVE' LIMIT 1`,
      [req.query.customerId]
    );
    if (customerRows[0]) {
      contacts = [{
        customer_contact_id: 0,
        customer_name: `${customerRows[0].customer_name} (Office)`,
      }];
    }
  }
  const params = [];
  const where = ["b.is_active = 1"];
  if (req.query.titleId) { where.push("b.id = ?"); params.push(req.query.titleId); }
  if (req.query.seriesId) { where.push("b.series_id = ?"); params.push(req.query.seriesId); }
  if (req.query.classLevelId) { where.push("b.class_level_id = ?"); params.push(req.query.classLevelId); }
  const [titles] = await db.execute(
    `SELECT b.id AS book_id, b.title, b.isbn, b.author, b.list_price AS price, b.list_price,
            b.physical_stock, b.book_type, b.book_num, b.series_id, b.subject_id, b.class_level_id,
            s.name AS series_name,
            COALESCE(CAST((SELECT key_value FROM application_setup WHERE key_name='SamplingCustomerMaxQtyAllowed' LIMIT 1) AS UNSIGNED), 10) AS max_sampling_qty
     FROM books b
     LEFT JOIN series s ON s.id = b.series_id
     WHERE ${where.join(" AND ")} ORDER BY b.title`, params
  );
  res.json({
    status: "success",
    samplingTypes,
    sampleGiven: [
      { label: "Sample Given", value: "SAMPLE_GIVEN" },
      { label: "To Be Dispatched", value: "TO_BE_DISPATCHED" },
    ],
    titles,
    sampleTo: contacts,
  });
}

export async function shipTo(req, res) {
  if (!req.query.customerId || !req.query.sampleGiven) {
    throw new AppError("customerId and sampleGiven are required", 400);
  }

  const customerId = Number.parseInt(req.query.customerId, 10);
  const contactId = Number.parseInt(req.query.customerContactId, 10);
  if (!Number.isInteger(customerId) || customerId <= 0) {
    throw new AppError("Invalid customerId", 400);
  }

  if (Number.isInteger(contactId) && contactId > 0) {
    const [rows] = await db.execute(
      `SELECT c.customer_name, c.address AS office_address, ci.name AS office_city, c.pincode AS office_pincode,
              cc.residential_address, rci.name AS residential_city, cc.residential_pincode,
              TRIM(CONCAT(COALESCE(cc.first_name,''),' ',COALESCE(cc.last_name,''))) AS contact_name
       FROM customers c
       JOIN customer_contacts cc
         ON cc.customer_id = c.id AND cc.id = ? AND cc.contact_status <> 'DELETED'
       LEFT JOIN cities ci ON ci.id = c.city_id
       LEFT JOIN cities rci ON rci.id = cc.residential_city_id
       WHERE c.id = ? AND c.customer_status = 'ACTIVE' LIMIT 1`,
      [contactId, customerId]
    );
    const row = rows[0];
    if (!row) throw new AppError("Customer/contact combination not found", 404);
    const contactName = row.contact_name || row.customer_name || "Customer";
    return res.json({
      status: "success",
      shipTo: {
        residentialAddress: row.residential_address
          ? `${contactName}, ${row.residential_address}, ${row.residential_city || ""} ${row.residential_pincode || ""}`.replace(/\s+/g, " ").trim()
          : null,
        officeAddress: row.office_address
          ? `${contactName}, ${row.office_address}, ${row.office_city || ""} ${row.office_pincode || ""}`.replace(/\s+/g, " ").trim()
          : null,
      },
    });
  }

  // No contact selected/available: return the customer's office address only.
  const [rows] = await db.execute(
    `SELECT c.customer_name, c.address AS office_address, ci.name AS office_city, c.pincode AS office_pincode
     FROM customers c
     LEFT JOIN cities ci ON ci.id = c.city_id
     WHERE c.id = ? AND c.customer_status = 'ACTIVE' LIMIT 1`,
    [customerId]
  );
  const row = rows[0];
  if (!row) throw new AppError("Customer not found", 404);
  res.json({
    status: "success",
    shipTo: {
      residentialAddress: null,
      officeAddress: row.office_address
        ? `${row.customer_name}, ${row.office_address}, ${row.office_city || ""} ${row.office_pincode || ""}`.replace(/\s+/g, " ").trim()
        : null,
    },
  });
}

export async function create(req, res) {
  const result = await withTransaction((connection) => createCustomerSampling(req.body, req.user, connection));
  res.status(201).json({ status: "success", message: "Customer Sampling request submitted successfully", ...result });
}

export async function myRequests(req, res) {
  const [rows] = await db.execute(
    `SELECT csr.*, c.customer_name, c.customer_code
     FROM customer_sampling_requests csr JOIN customers c ON c.id = csr.customer_id
     WHERE csr.executive_id = ? ORDER BY csr.created_at DESC`, [req.user.executiveId]
  );
  res.json({ status: "success", requests: rows });
}

export async function approvalList(req, res) {
  const [rows] = await db.execute(
    `SELECT ar.id AS approval_id, ar.current_level, ar.status AS approval_tracker_status,
            csr.id AS request_id, csr.request_number, csr.created_at AS request_date,
            csr.request_status, csr.in_budget, csr.available_budget, csr.requested_budget,
            e.executive_name, c.customer_name, c.customer_code, c.customer_type, c.address
     FROM approval_requests ar
     JOIN customer_sampling_requests csr ON csr.id = ar.entity_id
     JOIN executives e ON e.id = csr.executive_id
     JOIN customers c ON c.id = csr.customer_id
     WHERE ar.module_name = 'CUSTOMER_SAMPLING' AND ar.current_approver_executive_id = ? AND ar.status = 'PENDING'
     ORDER BY csr.created_at DESC`, [req.user.executiveId]
  );
  res.json({ status: "success", approvalList: rows });
}

export async function requestDetails(req, res) {
  const [rows] = await db.execute(
    `SELECT csr.*, c.customer_name, c.customer_code, c.address, e.executive_name, sm.name AS shipment_mode
     FROM customer_sampling_requests csr
     JOIN customers c ON c.id = csr.customer_id
     JOIN executives e ON e.id = csr.executive_id
     LEFT JOIN shipment_modes sm ON sm.id = csr.shipment_mode_id
     WHERE csr.id = ? LIMIT 1`, [req.params.id]
  );
  if (!rows[0]) throw new AppError("Sampling request not found", 404);
  await assertCanViewExecutive(req.user.executiveId, rows[0].executive_id);
  const [items] = await db.execute(
    `SELECT i.*, b.title, b.isbn, b.author, b.book_type, b.book_num, s.name AS series_name,
            st.name AS sampling_type
     FROM customer_sampling_request_items i
     JOIN books b ON b.id = i.book_id
     LEFT JOIN series s ON s.id = i.series_id
     LEFT JOIN sampling_types st ON st.id = i.sampling_type_id
     WHERE i.request_id = ? ORDER BY i.id`, [req.params.id]
  );
  const [approval] = await db.execute("SELECT * FROM approval_requests WHERE module_name = 'CUSTOMER_SAMPLING' AND entity_id = ? LIMIT 1", [req.params.id]);
  res.json({ status: "success", request: rows[0], items, approval: approval[0] || null });
}
