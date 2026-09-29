import { db, withTransaction } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { getSetupMap } from "../../services/setup.service.js";
import { createApproval } from "../../services/approval.service.js";
import { requireFields, toFlag } from "../../utils/validation.js";

function validateContact(body, setup) {
  requireFields(body, ["customerId", "customerType", "contactStatus", "designationId"]);
  const nameRule = String(setup.CustomerContactFirstLastNameMandatory || "F").toUpperCase();
  if (["F", "B"].includes(nameRule) && !body.firstName) throw new AppError("firstName is required", 400);
  if (["L", "B"].includes(nameRule) && !body.lastName) throw new AppError("lastName is required", 400);
  const customerType = String(body.customerType || "").toUpperCase();
  const commKey = customerType === "SCHOOL" ? "TeacherMobileEmailMandatory" : "CustomerContactMobileEmailMandatory";
  const commRule = String(setup[commKey] || "N").toUpperCase();
  if (commRule === "M" && !body.mobile) throw new AppError("mobile is required", 400);
  if (commRule === "E" && !body.email) throw new AppError("email is required", 400);
  if (commRule === "B" && (!body.mobile || !body.email)) throw new AppError("mobile and email are required", 400);
  if (commRule === "A" && !body.mobile && !body.email) throw new AppError("mobile or email is required", 400);
}

export async function listContacts(req, res) {
  const [rows] = await db.execute(
    `SELECT cc.id, cc.customer_id, cc.primary_contact, cc.first_name, cc.last_name, cc.email, cc.mobile,
            cc.contact_status, cc.validation_status, cd.name AS designation
     FROM customer_contacts cc LEFT JOIN contact_designations cd ON cd.id = cc.designation_id
     WHERE cc.customer_id = ? ORDER BY cc.primary_contact DESC, cc.id`, [req.params.customerId]
  );
  res.json({ status: "success", contacts: rows });
}

export async function getContact(req, res) {
  const [rows] = await db.execute("SELECT * FROM customer_contacts WHERE id = ? LIMIT 1", [req.params.id]);
  if (!rows[0]) throw new AppError("Contact not found", 404);
  res.json({ status: "success", contact: rows[0] });
}

export async function createContact(req, res) {
  const result = await withTransaction(async (connection) => {
    const setup = await getSetupMap(connection);
    validateContact(req.body, setup);
    const [customerRows] = await connection.execute("SELECT validation_status FROM customers WHERE id = ? LIMIT 1", [req.body.customerId]);
    const customer = customerRows[0];
    if (!customer) throw new AppError("Customer not found", 404);
    if (customer.validation_status !== "VALIDATED") throw new AppError("Contact cannot be created because customer is not validated", 409);

    const direct = String(setup.ApprovedContactsNew || "").split(",").map((x) => x.trim().toUpperCase()).includes(req.user.profileCode.toUpperCase());
    const customerType = String(req.body.customerType).toUpperCase();
    const contactStatus = String(req.body.contactStatus).toUpperCase();
    if (!["SCHOOL", "INSTITUTE", "TRADE", "LIBRARY"].includes(customerType)) throw new AppError("Invalid customerType", 400);
    if (!["ACTIVE", "INACTIVE"].includes(contactStatus)) throw new AppError("contactStatus must be ACTIVE or INACTIVE", 400);
    const [insert] = await connection.execute(
      `INSERT INTO customer_contacts
        (customer_id, customer_type, primary_contact, salutation_id, designation_id, first_name, last_name,
         email, mobile, contact_status, validation_status, residential_address, residential_city_id,
         residential_pincode, birthday, anniversary, data_source_id, created_by_user_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [req.body.customerId, customerType, toFlag(req.body.primaryContact), req.body.salutationId || null,
       req.body.designationId, req.body.firstName || null, req.body.lastName || null, req.body.email || null,
       req.body.mobile || null, contactStatus, direct ? "VALIDATED" : "PENDING_APPROVAL",
       req.body.residentialAddress || null, req.body.residentialCityId || null, req.body.residentialPincode || null,
       req.body.birthday || null, req.body.anniversary || null, req.body.dataSourceId || null, req.user.userId]
    );
    let approval = null;
    if (!direct) {
      approval = await createApproval({
        moduleName: "CONTACT_CREATE",
        entityId: insert.insertId,
        requestNumber: `CONT-${insert.insertId}`,
        requestedByExecutiveId: req.user.executiveId,
      }, connection);
      if (approval.autoApproved) {
        await connection.execute("UPDATE customer_contacts SET validation_status = 'VALIDATED' WHERE id = ?", [insert.insertId]);
      }
    }
    return { contactId: insert.insertId, validationStatus: direct || approval?.autoApproved ? "VALIDATED" : "PENDING_APPROVAL", approval };
  });
  res.status(201).json({ status: "success", ...result });
}

export async function updateContact(req, res) {
  const setup = await getSetupMap();
  validateContact(req.body, setup);
  const contactStatus = String(req.body.contactStatus).toUpperCase();
  if (!["ACTIVE", "INACTIVE"].includes(contactStatus)) throw new AppError("contactStatus must be ACTIVE or INACTIVE", 400);
  await db.execute(
    `UPDATE customer_contacts SET primary_contact = ?, salutation_id = ?, designation_id = ?, first_name = ?,
       last_name = ?, email = ?, mobile = ?, contact_status = ?, residential_address = ?, residential_city_id = ?,
       residential_pincode = ?, birthday = ?, anniversary = ?, data_source_id = ?, updated_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [toFlag(req.body.primaryContact), req.body.salutationId || null, req.body.designationId,
     req.body.firstName || null, req.body.lastName || null, req.body.email || null, req.body.mobile || null,
     contactStatus, req.body.residentialAddress || null, req.body.residentialCityId || null,
     req.body.residentialPincode || null, req.body.birthday || null, req.body.anniversary || null,
     req.body.dataSourceId || null, req.params.id]
  );
  res.json({ status: "success", message: "Customer contact updated successfully" });
}

export async function deleteContact(req, res) {
  await withTransaction(async (connection) => {
    const [rows] = await connection.execute("SELECT * FROM customer_contacts WHERE id = ? FOR UPDATE", [req.params.id]);
    if (!rows[0]) throw new AppError("Contact not found", 404);
    await connection.execute("UPDATE customer_contacts SET contact_status = 'DELETED', updated_at = CURRENT_TIMESTAMP WHERE id = ?", [req.params.id]);
  });
  res.json({ status: "success", message: "Customer contact deleted successfully" });
}
