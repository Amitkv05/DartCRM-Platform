import { db, withTransaction } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { requireFields, toFlag } from "../../utils/validation.js";
import { getSetupMap } from "../../services/setup.service.js";
import { createApproval } from "../../services/approval.service.js";
import { getDownHierarchy } from "../../services/hierarchy.service.js";
import { applyCustomerUpdate } from "../../services/customer-update.service.js";

function csvContains(csv, value) {
  return String(csv || "").split(",").map((x) => x.trim().toUpperCase()).includes(String(value).toUpperCase());
}

export async function masterData(req, res) {
  const queries = await Promise.all([
    db.execute("SELECT id, name FROM boards ORDER BY name"),
    db.execute("SELECT id, class_num_id, name FROM classes ORDER BY sort_order"),
    db.execute("SELECT id, name FROM chain_schools ORDER BY name"),
    db.execute("SELECT id, name FROM data_sources ORDER BY name"),
    db.execute("SELECT id, name FROM salutations ORDER BY name"),
    db.execute("SELECT id, name FROM contact_designations ORDER BY name"),
    db.execute("SELECT id, name FROM subjects ORDER BY name"),
    db.execute("SELECT id, name FROM departments ORDER BY name"),
    db.execute("SELECT id, name FROM adoption_roles ORDER BY name"),
    db.execute("SELECT id, name FROM customer_categories ORDER BY name"),
    db.execute("SELECT id, name FROM purchase_modes ORDER BY id"),
    db.execute("SELECT id, name FROM institute_types ORDER BY name"),
    db.execute("SELECT id, name FROM institute_levels ORDER BY name"),
    db.execute("SELECT id, name FROM affiliate_types ORDER BY name"),
    db.execute("SELECT id, executive_name AS name FROM executives WHERE status = 'ACTIVE' ORDER BY executive_name"),
  ]);
  const names = ["boards","classes","chainSchools","dataSources","salutations","contactDesignations","subjects","departments","adoptionRoles","customerCategories","purchaseModes","instituteTypes","instituteLevels","affiliateTypes","accountableExecutives"];
  const data = {};
  names.forEach((name, i) => { data[name] = queries[i][0]; });
  res.json({ status: "success", ...data });
}

