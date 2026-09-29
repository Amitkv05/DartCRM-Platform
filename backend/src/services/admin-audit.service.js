import { db } from "../config/db.js";

export async function createAdminRequestHistory({
  approvalRequestId,
  moduleName,
  entityId,
  requestNumber,
  requestedByExecutiveId,
  currentApproverExecutiveId = null,
  currentLevel = 0,
  status = "PENDING",
}, executor = db) {
  await executor.execute(
    `INSERT INTO admin_request_history
      (approval_request_id, module_name, entity_id, request_number, requested_by_executive_id,
       current_approver_executive_id, current_level, status, last_action, last_action_by_executive_id,
       last_action_level, last_remarks)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'SUBMITTED', ?, 0, 'Request submitted')
     ON DUPLICATE KEY UPDATE
       current_approver_executive_id = VALUES(current_approver_executive_id),
       current_level = VALUES(current_level), status = VALUES(status), updated_at = CURRENT_TIMESTAMP`,
    [approvalRequestId, moduleName, entityId, requestNumber, requestedByExecutiveId,
     currentApproverExecutiveId, currentLevel, status, requestedByExecutiveId]
  );
}

export async function updateAdminRequestHistory({
  approvalRequestId,
  status,
  currentApproverExecutiveId = null,
  currentLevel = 0,
  lastAction,
  lastActionByExecutiveId,
  lastActionLevel = 0,
  remarks = null,
}, executor = db) {
  await executor.execute(
    `UPDATE admin_request_history
     SET status = ?, current_approver_executive_id = ?, current_level = ?,
         last_action = ?, last_action_by_executive_id = ?, last_action_level = ?,
         last_remarks = ?, completed_at = CASE WHEN ? IN ('APPROVED','REJECTED') THEN CURRENT_TIMESTAMP ELSE NULL END,
         updated_at = CURRENT_TIMESTAMP
     WHERE approval_request_id = ?`,
    [status, currentApproverExecutiveId, currentLevel, lastAction, lastActionByExecutiveId,
     lastActionLevel, remarks, status, approvalRequestId]
  );
}

export async function reassignAdminRequestHistory({ approvalRequestId, currentApproverExecutiveId, currentLevel }, executor = db) {
  await executor.execute(
    `UPDATE admin_request_history
     SET current_approver_executive_id = ?, current_level = ?, updated_at = CURRENT_TIMESTAMP
     WHERE approval_request_id = ?`,
    [currentApproverExecutiveId, currentLevel, approvalRequestId]
  );
}
