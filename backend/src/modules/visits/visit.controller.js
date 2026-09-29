import { db, withTransaction } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { requireFields } from "../../utils/validation.js";
import { getDownHierarchy, getUpHierarchy } from "../../services/hierarchy.service.js";
import { getSetupMap } from "../../services/setup.service.js";
import { createApproval } from "../../services/approval.service.js";
import { createCustomerSampling } from "../../services/sampling.service.js";

function daysBetween(a, b) {
  const ms = 24 * 60 * 60 * 1000;
  return Math.floor(
    (Date.UTC(a.getUTCFullYear(), a.getUTCMonth(), a.getUTCDate()) -
      Date.UTC(b.getUTCFullYear(), b.getUTCMonth(), b.getUTCDate())) /
      ms
  );
}

function dateOnly(value) {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString().slice(0, 10);
}

function addUtcDays(date, amount) {
  const copy = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  copy.setUTCDate(copy.getUTCDate() + amount);
  return copy;
}

async function allowedDateRangesForExecutive(executiveId, executor = db) {
  const setup = await getSetupMap(executor);
  const allowedDays = Math.max(0, Number(setup.VisitEntryDays || 3));
  const today = new Date();
  const normalFrom = addUtcDays(today, -allowedDays);
  const ranges = [
    {
      fromDate: dateOnly(normalFrom),
      toDate: dateOnly(today),
      source: "NORMAL",
      backdateRequestId: null,
    },
  ];

  const [approvedBackdates] = await executor.execute(
    `SELECT id, requested_visit_date
     FROM backdate_requests
     WHERE executive_id = ? AND status = 'APPROVED'
     ORDER BY requested_visit_date, id`,
    [executiveId]
  );

  for (const row of approvedBackdates) {
    const visitDate = dateOnly(row.requested_visit_date);
    if (!visitDate) continue;
    const alreadyInsideNormal = visitDate >= ranges[0].fromDate && visitDate <= ranges[0].toDate;
    if (!alreadyInsideNormal) {
      ranges.push({
        fromDate: visitDate,
        toDate: visitDate,
        source: "APPROVED_BACKDATE",
        backdateRequestId: Number(row.id),
      });
    }
  }
  return ranges;
}

async function validateVisitDate(visitDate, backdateRequestId, executiveId, executor) {
  const setup = await getSetupMap(executor);
  const allowedDays = Number(setup.VisitEntryDays || 3);
  const target = new Date(`${visitDate}T00:00:00Z`);
  if (Number.isNaN(target.getTime())) {
    throw new AppError("visitDate must be a valid YYYY-MM-DD date", 400);
  }
  const age = daysBetween(new Date(), target);
  if (age < 0) throw new AppError("Visit date cannot be in the future", 400);
  if (age <= allowedDays) return;

  if (!backdateRequestId) {
    throw new AppError(
      "Visit date is outside normal entry period. An approved backdate request is required.",
      409
    );
  }
  const [rows] = await executor.execute(
    `SELECT id, status, executive_id, requested_visit_date FROM backdate_requests
     WHERE id = ? LIMIT 1`,
    [backdateRequestId]
  );
  const request = rows[0];
  if (
    !request ||
    request.status !== "APPROVED" ||
    Number(request.executive_id) !== Number(executiveId)
  ) {
    throw new AppError("Backdate request is not approved for this executive", 409);
  }
  if (dateOnly(request.requested_visit_date) !== visitDate) {
    throw new AppError("Backdate request does not match visitDate", 409);
  }
}

async function validateVisitReferences(body, executor) {
  const [customerRows] = await executor.execute(
    "SELECT id, customer_type FROM customers WHERE id = ? AND customer_status = 'ACTIVE' LIMIT 1",
    [body.customerId]
  );
  const customer = customerRows[0];
  if (!customer) throw new AppError("Customer not found or inactive", 404);

  if (String(customer.customer_type).toUpperCase() !== String(body.customerType).toUpperCase()) {
    throw new AppError("customerType does not match the selected customer", 400);
  }

  const contactId = Number.parseInt(body.customerContactId, 10);
  if (Number.isInteger(contactId) && contactId > 0) {
    const [contactRows] = await executor.execute(
      `SELECT id FROM customer_contacts
       WHERE id = ? AND customer_id = ? AND contact_status <> 'DELETED' LIMIT 1`,
      [contactId, body.customerId]
    );
    if (!contactRows[0]) {
      throw new AppError("Selected Person Met does not belong to this customer", 400);
    }
  }

  const [purposeRows] = await executor.execute(
    "SELECT id FROM visit_purposes WHERE id = ? AND is_active = 1 LIMIT 1",
    [body.visitPurposeId]
  );
  if (!purposeRows[0]) throw new AppError("Invalid Visit Purpose", 400);

  if (body.academicSessionId != null) {
    const [sessionRows] = await executor.execute(
      "SELECT id FROM academic_sessions WHERE id = ? AND is_active = 1 LIMIT 1",
      [body.academicSessionId]
    );
    if (!sessionRows[0]) throw new AppError("Invalid Academic Session", 400);
  }
}

