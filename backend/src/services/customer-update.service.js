import { AppError } from "../utils/AppError.js";
import { toFlag } from "../utils/validation.js";

export async function applyCustomerUpdate(customerId, body, executor) {
  const [rows] = await executor.execute("SELECT * FROM customers WHERE id = ? FOR UPDATE", [customerId]);
  const existing = rows[0];
  if (!existing) throw new AppError("Customer not found", 404);
  const customerType = String(body.customerType || existing.customer_type).toUpperCase();

  await executor.execute(
    `UPDATE customers SET customer_name = ?, ref_code = ?, email = ?, mobile = ?, address = ?, city_id = ?,
     pincode = ?, key_customer = ?, customer_status = ?, latitude = ?, longitude = ?, gst_number = ?, pan_number = ?
     WHERE id = ?`,
    [body.customerName ?? existing.customer_name, body.refCode ?? existing.ref_code,
     body.email ?? existing.email, body.mobile ?? existing.mobile, body.address ?? existing.address,
     body.cityId ?? existing.city_id, body.pincode ?? existing.pincode,
     body.keyCustomer === undefined ? existing.key_customer : toFlag(body.keyCustomer),
     body.customerStatus ? String(body.customerStatus).toUpperCase() : existing.customer_status,
     body.latitude ?? existing.latitude, body.longitude ?? existing.longitude,
     body.gstNumber ?? existing.gst_number, body.panNumber ?? existing.pan_number, customerId]
  );

  if (Array.isArray(body.categoryIds)) {
    await executor.execute("DELETE FROM customer_category_map WHERE customer_id = ?", [customerId]);
    for (const categoryId of body.categoryIds) {
      await executor.execute(
        "INSERT INTO customer_category_map (customer_id, category_id) VALUES (?, ?)",
        [customerId, categoryId]
      );
    }
  }

  if (Array.isArray(body.executiveIds)) {
    await executor.execute("DELETE FROM customer_executives WHERE customer_id = ?", [customerId]);
    for (const executiveId of body.executiveIds) {
      await executor.execute(
        "INSERT INTO customer_executives (customer_id, executive_id) VALUES (?, ?)",
        [customerId, executiveId]
      );
    }
  }

  if (customerType === "SCHOOL" && body.school) {
    const school = body.school;
    await executor.execute(
      `INSERT INTO customer_school_details
       (customer_id, board_id, chain_school_id, start_class_id, end_class_id, medium_instruction,
        ranking, sampling_month, decision_month, purchase_mode_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE board_id=VALUES(board_id), chain_school_id=VALUES(chain_school_id),
       start_class_id=VALUES(start_class_id), end_class_id=VALUES(end_class_id),
       medium_instruction=VALUES(medium_instruction), ranking=VALUES(ranking),
       sampling_month=VALUES(sampling_month), decision_month=VALUES(decision_month),
       purchase_mode_id=VALUES(purchase_mode_id)`,
      [customerId, school.boardId || null, school.chainSchoolId || null,
       school.startClassId || null, school.endClassId || null,
       school.mediumInstruction || null, school.ranking || null,
       school.samplingMonth || null, school.decisionMonth || null,
       school.purchaseModeId || null]
    );
  }
}
