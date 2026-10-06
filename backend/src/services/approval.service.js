import { db } from "../config/db.js";
import { AppError } from "../utils/AppError.js";
import { getNextEligibleApprover } from "./hierarchy.service.js";
import { createNotification } from "./notification.service.js";
import { createAdminRequestHistory, updateAdminRequestHistory } from "./admin-audit.service.js";

async function assertApprovalEnabled(executiveId, executor = db) {
  const [rows] = await executor.execute(
    `SELECT e.approval_enabled, e.status, p.level_rank, p.is_admin
     FROM executives e
     JOIN profiles p ON p.id = e.profile_id
     WHERE e.id = ? LIMIT 1`,
    [executiveId]
  );
  const executive = rows[0];
  if (!executive || executive.status !== "ACTIVE" || Number(executive.approval_enabled) !== 1) {
    throw new AppError("Your account is not allowed to approve requests", 403);
  }
  if (Number(executive.level_rank) <= 1 && Number(executive.is_admin || 0) !== 1) {
    throw new AppError("L1 executives are request-only and cannot approve requests", 403);
  }
}

export async function createApproval({ moduleName, entityId, requestNumber, requestedByExecutiveId }, executor = db) {
  // One module/entity pair is unique in the database. A terminal REJECTED request
  // must therefore be reopened instead of inserting a second approval row.
  const [existingRows] = await executor.execute(
    `SELECT * FROM approval_requests
     WHERE module_name = ? AND entity_id = ?
     LIMIT 1 FOR UPDATE`,
    [moduleName, entityId]
  );
  const existing = existingRows[0];

  if (existing?.status === "PENDING") {
    throw new AppError("Approval request is already pending", 409);
  }
  if (existing?.status === "APPROVED") {
    throw new AppError("Approval request is already approved", 409);
  }

  const firstApprover = await getNextEligibleApprover(requestedByExecutiveId, executor);

  if (!firstApprover) {
    let approvalId;

    if (existing?.status === "REJECTED") {
      approvalId = existing.id;
      await executor.execute(
        `UPDATE approval_requests
         SET request_number = ?, requested_by_executive_id = ?,
             current_approver_executive_id = NULL, current_level = 0,
             status = 'APPROVED', completed_at = CURRENT_TIMESTAMP,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [requestNumber, requestedByExecutiveId, approvalId]
      );
    } else {
      const [result] = await executor.execute(
        `INSERT INTO approval_requests
          (module_name, entity_id, request_number, requested_by_executive_id,
           current_approver_executive_id, current_level, status, completed_at)
         VALUES (?, ?, ?, ?, NULL, 0, 'APPROVED', CURRENT_TIMESTAMP)`,
        [moduleName, entityId, requestNumber, requestedByExecutiveId]
      );
      approvalId = result.insertId;
    }

    await executor.execute(
      `INSERT INTO approval_history
        (approval_request_id, module_name, entity_id, approval_level, action, action_by_executive_id, remarks)
       VALUES (?, ?, ?, 0, 'SUBMITTED', ?, ?),
              (?, ?, ?, 0, 'APPROVED_FINAL', ?, 'Auto-approved because no higher eligible approver exists')`,
      [approvalId, moduleName, entityId, requestedByExecutiveId,
       existing?.status === "REJECTED" ? "Request resubmitted" : "Request submitted",
       approvalId, moduleName, entityId, requestedByExecutiveId]
    );

    if (existing?.status === "REJECTED") {
      await updateAdminRequestHistory({
        approvalRequestId: approvalId,
        status: "APPROVED",
        currentApproverExecutiveId: null,
        currentLevel: 0,
        lastAction: "APPROVED_FINAL",
        lastActionByExecutiveId: requestedByExecutiveId,
        lastActionLevel: 0,
        remarks: "Auto-approved because no higher eligible approver exists",
      }, executor);
    } else {
      await createAdminRequestHistory({
        approvalRequestId: approvalId,
        moduleName,
        entityId,
        requestNumber,
        requestedByExecutiveId,
        currentApproverExecutiveId: null,
        currentLevel: 0,
        status: "APPROVED",
      }, executor);
      await updateAdminRequestHistory({
        approvalRequestId: approvalId,
        status: "APPROVED",
        currentApproverExecutiveId: null,
        currentLevel: 0,
        lastAction: "APPROVED_FINAL",
        lastActionByExecutiveId: requestedByExecutiveId,
        lastActionLevel: 0,
        remarks: "Auto-approved because no higher eligible approver exists",
      }, executor);
    }

    return { autoApproved: true, approvalId, currentApprover: null, level: 0 };
  }

  const firstApproverId = Number.parseInt(firstApprover.id, 10);
  const firstLevel = Number.parseInt(firstApprover.level_rank, 10);
  if (!Number.isInteger(firstApproverId) || !Number.isInteger(firstLevel)) {
    throw new AppError("Approver hierarchy/profile configuration is incomplete", 500);
  }

  let approvalId;
  if (existing?.status === "REJECTED") {
    approvalId = existing.id;
    await executor.execute(
      `UPDATE approval_requests
       SET request_number = ?, requested_by_executive_id = ?,
           current_approver_executive_id = ?, current_level = ?,
           status = 'PENDING', completed_at = NULL,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [requestNumber, requestedByExecutiveId, firstApproverId, firstLevel, approvalId]
    );
  } else {
    const [result] = await executor.execute(
      `INSERT INTO approval_requests
        (module_name, entity_id, request_number, requested_by_executive_id, current_approver_executive_id, current_level, status)
       VALUES (?, ?, ?, ?, ?, ?, 'PENDING')`,
      [moduleName, entityId, requestNumber, requestedByExecutiveId, firstApproverId, firstLevel]
    );
    approvalId = result.insertId;
  }

  await executor.execute(
    `INSERT INTO approval_history
      (approval_request_id, module_name, entity_id, approval_level, action, action_by_executive_id, remarks)
     VALUES (?, ?, ?, 0, 'SUBMITTED', ?, ?)`,
    [approvalId, moduleName, entityId, requestedByExecutiveId,
     existing?.status === "REJECTED" ? "Request resubmitted" : "Request submitted"]
  );

  if (existing?.status === "REJECTED") {
    await updateAdminRequestHistory({
      approvalRequestId: approvalId,
      status: "PENDING",
      currentApproverExecutiveId: firstApproverId,
      currentLevel: firstLevel,
      lastAction: "SUBMITTED",
      lastActionByExecutiveId: requestedByExecutiveId,
      lastActionLevel: 0,
      remarks: "Request resubmitted",
    }, executor);
  } else {
    await createAdminRequestHistory({
      approvalRequestId: approvalId,
      moduleName,
      entityId,
      requestNumber,
      requestedByExecutiveId,
      currentApproverExecutiveId: firstApproverId,
      currentLevel: firstLevel,
      status: "PENDING",
    }, executor);
  }

  await createNotification({
    executiveId: firstApproverId,
    title: `${moduleName} approval required`,
    message: `${requestNumber} is waiting for your approval.`,
    module: moduleName,
    entityId,
  }, executor);

  return { autoApproved: false, approvalId, currentApprover: firstApproverId, level: firstLevel };
}

export async function getApprovalForUpdate(approvalId, executor = db) {
  const [rows] = await executor.execute(
    "SELECT * FROM approval_requests WHERE id = ? FOR UPDATE",
    [approvalId]
  );
  const approval = rows[0];
  if (!approval) throw new AppError("Approval request not found", 404);
  return approval;
}

/**
 * APPROVE + sendToNextLevel=true  => move to next eligible approval-enabled manager.
 * APPROVE + sendToNextLevel=false => final approval immediately.
 * REJECT                           => terminal rejection.
 */
export async function actOnApproval({
  approvalId,
  actorExecutiveId,
  action,
  remarks = null,
  sendToNextLevel = false,
}, executor = db) {
  const approval = await getApprovalForUpdate(approvalId, executor);
  if (approval.status !== "PENDING") throw new AppError(`Request is already ${approval.status}`, 409);
  if (Number(approval.current_approver_executive_id) !== Number(actorExecutiveId)) {
    throw new AppError("This request is not assigned to you", 403);
  }

  await assertApprovalEnabled(actorExecutiveId, executor);

  if (action === "REJECT") {
    if (!remarks || !String(remarks).trim()) throw new AppError("Remarks are required when rejecting", 400);
    await executor.execute(
      `UPDATE approval_requests
       SET status = 'REJECTED', completed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [approvalId]
    );
    await executor.execute(
      `INSERT INTO approval_history
        (approval_request_id, module_name, entity_id, approval_level, action, action_by_executive_id, remarks)
       VALUES (?, ?, ?, ?, 'REJECTED', ?, ?)`,
      [approvalId, approval.module_name, approval.entity_id, approval.current_level, actorExecutiveId, remarks]
    );
    await updateAdminRequestHistory({
      approvalRequestId: approvalId,
      status: "REJECTED",
      currentApproverExecutiveId: null,
      currentLevel: approval.current_level,
      lastAction: "REJECTED",
      lastActionByExecutiveId: actorExecutiveId,
      lastActionLevel: approval.current_level,
      remarks,
    }, executor);
    await createNotification({
      executiveId: approval.requested_by_executive_id,
      title: `${approval.module_name} rejected`,
      message: `${approval.request_number} was rejected.`,
      module: approval.module_name,
      entityId: approval.entity_id,
    }, executor);
    return { approval, final: true, status: "REJECTED", nextApprover: null };
  }

  if (!sendToNextLevel) {
    await executor.execute(
      `INSERT INTO approval_history
        (approval_request_id, module_name, entity_id, approval_level, action, action_by_executive_id, remarks)
       VALUES (?, ?, ?, ?, 'APPROVED_FINAL', ?, ?)`,
      [approvalId, approval.module_name, approval.entity_id, approval.current_level, actorExecutiveId,
       remarks || "Approved as final at this level"]
    );
    await executor.execute(
      `UPDATE approval_requests
       SET status = 'APPROVED', current_approver_executive_id = NULL,
           completed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [approvalId]
    );
    await updateAdminRequestHistory({
      approvalRequestId: approvalId,
      status: "APPROVED",
      currentApproverExecutiveId: null,
      currentLevel: approval.current_level,
      lastAction: "APPROVED_FINAL",
      lastActionByExecutiveId: actorExecutiveId,
      lastActionLevel: approval.current_level,
      remarks: remarks || "Approved as final at this level",
    }, executor);
    await createNotification({
      executiveId: approval.requested_by_executive_id,
      title: `${approval.module_name} approved`,
      message: `${approval.request_number} received final approval.`,
      module: approval.module_name,
      entityId: approval.entity_id,
    }, executor);
    return { approval, final: true, status: "APPROVED", nextApprover: null };
  }

  await executor.execute(
    `INSERT INTO approval_history
      (approval_request_id, module_name, entity_id, approval_level, action, action_by_executive_id, remarks)
     VALUES (?, ?, ?, ?, 'APPROVED_LEVEL', ?, ?)`,
    [approvalId, approval.module_name, approval.entity_id, approval.current_level, actorExecutiveId, remarks]
  );

  const nextApprover = await getNextEligibleApprover(actorExecutiveId, executor);
  if (!nextApprover) {
    await executor.execute(
      `UPDATE approval_requests
       SET status = 'APPROVED', current_approver_executive_id = NULL,
           completed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [approvalId]
    );
    await updateAdminRequestHistory({
      approvalRequestId: approvalId,
      status: "APPROVED",
      currentApproverExecutiveId: null,
      currentLevel: approval.current_level,
      lastAction: "APPROVED_FINAL",
      lastActionByExecutiveId: actorExecutiveId,
      lastActionLevel: approval.current_level,
      remarks: remarks || "Approved at highest eligible level",
    }, executor);
    await createNotification({
      executiveId: approval.requested_by_executive_id,
      title: `${approval.module_name} approved`,
      message: `${approval.request_number} received final approval.`,
      module: approval.module_name,
      entityId: approval.entity_id,
    }, executor);
    return { approval, final: true, status: "APPROVED", nextApprover: null };
  }

  const nextLevel = Number(nextApprover.level_rank);
  await executor.execute(
    `UPDATE approval_requests
     SET current_approver_executive_id = ?, current_level = ?, updated_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [nextApprover.id, nextLevel, approvalId]
  );
  await updateAdminRequestHistory({
    approvalRequestId: approvalId,
    status: "PENDING",
    currentApproverExecutiveId: nextApprover.id,
    currentLevel: nextLevel,
    lastAction: "APPROVED_LEVEL",
    lastActionByExecutiveId: actorExecutiveId,
    lastActionLevel: approval.current_level,
    remarks,
  }, executor);
  await createNotification({
    executiveId: nextApprover.id,
    title: `${approval.module_name} approval required`,
    message: `${approval.request_number} is pending for approval level ${nextLevel}.`,
    module: approval.module_name,
    entityId: approval.entity_id,
  }, executor);

  return { approval, final: false, status: "PENDING", nextApprover: nextApprover.id, nextLevel };
}
