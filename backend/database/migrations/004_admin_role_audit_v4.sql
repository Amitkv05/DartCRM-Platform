-- CRM V3 -> V4 Admin & Audit upgrade.
-- Run ONCE on an existing V3 database after taking a backup.

ALTER TABLE executives
  ADD COLUMN menu_access_mode ENUM('PROFILE','CUSTOM') NOT NULL DEFAULT 'PROFILE' AFTER approval_enabled;

CREATE TABLE IF NOT EXISTS executive_menu_overrides (
  executive_id BIGINT UNSIGNED NOT NULL,
  menu_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (executive_id, menu_id),
  CONSTRAINT fk_emo_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE,
  CONSTRAINT fk_emo_menu FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS admin_request_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  approval_request_id BIGINT UNSIGNED NOT NULL UNIQUE,
  module_name VARCHAR(60) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  request_number VARCHAR(80) NOT NULL,
  requested_by_executive_id BIGINT UNSIGNED NOT NULL,
  current_approver_executive_id BIGINT UNSIGNED NULL,
  current_level INT NOT NULL DEFAULT 0,
  status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  last_action VARCHAR(40) NULL,
  last_action_by_executive_id BIGINT UNSIGNED NULL,
  last_action_level INT NULL,
  last_remarks VARCHAR(1000) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  CONSTRAINT fk_arh_approval FOREIGN KEY (approval_request_id) REFERENCES approval_requests(id) ON DELETE CASCADE,
  CONSTRAINT fk_arh_requester FOREIGN KEY (requested_by_executive_id) REFERENCES executives(id),
  CONSTRAINT fk_arh_current FOREIGN KEY (current_approver_executive_id) REFERENCES executives(id) ON DELETE SET NULL,
  CONSTRAINT fk_arh_last_actor FOREIGN KEY (last_action_by_executive_id) REFERENCES executives(id) ON DELETE SET NULL,
  INDEX idx_arh_status_module (status, module_name, created_at),
  INDEX idx_arh_requester (requested_by_executive_id, created_at)
) ENGINE=InnoDB;

-- Backfill admin history for all existing approval requests.
INSERT IGNORE INTO admin_request_history
(approval_request_id, module_name, entity_id, request_number, requested_by_executive_id,
 current_approver_executive_id, current_level, status, last_action, last_action_by_executive_id,
 last_action_level, last_remarks, created_at, updated_at, completed_at)
SELECT ar.id, ar.module_name, ar.entity_id, ar.request_number, ar.requested_by_executive_id,
       ar.current_approver_executive_id, ar.current_level, ar.status,
       COALESCE((SELECT ah.action FROM approval_history ah WHERE ah.approval_request_id=ar.id ORDER BY ah.id DESC LIMIT 1),'SUBMITTED'),
       COALESCE((SELECT ah.action_by_executive_id FROM approval_history ah WHERE ah.approval_request_id=ar.id ORDER BY ah.id DESC LIMIT 1), ar.requested_by_executive_id),
       COALESCE((SELECT ah.approval_level FROM approval_history ah WHERE ah.approval_request_id=ar.id ORDER BY ah.id DESC LIMIT 1),0),
       (SELECT ah.remarks FROM approval_history ah WHERE ah.approval_request_id=ar.id ORDER BY ah.id DESC LIMIT 1),
       ar.created_at, ar.updated_at, ar.completed_at
FROM approval_requests ar;

UPDATE menus
SET child_menu_name='User & Role Management', route_path='/admin/users', sort_order=90, admin_only=1
WHERE route_path='/admin/approval-roles' OR child_menu_name='Approval Role Management';

INSERT INTO menus (menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only)
SELECT 'Admin','Request & Approval History','/admin/request-history',91,0,1
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE route_path='/admin/request-history');

INSERT INTO menus (menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only)
SELECT 'Requests','My Request History','/requests/my-history',60,0,0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE route_path='/requests/my-history');

INSERT IGNORE INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id FROM profiles p JOIN menus m ON m.route_path='/requests/my-history';

INSERT IGNORE INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id FROM profiles p JOIN menus m ON m.route_path IN ('/admin/users','/admin/request-history')
WHERE p.is_admin=1;

DELETE pm FROM profile_menus pm
JOIN profiles p ON p.id=pm.profile_id
JOIN menus m ON m.id=pm.menu_id
WHERE m.admin_only=1 AND p.is_admin=0;

SELECT '004_admin_role_audit_v4 migration completed' AS result;
