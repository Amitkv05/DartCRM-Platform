-- CRM backend -> V3 approval workflow upgrade.
-- Run ONCE on the existing CRM V2 database after taking a backup.
-- This migration does not delete business data.

ALTER TABLE executives
  ADD COLUMN approval_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER manager_executive_id;

ALTER TABLE menus
  ADD COLUMN requires_approval_role TINYINT(1) NOT NULL DEFAULT 0 AFTER sort_order,
  ADD COLUMN admin_only TINYINT(1) NOT NULL DEFAULT 0 AFTER requires_approval_role;

-- Existing managers/admin are enabled by default; L1 remains request-only.
UPDATE executives e
JOIN profiles p ON p.id = e.profile_id
SET e.approval_enabled = CASE WHEN p.level_rank >= 2 THEN 1 ELSE 0 END;

CREATE TABLE IF NOT EXISTS customer_change_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT UNSIGNED NOT NULL,
  requested_by_executive_id BIGINT UNSIGNED NOT NULL,
  proposed_payload JSON NOT NULL,
  original_snapshot JSON NOT NULL,
  status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  CONSTRAINT fk_ccr_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  CONSTRAINT fk_ccr_exec FOREIGN KEY (requested_by_executive_id) REFERENCES executives(id),
  INDEX idx_ccr_customer_status (customer_id, status),
  INDEX idx_ccr_requester (requested_by_executive_id, status)
) ENGINE=InnoDB;

-- Allow an explicit final approval action in the audit trail.
ALTER TABLE approval_history
  MODIFY COLUMN action ENUM('SUBMITTED','APPROVED_LEVEL','APPROVED_FINAL','REJECTED') NOT NULL;

-- Reuse existing sampling approval menu rows when present.
UPDATE menus
SET child_menu_name = 'Customer Sampling Approval',
    route_path = '/approvals/customer-sampling',
    sort_order = 40,
    requires_approval_role = 1,
    admin_only = 0
WHERE child_menu_name IN ('Sampling Approval','Customer Sampling Approval')
   OR route_path IN ('/sampling/approvals','/approvals/customer-sampling');

UPDATE menus
SET child_menu_name = 'Self-Stock Approval',
    route_path = '/approvals/self-stock',
    sort_order = 41,
    requires_approval_role = 1,
    admin_only = 0
WHERE child_menu_name = 'Self-Stock Approval'
   OR route_path IN ('/self-stock/approvals','/approvals/self-stock');

-- Mark approval menus and keep request menus non-approval.
UPDATE menus SET requires_approval_role = 1
WHERE route_path IN ('/approvals/customer-sampling','/approvals/self-stock');

-- Add missing approval/admin menu rows without duplicating them.
INSERT INTO menus (menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only)
SELECT 'Customer Approvals','Customer Create Approval','/approvals/customer-create',50,1,0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE route_path='/approvals/customer-create');

INSERT INTO menus (menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only)
SELECT 'Customer Approvals','Customer Update Approval','/approvals/customer-update',51,1,0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE route_path='/approvals/customer-update');

INSERT INTO menus (menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only)
SELECT 'Customer Approvals','Customer Delete Approval','/approvals/customer-delete',52,1,0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE route_path='/approvals/customer-delete');

INSERT INTO menus (menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only)
SELECT 'Customer Approvals','Contact Approval','/approvals/contact-create',53,1,0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE route_path='/approvals/contact-create');

INSERT INTO menus (menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only)
SELECT 'Visit/DSR','Visit Backdate Approval','/approvals/visit-backdate',23,1,0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE route_path='/approvals/visit-backdate');

INSERT INTO menus (menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only)
SELECT 'Admin','Approval Role Management','/admin/approval-roles',90,0,1
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE route_path='/admin/approval-roles');

INSERT INTO menus (menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only)
SELECT 'Visit/DSR','Visit Backdate Request','/visits/backdate-request',24,0,0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE route_path='/visits/backdate-request');

-- Add the new request menu to every active profile.
INSERT IGNORE INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id FROM profiles p JOIN menus m ON m.route_path='/visits/backdate-request';

-- All non-admin, non-approval menus remain available according to their current profile mapping.
-- Remove approval menus from L1 regardless of previous seed data.
DELETE pm FROM profile_menus pm
JOIN profiles p ON p.id = pm.profile_id
JOIN menus m ON m.id = pm.menu_id
WHERE p.level_rank = 1 AND m.requires_approval_role = 1;

-- Add approval menus to L2+ profiles. The runtime menu API additionally checks executive.approval_enabled.
INSERT IGNORE INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id
FROM profiles p
JOIN menus m ON m.requires_approval_role = 1 AND m.admin_only = 0
WHERE p.level_rank >= 2;

-- Admin-only menu is mapped only to admin profiles.
DELETE pm FROM profile_menus pm
JOIN menus m ON m.id = pm.menu_id
JOIN profiles p ON p.id = pm.profile_id
WHERE m.admin_only = 1 AND p.is_admin = 0;

INSERT IGNORE INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id
FROM profiles p
JOIN menus m ON m.admin_only = 1
WHERE p.is_admin = 1;

SELECT '003_approval_workflow_v3 migration completed' AS result;