async function insertEProductPromotions(visitId, promotions, executor) {
  if (!Array.isArray(promotions) || promotions.length === 0) return;

  for (const promotion of promotions) {
    requireFields(promotion, ["brandId", "eProductId", "salesStageId", "prospectId"]);

    const [productRows] = await executor.execute(
      `SELECT ep.id
       FROM e_products ep
       JOIN brands b ON b.id = ep.brand_id AND b.is_active = 1
       WHERE ep.id = ? AND ep.brand_id = ? AND ep.is_active = 1 LIMIT 1`,
      [promotion.eProductId, promotion.brandId]
    );
    if (!productRows[0]) {
      throw new AppError("Selected E-Product does not belong to the selected Brand", 400);
    }

    const [stageRows] = await executor.execute(
      "SELECT id FROM sales_stages WHERE id = ? AND is_active = 1 LIMIT 1",
      [promotion.salesStageId]
    );
    if (!stageRows[0]) throw new AppError("Invalid Sales Stage", 400);

    const [prospectRows] = await executor.execute(
      "SELECT id FROM prospects WHERE id = ? AND is_active = 1 LIMIT 1",
      [promotion.prospectId]
    );
    if (!prospectRows[0]) throw new AppError("Invalid Prospect", 400);

    const [insert] = await executor.execute(
      `INSERT INTO visit_eproduct_promotions
       (visit_id, brand_id, e_product_id, sales_stage_id, prospect_id, remarks)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        visitId,
        Number(promotion.brandId),
        Number(promotion.eProductId),
        Number(promotion.salesStageId),
        Number(promotion.prospectId),
        promotion.remarks || null,
      ]
    );

    // Flutter/original API sends ClassNumId values (-1, 1, 2, ...), not the
    // internal classes.id primary key. Resolve the business ClassNumId first.
    const classNumIds = Array.isArray(promotion.classIds)
      ? [...new Set(promotion.classIds.map(Number).filter(Number.isFinite))]
      : [];
    for (const classNumId of classNumIds) {
      const [classRows] = await executor.execute(
        `SELECT c.id AS class_id
         FROM classes c
         JOIN e_product_classes epc
           ON epc.class_id = c.id AND epc.e_product_id = ?
         WHERE c.class_num_id = ? LIMIT 1`,
        [promotion.eProductId, classNumId]
      );
      if (!classRows[0]) {
        throw new AppError(
          `Class ${classNumId} is not configured for the selected E-Product`,
          400
        );
      }
      await executor.execute(
        "INSERT INTO visit_eproduct_promotion_classes (promotion_id, class_id) VALUES (?, ?)",
        [insert.insertId, classRows[0].class_id]
      );
    }
  }
}

export async function dsrEntryData(req, res) {
  requireFields(req.query, ["customerId"]);
  const [customerRows] = await db.execute(
    `SELECT c.id, c.customer_code, c.customer_name, c.customer_type, c.ref_code,
            c.address, c.email, c.mobile
     FROM customers c WHERE c.id = ? AND c.customer_status = 'ACTIVE' LIMIT 1`,
    [req.query.customerId]
  );
  const customer = customerRows[0];
  if (!customer) throw new AppError("Customer not found", 404);

  const up = await getUpHierarchy(req.user.executiveId);
  const down = await getDownHierarchy(req.user.executiveId);
  const hierarchyIds = [...new Set([...up, ...down, req.user.executiveId])];
  const placeholders = hierarchyIds.map(() => "?").join(",");
  const [joinVisit] = await db.execute(
    `SELECT id AS executive_id, executive_name
     FROM executives
     WHERE id IN (${placeholders}) AND status = 'ACTIVE'
     ORDER BY executive_name`,
    hierarchyIds
  );
  const [personMet] = await db.execute(
    `SELECT id AS customer_contact_id,
            TRIM(CONCAT(COALESCE(first_name,''), ' ', COALESCE(last_name,''))) AS customer_contact_name
     FROM customer_contacts
     WHERE customer_id = ? AND contact_status <> 'DELETED'
     ORDER BY primary_contact DESC, first_name, last_name`,
    [customer.id]
  );
  const [visitPurpose] = await db.execute(
    "SELECT id, name AS visit_purpose FROM visit_purposes WHERE is_active = 1 ORDER BY id"
  );
  const [departments] = await db.execute(
    "SELECT id, name AS department FROM departments ORDER BY name"
  );
  const [academicSessions] = await db.execute(
    `SELECT id, session_name, start_date, end_date
     FROM academic_sessions WHERE is_active = 1 ORDER BY start_date DESC`
  );
  const [salesStage] = await db.execute(
    `SELECT id, stage_name, sequence_num
     FROM sales_stages WHERE is_active = 1 ORDER BY id`
  );
  const [brands] = await db.execute(
    "SELECT id, brand_name FROM brands WHERE is_active = 1 ORDER BY brand_name"
  );
  const [prospects] = await db.execute(
    "SELECT id, prospect_name FROM prospects WHERE is_active = 1 ORDER BY id"
  );
  const setup = await getSetupMap();
  const allowedDateRanges = await allowedDateRangesForExecutive(req.user.executiveId);

  res.json({
    status: "success",
    customerSummary: customer,
    visitPurpose,
    joinVisit,
    personMet,
    departments,
    academicSessions,
    salesStage,
    brands,
    prospects,
    applicationSetupKeyValue: [
      {
        visitBooksSampling: setup.VisitBooksSampling || "N",
        visitEProducts: setup.VisitEProducts || "N",
      },
    ],
    allowedDateRanges,
    upHierarchy: up,
    downHierarchy: down,
  });
}

export async function followUpExecutives(req, res) {
  requireFields(req.query, ["departmentId"]);
  const [rows] = await db.execute(
    `SELECT id AS executive_id, executive_name FROM executives
     WHERE department_id = ? AND status = 'ACTIVE' ORDER BY executive_name`,
    [req.query.departmentId]
  );
  res.json({ status: "success", executives: rows });
}


export async function listMyBackdateRequests(req, res) {
  const [rows] = await db.execute(
    `SELECT br.id, br.requested_visit_date, br.reason, br.status, br.created_at,
            ar.id AS approval_id, ar.current_level, ar.current_approver_executive_id
     FROM backdate_requests br
     LEFT JOIN approval_requests ar
       ON ar.module_name = 'VISIT_BACKDATE' AND ar.entity_id = br.id
     WHERE br.executive_id = ?
     ORDER BY br.created_at DESC`,
    [req.user.executiveId]
  );
  res.json({ status: "success", requests: rows });
}

export async function requestBackdate(req, res) {
  requireFields(req.body, ["visitDate", "reason"]);
  const setup = await getSetupMap();
  const maxDays = Number(setup.BackDateRequestDaysVisit || 10);
  const target = new Date(`${req.body.visitDate}T00:00:00Z`);
  const age = daysBetween(new Date(), target);
  if (age < 0) throw new AppError("Backdate request cannot be for a future date", 400);
  if (age > maxDays) {
    throw new AppError(`Backdate request cannot exceed ${maxDays} days`, 409);
  }

  const result = await withTransaction(async (connection) => {
    const [existing] = await connection.execute(
      `SELECT id, status FROM backdate_requests
       WHERE executive_id = ? AND requested_visit_date = ? AND status = 'PENDING' LIMIT 1`,
      [req.user.executiveId, req.body.visitDate]
    );
    if (existing[0]) throw new AppError("A backdate request for this visit date is already pending", 409);

    const [insert] = await connection.execute(
      `INSERT INTO backdate_requests
       (executive_id, requested_visit_date, reason, status, created_by_user_id)
       VALUES (?, ?, ?, 'PENDING', ?)`,
      [req.user.executiveId, req.body.visitDate, req.body.reason, req.user.userId]
    );
    const approval = await createApproval(
      {
        moduleName: "VISIT_BACKDATE",
        entityId: insert.insertId,
        requestNumber: `BDV-${insert.insertId}`,
        requestedByExecutiveId: req.user.executiveId,
      },
      connection
    );
    if (approval.autoApproved) {
      await connection.execute(
        "UPDATE backdate_requests SET status = 'APPROVED' WHERE id = ?",
        [insert.insertId]
      );
    }
    return { requestId: insert.insertId, approval };
  });
  res.status(201).json({ status: "success", ...result });
}

export async function createVisit(req, res) {
  requireFields(req.body, [
    "customerId",
    "customerType",
    "visitPurposeId",
    "visitFeedback",
    "visitDate",
    "address",
    "latitude",
    "longitude",
  ]);

  const result = await withTransaction(async (connection) => {
    await validateVisitReferences(req.body, connection);

    const setup = await getSetupMap(connection);
    if (
      String(setup.VisitFeedbackMandatory || "No").toLowerCase() === "yes" &&
      !String(req.body.visitFeedback || "").trim()
    ) {
      throw new AppError("Visit feedback is mandatory", 400);
    }
    const minChars = Number(setup.VisitFeedbackMinChar || 0);
    if (String(req.body.visitFeedback || "").trim().length < minChars) {
      throw new AppError(`Visit feedback must contain at least ${minChars} characters`, 400);
    }
    await validateVisitDate(
      req.body.visitDate,
      req.body.backdateRequestId,
      req.user.executiveId,
      connection
    );

    const [visitInsert] = await connection.execute(
      `INSERT INTO visits
       (executive_id, logged_in_executive_id, customer_id, customer_type,
        customer_contact_id, academic_session_id, visit_purpose_id,
        other_visit_purpose, visit_feedback, visit_date, address, latitude, longitude,
        request_remarks, send_thankyou_mail, mail_content_type, mail_body, web_entry,
        competing_data_payload, backdate_request_id, created_by_user_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.body.executiveId || req.user.executiveId,
        req.user.executiveId,
        req.body.customerId,
        String(req.body.customerType).toUpperCase(),
        Number.parseInt(req.body.customerContactId, 10) > 0
          ? Number.parseInt(req.body.customerContactId, 10)
          : null,
        req.body.academicSessionId || null,
        req.body.visitPurposeId,
        req.body.otherVisitPurpose || null,
        req.body.visitFeedback,
        req.body.visitDate,
        req.body.address,
        req.body.latitude,
        req.body.longitude,
        req.body.requestRemarks || null,
        String(req.body.sendThankyouMail || "No").toLowerCase() === "yes" ? 1 : 0,
        req.body.mailContentType || null,
        req.body.mailBody || null,
        String(req.body.webEntry || "No").toLowerCase() === "yes" ? 1 : 0,
        req.body.competingDataPayload || null,
        req.body.backdateRequestId || null,
        req.user.userId,
      ]
    );
    const visitId = visitInsert.insertId;

    if (Array.isArray(req.body.jointExecutiveIds)) {
      for (const executiveId of [...new Set(req.body.jointExecutiveIds.map(Number))]) {
        if (!Number.isFinite(executiveId)) continue;
        await connection.execute(
          "INSERT IGNORE INTO visit_joint_executives (visit_id, executive_id) VALUES (?, ?)",
          [visitId, executiveId]
        );
      }
    }

    if (Array.isArray(req.body.documents)) {
      for (const doc of req.body.documents) {
        requireFields(doc, ["documentName", "fileName"]);
        await connection.execute(
          "INSERT INTO visit_documents (visit_id, document_name, file_name, file_size) VALUES (?, ?, ?, ?)",
          [visitId, doc.documentName, doc.fileName, doc.fileSize || null]
        );
      }
    }

    if (Array.isArray(req.body.followUps)) {
      for (const follow of req.body.followUps) {
        requireFields(follow, ["departmentId", "followUpExecutiveId", "action", "followUpDate"]);
        await connection.execute(
          `INSERT INTO followups
           (visit_id, customer_id, department_id, assigned_executive_id,
            action_text, followup_date, status, created_by_user_id)
           VALUES (?, ?, ?, ?, ?, ?, 'OPEN', ?)`,
          [
            visitId,
            req.body.customerId,
            follow.departmentId,
            follow.followUpExecutiveId,
            follow.action,
            follow.followUpDate,
            req.user.userId,
          ]
        );
      }
    }

    await insertEProductPromotions(visitId, req.body.eProductPromotions, connection);

    let sampling = null;
    if (req.body.sampling) {
      sampling = await createCustomerSampling(
        {
          ...req.body.sampling,
          customerId: req.body.customerId,
          customerType: req.body.customerType,
        },
        req.user,
        connection,
        visitId
      );
    }

    return { visitId, sampling };
  });

  res.status(201).json({
    status: "success",
    message: "Visit inserted successfully",
    ...result,
  });
}

