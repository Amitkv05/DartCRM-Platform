-- CRM backend patch for an already-created database.
-- Safe for the current demo database: it only realigns the dynamic Flutter menus
-- and refreshes the known Visit/Sampling master values.

START TRANSACTION;

DELETE FROM profile_menus;
DELETE FROM menus;

INSERT INTO menus (id, menu_name, child_menu_name, route_path, sort_order, is_active) VALUES
(1,'Customer','School List','/customers/school',10,1),
(2,'Customer','Trade List','/customers/trade',11,1),
(3,'Customer','Library List','/customers/library',12,1),
(4,'Visit/DSR','View Today''s Plan','/plans/today',20,1),
(5,'Visit/DSR','View Tomorrow''s Plan','/plans/tomorrow',21,1),
(6,'Visit/DSR','Visit Entry','/visits/new',22,1),
(7,'Sampling','School Sampling','/sampling/school',30,1),
(8,'Sampling','Trade Sampling','/sampling/trade',31,1),
(9,'Sampling','Library Sampling','/sampling/library',32,1),
(10,'Sampling','Sampling Approval','/sampling/approvals',33,1),
(11,'Sampling','Self-Stock Request','/self-stock',34,1),
(12,'Sampling','Self-Stock Approval','/self-stock/approvals',35,1);

INSERT INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id FROM profiles p CROSS JOIN menus m WHERE m.is_active = 1;

INSERT INTO application_setup (key_name, key_value, description, is_active)
VALUES
('VisitBooksSampling','Y','Show book sampling controls during Visit/DSR entry.',1),
('VisitEProducts','Y','Show E-Product promotion controls during Visit/DSR entry.',1)
ON DUPLICATE KEY UPDATE
  key_value = VALUES(key_value),
  description = VALUES(description),
  is_active = 1;

COMMIT;