export async function createCustomer(req, res) {
  requireFields(req.body, ["customerType", "customerName", "address", "cityId", "pincode", "customerStatus"]);
  const customerType = String(req.body.customerType).trim().toUpperCase();
  const customerStatus = String(req.body.customerStatus).trim().toUpperCase();
  if (!["SCHOOL", "INSTITUTE", "TRADE", "LIBRARY"].includes(customerType)) {
    throw new AppError("customerType must be SCHOOL, INSTITUTE, TRADE or LIBRARY", 400);
  }
  if (!["ACTIVE", "INACTIVE"].includes(customerStatus)) throw new AppError("customerStatus must be ACTIVE or INACTIVE", 400);
  const result = await withTransaction(async (connection) => {
    const setup = await getSetupMap(connection);
    const directValidated = csvContains(setup.ApprovedCustomerMasterNew, req.user.profileCode);
    const validationStatus = directValidated ? "VALIDATED" : "PENDING_APPROVAL";

    const [duplicate] = await connection.execute(
      `SELECT id, validation_status FROM customers
       WHERE customer_type = ? AND LOWER(customer_name) = LOWER(?) AND city_id = ?
       AND customer_status <> 'INACTIVE' LIMIT 1`,
      [customerType, req.body.customerName, req.body.cityId]
    );
    if (duplicate[0]) throw new AppError("Customer already exists or is already pending approval", 409);

    const [insert] = await connection.execute(
      `INSERT INTO customers
       (customer_type, customer_name, ref_code, email, mobile, address, city_id, pincode,
        key_customer, customer_status, validation_status, latitude, longitude, gst_number, pan_number,
        created_by_user_id, created_by_executive_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [customerType, req.body.customerName, req.body.refCode || null, req.body.email || null,
       req.body.mobile || null, req.body.address, req.body.cityId, req.body.pincode,
       toFlag(req.body.keyCustomer), customerStatus, validationStatus,
       req.body.latitude || null, req.body.longitude || null, req.body.gstNumber || null,
       req.body.panNumber || null, req.user.userId, req.user.executiveId]
    );
    const customerId = insert.insertId;
    const codePrefix = { SCHOOL: "SCH", INSTITUTE: "INS", TRADE: "TR", LIBRARY: "LR" }[customerType];
    await connection.execute("UPDATE customers SET customer_code = ? WHERE id = ?", [`${codePrefix}${String(customerId).padStart(4, "0")}`, customerId]);

    if (Array.isArray(req.body.categoryIds)) {
      for (const categoryId of req.body.categoryIds) {
        await connection.execute("INSERT IGNORE INTO customer_category_map (customer_id, category_id) VALUES (?, ?)", [customerId, categoryId]);
      }
    }
    const executiveIds = Array.isArray(req.body.executiveIds) && req.body.executiveIds.length ? req.body.executiveIds : [req.user.executiveId];
    for (const executiveId of executiveIds) {
      await connection.execute("INSERT IGNORE INTO customer_executives (customer_id, executive_id) VALUES (?, ?)", [customerId, executiveId]);
    }

    if (customerType === "SCHOOL") {
      const school = req.body.school || {};
      await connection.execute(
        `INSERT INTO customer_school_details
         (customer_id, board_id, chain_school_id, start_class_id, end_class_id, medium_instruction,
          ranking, sampling_month, decision_month, purchase_mode_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [customerId, school.boardId || null, school.chainSchoolId || null, school.startClassId || null,
         school.endClassId || null, school.mediumInstruction || null, school.ranking || null,
         school.samplingMonth || null, school.decisionMonth || null, school.purchaseModeId || null]
      );
    }

    if (req.body.primaryContact) {
      const c = req.body.primaryContact;
      await connection.execute(
        `INSERT INTO customer_contacts
         (customer_id, customer_type, primary_contact, salutation_id, designation_id, first_name, last_name,
          email, mobile, contact_status, validation_status, residential_address, residential_city_id,
          residential_pincode, birthday, anniversary, created_by_user_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [customerId, customerType, toFlag(c.primaryContact), c.salutationId || null,
         c.designationId || null, c.firstName || null, c.lastName || null, c.email || null,
         c.mobile || null, String(c.contactStatus || "ACTIVE").toUpperCase(), directValidated ? "VALIDATED" : "PENDING_APPROVAL",
         c.residentialAddress || null, c.residentialCityId || null, c.residentialPincode || null,
         c.birthday || null, c.anniversary || null, req.user.userId]
      );
    }

    let approval = null;
    if (!directValidated) {
      approval = await createApproval({
        moduleName: "CUSTOMER_CREATE",
        entityId: customerId,
        requestNumber: `CUST-${customerId}`,
        requestedByExecutiveId: req.user.executiveId,
      }, connection);
      if (approval.autoApproved) {
        await connection.execute("UPDATE customers SET validation_status = 'VALIDATED' WHERE id = ?", [customerId]);
      }
    }
    return { customerId, validationStatus: approval?.autoApproved ? "VALIDATED" : validationStatus, approval };
  });
  res.status(201).json({ status: "success", ...result });
}

export async function updateCustomer(req, res) {
  const result = await withTransaction(async (connection) => {
    const customerId = Number(req.params.id);
    const [rows] = await connection.execute(
      "SELECT * FROM customers WHERE id = ? FOR UPDATE",
      [customerId]
    );
    const existing = rows[0];
    if (!existing) throw new AppError("Customer not found", 404);

    const [actorRows] = await connection.execute(
      `SELECT p.is_admin FROM executives e JOIN profiles p ON p.id = e.profile_id
       WHERE e.id = ? LIMIT 1`,
      [req.user.executiveId]
    );
    const isAdmin = Number(actorRows[0]?.is_admin || 0) === 1;

    // Admin changes are intentionally direct. Everyone else submits a staged update request.
    if (isAdmin) {
      await applyCustomerUpdate(customerId, req.body, connection);
      return { customerId, directUpdate: true, requestStatus: "APPROVED" };
    }

    const [pending] = await connection.execute(
      `SELECT id FROM customer_change_requests
       WHERE customer_id = ? AND status = 'PENDING' LIMIT 1`,
      [customerId]
    );
    if (pending[0]) {
      throw new AppError("A customer update request is already pending approval", 409);
    }

    const [schoolRows] = await connection.execute(
      "SELECT * FROM customer_school_details WHERE customer_id = ? LIMIT 1",
      [customerId]
    );
    const [categoryRows] = await connection.execute(
      "SELECT category_id FROM customer_category_map WHERE customer_id = ? ORDER BY category_id",
      [customerId]
    );
    const [executiveRows] = await connection.execute(
      "SELECT executive_id FROM customer_executives WHERE customer_id = ? ORDER BY executive_id",
      [customerId]
    );

    const originalSnapshot = {
      customer: existing,
      school: schoolRows[0] || null,
      categoryIds: categoryRows.map((row) => row.category_id),
      executiveIds: executiveRows.map((row) => row.executive_id),
    };

    const [changeInsert] = await connection.execute(
      `INSERT INTO customer_change_requests
       (customer_id, requested_by_executive_id, proposed_payload, original_snapshot, status)
       VALUES (?, ?, ?, ?, 'PENDING')`,
      [customerId, req.user.executiveId, JSON.stringify(req.body || {}), JSON.stringify(originalSnapshot)]
    );

    const requestNumber = `CUST-UPD-${existing.customer_code || customerId}-${changeInsert.insertId}`;
    const approval = await createApproval({
      moduleName: "CUSTOMER_UPDATE",
      entityId: changeInsert.insertId,
      requestNumber,
      requestedByExecutiveId: req.user.executiveId,
    }, connection);

    if (approval.autoApproved) {
      await applyCustomerUpdate(customerId, req.body, connection);
      await connection.execute(
        "UPDATE customer_change_requests SET status='APPROVED', completed_at=CURRENT_TIMESTAMP WHERE id = ?",
        [changeInsert.insertId]
      );
    }

    return {
      customerId,
      changeRequestId: changeInsert.insertId,
      requestNumber,
      directUpdate: false,
      requestStatus: approval.autoApproved ? "APPROVED" : "PENDING_APPROVAL",
      approval,
    };
  });

  res.json({
    status: "success",
    message: result.directUpdate
      ? "Customer updated successfully"
      : result.requestStatus === "APPROVED"
        ? "Customer update approved automatically"
        : "Customer update request submitted for approval",
    ...result,
  });
}

export async function listCustomers(req, res) {
  const down = await getDownHierarchy(req.user.executiveId);
  const params = [];
  const conditions = ["1=1"];
  if (req.query.customerType) { conditions.push("c.customer_type = ?"); params.push(req.query.customerType); }
  if (req.query.validationStatus) { conditions.push("c.validation_status = ?"); params.push(req.query.validationStatus); }
  if (req.query.cityId) { conditions.push("c.city_id = ?"); params.push(req.query.cityId); }
  if (req.query.search) {
    conditions.push("(c.customer_name LIKE ? OR c.customer_code LIKE ? OR c.ref_code LIKE ?)");
    const q = `%${req.query.search}%`; params.push(q, q, q);
  }
  const placeholders = down.map(() => "?").join(",");
  // Final approved/validated CRM masters are visible across all levels.
  // Pending/rejected records remain limited to the creator's reporting scope.
  conditions.push(`((c.validation_status = 'VALIDATED' AND c.customer_status = 'ACTIVE') OR
                    EXISTS (SELECT 1 FROM customer_executives ce WHERE ce.customer_id = c.id AND ce.executive_id IN (${placeholders})))`);
  params.push(...down);

  const [rows] = await db.execute(
    `SELECT c.id, c.customer_code, c.customer_name, c.customer_type, c.ref_code, c.address,
            c.city_id, ci.name AS city, c.customer_status, c.validation_status, c.delete_request_status
     FROM customers c LEFT JOIN cities ci ON ci.id = c.city_id
     WHERE ${conditions.join(" AND ")} ORDER BY c.customer_name`, params
  );
  res.json({ status: "success", customers: rows });
}

export async function getCustomer(req, res) {
  const [rows] = await db.execute(
    `SELECT c.*, ci.name AS city FROM customers c LEFT JOIN cities ci ON ci.id = c.city_id WHERE c.id = ? LIMIT 1`,
    [req.params.id]
  );
  const customer = rows[0];
  if (!customer) throw new AppError("Customer not found", 404);

  // V4 rule: only finalized/validated active customers are globally visible.
  // Pending/rejected records remain restricted to the viewer's down-hierarchy assignments.
  const globallyVisible =
    customer.validation_status === "VALIDATED" && customer.customer_status === "ACTIVE";

  if (!globallyVisible) {
    const down = await getDownHierarchy(req.user.executiveId);
    const placeholders = down.map(() => "?").join(",");
    const [accessRows] = await db.execute(
      `SELECT 1
       FROM customer_executives
       WHERE customer_id = ?
         AND executive_id IN (${placeholders})
       LIMIT 1`,
      [req.params.id, ...down]
    );
    if (!accessRows[0]) {
      throw new AppError("You cannot view this customer", 403);
    }
  }

  const [contacts] = await db.execute("SELECT * FROM customer_contacts WHERE customer_id = ? ORDER BY primary_contact DESC, id", [req.params.id]);
  const [categories] = await db.execute(
    `SELECT cc.id, cc.name FROM customer_category_map m JOIN customer_categories cc ON cc.id = m.category_id WHERE m.customer_id = ?`, [req.params.id]
  );
  const [executives] = await db.execute(
    `SELECT e.id, e.executive_name FROM customer_executives ce JOIN executives e ON e.id = ce.executive_id WHERE ce.customer_id = ?`, [req.params.id]
  );
  const [school] = await db.execute(
    `SELECT csd.*, sc.class_num_id AS start_class_num_id, ec.class_num_id AS end_class_num_id
     FROM customer_school_details csd
     LEFT JOIN classes sc ON sc.id = csd.start_class_id
     LEFT JOIN classes ec ON ec.id = csd.end_class_id
     WHERE csd.customer_id = ? LIMIT 1`,
    [req.params.id]
  );
  res.json({ status: "success", customer, contacts, categories, executives, school: school[0] || null });
}

export async function requestDelete(req, res) {
  const result = await withTransaction(async (connection) => {
    const [rows] = await connection.execute("SELECT * FROM customers WHERE id = ? FOR UPDATE", [req.params.id]);
    const customer = rows[0];
    if (!customer) throw new AppError("Customer not found", 404);
    if (customer.delete_request_status === "PENDING") throw new AppError("Delete request is already pending for approval", 409);
    await connection.execute("UPDATE customers SET delete_request_status = 'PENDING' WHERE id = ?", [req.params.id]);
    const approval = await createApproval({
      moduleName: "CUSTOMER_DELETE",
      entityId: customer.id,
      requestNumber: `DEL-${customer.customer_code || customer.id}`,
      requestedByExecutiveId: req.user.executiveId,
    }, connection);
    if (approval.autoApproved) {
      await connection.execute("UPDATE customers SET customer_status = 'INACTIVE', delete_request_status = 'APPROVED' WHERE id = ?", [customer.id]);
    }
    return approval;
  });
  res.json({ status: "success", message: "Customer delete request submitted", approval: result });
}

export async function searchCities(req, res) {
  const [rows] = await db.execute(
    `SELECT DISTINCT c.id, c.name FROM executive_cities ec JOIN cities c ON c.id = ec.city_id
     WHERE ec.executive_id = ? ORDER BY c.name`, [req.user.executiveId]
  );
  res.json({ status: "success", cities: rows });
}

export async function searchCustomers(req, res) {
  req.query.search = req.query.customerName || req.query.customerCode || req.query.search;
  return listCustomers(req, res);
}

export async function searchBookSellers(req, res) {
  const params = [];
  const where = ["c.customer_type = 'TRADE'", "c.customer_status = 'ACTIVE'"];
  if (req.query.cityId) { where.push("c.city_id = ?"); params.push(req.query.cityId); }
  if (req.query.name) { where.push("c.customer_name LIKE ?"); params.push(`%${req.query.name}%`); }
  if (req.query.code) { where.push("c.customer_code LIKE ?"); params.push(`%${req.query.code}%`); }
  const [rows] = await db.execute(
    `SELECT c.id AS book_seller_id, c.customer_name AS book_seller_name, c.customer_code,
            c.address, ci.name AS city
     FROM customers c LEFT JOIN cities ci ON ci.id = c.city_id
     WHERE ${where.join(" AND ")} ORDER BY c.customer_name`, params
  );
  res.json({ status: "success", bookSellers: rows });
}