async function customerSummaryForDetails(customerId) {
  if (!customerId) return null;
  const [rows] = await db.execute(
    `SELECT c.id, c.customer_name, c.address, c.email, c.mobile,
            TRIM(CONCAT(COALESCE(cc.first_name,''),' ',COALESCE(cc.last_name,''))) AS contact_name
     FROM customers c
     LEFT JOIN customer_contacts cc
       ON cc.customer_id = c.id AND cc.contact_status = 'ACTIVE' AND cc.primary_contact = 1
     WHERE c.id = ? LIMIT 1`,
    [customerId]
  );
  return rows[0] || null;
}

export async function visitDetails(req, res) {
  const where = [];
  const params = [];
  if (req.query.visitId) {
    where.push("v.id = ?");
    params.push(req.query.visitId);
  }
  if (req.query.customerId) {
    where.push("v.customer_id = ?");
    params.push(req.query.customerId);
  }
  if (!where.length) throw new AppError("visitId or customerId is required", 400);

  const [visits] = await db.execute(
    `SELECT v.*, e.executive_name, vp.name AS visit_purpose,
            TRIM(CONCAT(COALESCE(cc.first_name,''),' ',COALESCE(cc.last_name,''))) AS person_met,
            c.customer_name, c.address AS customer_address, c.email AS customer_email,
            c.mobile AS customer_mobile
     FROM visits v
     JOIN executives e ON e.id = v.executive_id
     JOIN customers c ON c.id = v.customer_id
     LEFT JOIN visit_purposes vp ON vp.id = v.visit_purpose_id
     LEFT JOIN customer_contacts cc ON cc.id = v.customer_contact_id
     WHERE ${where.join(" AND ")}
     ORDER BY v.visit_date DESC, v.id DESC`,
    params
  );

  const customer = await customerSummaryForDetails(
    req.query.customerId || visits[0]?.customer_id
  );
  const ids = visits.map((v) => v.id);
  if (!ids.length) {
    return res.json({
      status: "success",
      customer,
      visits: [],
      documents: [],
      jointExecutives: [],
      followUps: [],
      eProductPromotions: [],
    });
  }

  const placeholders = ids.map(() => "?").join(",");
  const [documents] = await db.execute(
    `SELECT * FROM visit_documents
     WHERE visit_id IN (${placeholders}) ORDER BY visit_id, id`,
    ids
  );
  const [jointExecutives] = await db.execute(
    `SELECT vje.visit_id, e.id AS executive_id, e.executive_name
     FROM visit_joint_executives vje
     JOIN executives e ON e.id = vje.executive_id
     WHERE vje.visit_id IN (${placeholders})
     ORDER BY vje.visit_id, e.executive_name`,
    ids
  );
  const [followUps] = await db.execute(
    `SELECT * FROM followups
     WHERE visit_id IN (${placeholders}) ORDER BY visit_id, followup_date`,
    ids
  );
  const [eProductPromotions] = await db.execute(
    `SELECT vep.*, b.brand_name, ep.product_name, ss.stage_name, p.prospect_name
     FROM visit_eproduct_promotions vep
     JOIN brands b ON b.id = vep.brand_id
     JOIN e_products ep ON ep.id = vep.e_product_id
     JOIN sales_stages ss ON ss.id = vep.sales_stage_id
     JOIN prospects p ON p.id = vep.prospect_id
     WHERE vep.visit_id IN (${placeholders})
     ORDER BY vep.visit_id, vep.id`,
    ids
  );

  res.json({
    status: "success",
    customer,
    visits,
    documents,
    jointExecutives,
    followUps,
    eProductPromotions,
  });
}
