import { applyCustomerUpdate } from "./customer-update.service.js";
import { getSetupValue } from "./setup.service.js";

async function applySamplingBudget(moduleName, requestId, executor) {
  const isCustomer = moduleName === "CUSTOMER_SAMPLING";
  const requestTable = isCustomer ? "customer_sampling_requests" : "self_stock_requests";
  const itemTable = isCustomer ? "customer_sampling_request_items" : "self_stock_request_items";
  const [requestRows] = await executor.execute(
    `SELECT executive_id FROM ${requestTable} WHERE id = ? LIMIT 1`,
    [requestId]
  );
  const request = requestRows[0];
  if (!request) return;

  const [items] = await executor.execute(
    `SELECT book_id, COALESCE(approved_qty, requested_qty) AS qty, unit_price
     FROM ${itemTable} WHERE request_id = ?`,
    [requestId]
  );
  const budgetType = (await getSetupValue("SamplingBudgetType", executor) || "units").toLowerCase();
  const budgetFor = (await getSetupValue("SamplingBudgetFor", executor) || "overall").toLowerCase();
  const year = new Date().getUTCFullYear();

  if (budgetFor === "titlewise") {
    for (const item of items) {
      const units = Number(item.qty || 0);
      const value = units * Number(item.unit_price || 0);
      if (budgetType === "value") {
        await executor.execute(
          `UPDATE sampling_budgets SET used_value = used_value + ?
           WHERE executive_id = ? AND budget_year = ? AND book_id = ?`,
          [value, request.executive_id, year, item.book_id]
        );
      } else {
        await executor.execute(
          `UPDATE sampling_budgets SET used_units = used_units + ?
           WHERE executive_id = ? AND budget_year = ? AND book_id = ?`,
          [units, request.executive_id, year, item.book_id]
        );
      }
    }
  } else {
    const units = items.reduce((sum, item) => sum + Number(item.qty || 0), 0);
    const value = items.reduce((sum, item) => sum + Number(item.qty || 0) * Number(item.unit_price || 0), 0);
    if (budgetType === "value") {
      await executor.execute(
        `UPDATE sampling_budgets SET used_value = used_value + ?
         WHERE executive_id = ? AND budget_year = ? AND book_id IS NULL`,
        [value, request.executive_id, year]
      );
    } else {
      await executor.execute(
        `UPDATE sampling_budgets SET used_units = used_units + ?
         WHERE executive_id = ? AND budget_year = ? AND book_id IS NULL`,
        [units, request.executive_id, year]
      );
    }
  }
}

export async function finalizeApproval(moduleName, entityId, status, executor) {
  if (moduleName === "CUSTOMER_CREATE") {
    const validation = status === "APPROVED" ? "VALIDATED" : "REJECTED";
    await executor.execute("UPDATE customers SET validation_status = ? WHERE id = ?", [validation, entityId]);
    await executor.execute(
      "UPDATE customer_contacts SET validation_status = ? WHERE customer_id = ? AND validation_status = 'PENDING_APPROVAL'",
      [validation, entityId]
    );
  } else if (moduleName === "CUSTOMER_UPDATE") {
    const [rows] = await executor.execute(
      "SELECT * FROM customer_change_requests WHERE id = ? FOR UPDATE",
      [entityId]
    );
    const change = rows[0];
    if (!change) return;
    if (status === "APPROVED") {
      const proposed = typeof change.proposed_payload === "string"
        ? JSON.parse(change.proposed_payload)
        : change.proposed_payload;
      await applyCustomerUpdate(change.customer_id, proposed || {}, executor);
    }
    await executor.execute(
      "UPDATE customer_change_requests SET status = ?, completed_at = CURRENT_TIMESTAMP WHERE id = ?",
      [status, entityId]
    );
  } else if (moduleName === "CONTACT_CREATE") {
    await executor.execute(
      "UPDATE customer_contacts SET validation_status = ? WHERE id = ?",
      [status === "APPROVED" ? "VALIDATED" : "REJECTED", entityId]
    );
  } else if (moduleName === "CUSTOMER_DELETE") {
    if (status === "APPROVED") {
      await executor.execute(
        "UPDATE customers SET customer_status = 'INACTIVE', delete_request_status = 'APPROVED' WHERE id = ?",
        [entityId]
      );
    } else {
      await executor.execute(
        "UPDATE customers SET delete_request_status = 'REJECTED' WHERE id = ?",
        [entityId]
      );
    }
  } else if (moduleName === "CUSTOMER_SAMPLING") {
    await executor.execute(
      "UPDATE customer_sampling_requests SET approval_status = ?, request_status = ? WHERE id = ?",
      [status, status, entityId]
    );
    if (status === "APPROVED") await applySamplingBudget("CUSTOMER_SAMPLING", entityId, executor);
  } else if (moduleName === "SELF_STOCK") {
    await executor.execute(
      "UPDATE self_stock_requests SET approval_status = ?, request_status = ? WHERE id = ?",
      [status, status, entityId]
    );
    if (status === "APPROVED") await applySamplingBudget("SELF_STOCK", entityId, executor);
  } else if (moduleName === "VISIT_BACKDATE") {
    await executor.execute(
      "UPDATE backdate_requests SET status = ? WHERE id = ?",
      [status, entityId]
    );
  }
}
