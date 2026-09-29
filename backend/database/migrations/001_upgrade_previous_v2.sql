-- CRM backend - upgrade script for databases created from the FIRST V2 package.
-- Run this ONCE on your existing crm_database_v2 database before starting the
-- updated backend. It preserves existing CRM data and adds the later
-- E-Product/Visit fields plus the Flutter-compatible menu names.
--
-- IMPORTANT: select your existing database in phpMyAdmin/MySQL before running.

SET @db_name := DATABASE();

-- ---------------------------------------------------------------------------
-- 1. Classes: original E-Product APIs use values such as -1, 1, 2 as class ids.
-- ---------------------------------------------------------------------------
SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'classes' AND COLUMN_NAME = 'class_num_id') = 0,
  'ALTER TABLE classes ADD COLUMN class_num_id INT NULL AFTER id',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE classes SET class_num_id = CASE name
  WHEN 'Nry' THEN -3
  WHEN 'LKG' THEN -2
  WHEN 'UKG' THEN -1
  WHEN '1' THEN 1 WHEN '2' THEN 2 WHEN '3' THEN 3 WHEN '4' THEN 4
  WHEN '5' THEN 5 WHEN '6' THEN 6 WHEN '7' THEN 7 WHEN '8' THEN 8
  WHEN '9' THEN 9 WHEN '10' THEN 10 WHEN '11' THEN 11 WHEN '12' THEN 12
  ELSE class_num_id
END
WHERE class_num_id IS NULL;

-- ---------------------------------------------------------------------------
-- 2. E-Product master tables.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS academic_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  session_name VARCHAR(40) NOT NULL UNIQUE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS brands (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  brand_name VARCHAR(150) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sales_stages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  stage_name VARCHAR(250) NOT NULL UNIQUE,
  sequence_num INT NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS prospects (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  prospect_name VARCHAR(500) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS e_products (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  brand_id BIGINT UNSIGNED NOT NULL,
  subject_id BIGINT UNSIGNED NULL,
  product_name VARCHAR(250) NOT NULL,
  product_code VARCHAR(80) NULL,
  list_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_eproduct_brand FOREIGN KEY (brand_id) REFERENCES brands(id),
  CONSTRAINT fk_eproduct_subject FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
  UNIQUE KEY uk_eproduct_brand_code (brand_id, product_code),
  INDEX idx_eproduct_brand_name (brand_id, product_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS e_product_classes (
  e_product_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (e_product_id, class_id),
  CONSTRAINT fk_epc_product FOREIGN KEY (e_product_id) REFERENCES e_products(id) ON DELETE CASCADE,
  CONSTRAINT fk_epc_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- 3. Visit columns added for the documented E-Product Visit Entry payload.
-- ---------------------------------------------------------------------------
SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'visits' AND COLUMN_NAME = 'other_visit_purpose') = 0,
  'ALTER TABLE visits ADD COLUMN other_visit_purpose VARCHAR(500) NULL AFTER visit_purpose_id',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'visits' AND COLUMN_NAME = 'send_thankyou_mail') = 0,
  'ALTER TABLE visits ADD COLUMN send_thankyou_mail TINYINT(1) NOT NULL DEFAULT 0 AFTER request_remarks',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'visits' AND COLUMN_NAME = 'mail_content_type') = 0,
  'ALTER TABLE visits ADD COLUMN mail_content_type VARCHAR(80) NULL AFTER send_thankyou_mail',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'visits' AND COLUMN_NAME = 'mail_body') = 0,
  'ALTER TABLE visits ADD COLUMN mail_body TEXT NULL AFTER mail_content_type',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'visits' AND COLUMN_NAME = 'web_entry') = 0,
  'ALTER TABLE visits ADD COLUMN web_entry TINYINT(1) NOT NULL DEFAULT 0 AFTER mail_body',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'visits' AND COLUMN_NAME = 'competing_data_payload') = 0,
  'ALTER TABLE visits ADD COLUMN competing_data_payload LONGTEXT NULL AFTER web_entry',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS visit_eproduct_promotions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visit_id BIGINT UNSIGNED NOT NULL,
  brand_id BIGINT UNSIGNED NOT NULL,
  e_product_id BIGINT UNSIGNED NOT NULL,
  sales_stage_id BIGINT UNSIGNED NOT NULL,
  prospect_id BIGINT UNSIGNED NOT NULL,
  remarks VARCHAR(1500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_vep_visit FOREIGN KEY (visit_id) REFERENCES visits(id) ON DELETE CASCADE,
  CONSTRAINT fk_vep_brand FOREIGN KEY (brand_id) REFERENCES brands(id),
  CONSTRAINT fk_vep_product FOREIGN KEY (e_product_id) REFERENCES e_products(id),
  CONSTRAINT fk_vep_stage FOREIGN KEY (sales_stage_id) REFERENCES sales_stages(id),
  CONSTRAINT fk_vep_prospect FOREIGN KEY (prospect_id) REFERENCES prospects(id),
  INDEX idx_vep_customer_history (e_product_id, visit_id),
  INDEX idx_vep_visit (visit_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS visit_eproduct_promotion_classes (
  promotion_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (promotion_id, class_id),
  CONSTRAINT fk_vepc_promotion FOREIGN KEY (promotion_id) REFERENCES visit_eproduct_promotions(id) ON DELETE CASCADE,
  CONSTRAINT fk_vepc_class FOREIGN KEY (class_id) REFERENCES classes(id)
) ENGINE=InnoDB;

-- Academic-session FK is added only if it is not already present.
SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
   WHERE CONSTRAINT_SCHEMA = @db_name AND TABLE_NAME = 'visits'
     AND CONSTRAINT_NAME = 'fk_visit_academic_session') = 0,
  'ALTER TABLE visits ADD CONSTRAINT fk_visit_academic_session FOREIGN KEY (academic_session_id) REFERENCES academic_sessions(id) ON DELETE SET NULL',
  'SELECT 1'
);

-- Seed sessions before executing the FK statement so existing demo values 1/2 are valid.
INSERT INTO academic_sessions (id, session_name, start_date, end_date, is_active) VALUES
(1,'2025-2026','2025-04-01','2026-03-31',1),
(2,'2026-2027','2026-04-01','2027-03-31',1)
ON DUPLICATE KEY UPDATE
  session_name = VALUES(session_name), start_date = VALUES(start_date),
  end_date = VALUES(end_date), is_active = VALUES(is_active);

PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 4. E-Product master data supplied for this CRM.
-- ---------------------------------------------------------------------------
INSERT INTO sales_stages (id, stage_name, sequence_num, is_active) VALUES
(1,'S0 - Attempted Meeting',1,1),
(2,'S1 - Met & Intro to Platform/Product',1,1),
(3,'S2 - Product Demonstration',1,1),
(4,'S3 - Product Trial',1,1),
(5,'S4 - Finalising Negotiation & MOU Signing',1,1),
(6,'S5 - Finalised Terms & Closure',1,1)
ON DUPLICATE KEY UPDATE stage_name=VALUES(stage_name), sequence_num=VALUES(sequence_num), is_active=1;

INSERT INTO brands (id, brand_name, is_active) VALUES
(1,'Cretile',1),(2,'GSL x CUPA',1),(3,'GSL x HBPE',1),
(4,'IIT Guwahati',1),(5,'Tinkrworks',1),(6,'VEX',1)
ON DUPLICATE KEY UPDATE brand_name=VALUES(brand_name), is_active=1;

INSERT INTO prospects (id, prospect_name, is_active) VALUES
(1,'Warm Prospect - interested in product',1),
(2,'Cold Prospect - Next Year',1),
(3,'Cold Prospect - Using some other Product or Supplier',1),
(4,'Cold Prospect - Free Structure does not allow',1),
(5,'Cold Prospect - Budget, decision-making authority or timing Issues',1)
ON DUPLICATE KEY UPDATE prospect_name=VALUES(prospect_name), is_active=1;

INSERT INTO e_products (id, brand_id, subject_id, product_name, product_code, list_price, is_active) VALUES
(2,4,4,'Testing eprodcut 1','EP-02',859.00,1),
(3,2,4,'testing product 2','Product/02',499.00,1),
(4,2,4,'testing product 234','testing/01',599.00,1),
(5,2,4,'Testing eprodcut 1','SDSADSAq',859.00,1),
(6,2,4,'Vyakarana E-Book','EB01',399.00,1)
ON DUPLICATE KEY UPDATE
  brand_id=VALUES(brand_id), subject_id=VALUES(subject_id),
  product_name=VALUES(product_name), product_code=VALUES(product_code),
  list_price=VALUES(list_price), is_active=1;

INSERT IGNORE INTO e_product_classes (e_product_id, class_id) VALUES
(2,3),(2,4),(2,5),
(3,4),(3,5),(3,6),
(4,4),(4,5),(4,6),(4,7),
(5,2),(5,3),(5,4),(5,5),
(6,4),(6,5),(6,6),(6,7),(6,8);

-- ---------------------------------------------------------------------------
-- 5. DSR feature flags and Flutter HomeScreen menu names.
-- ---------------------------------------------------------------------------
INSERT INTO application_setup (key_name, key_value, description, is_active) VALUES
('VisitBooksSampling','Y','Show book sampling controls during Visit/DSR entry.',1),
('VisitEProducts','Y','Show E-Product promotion controls during Visit/DSR entry.',1)
ON DUPLICATE KEY UPDATE key_value=VALUES(key_value), description=VALUES(description), is_active=1;

DELETE FROM profile_menus;
DELETE FROM menus;

INSERT INTO menus (id, menu_name, child_menu_name, route_path, sort_order) VALUES
(1,'Customer','School List','/customers/school',10),
(2,'Customer','Trade List','/customers/trade',11),
(3,'Customer','Library List','/customers/library',12),
(4,'Visit/DSR','View Today''s Plan','/plans/today',20),
(5,'Visit/DSR','View Tomorrow''s Plan','/plans/tomorrow',21),
(6,'Visit/DSR','Visit Entry','/visits/new',22),
(7,'Sampling','School Sampling','/sampling/school',30),
(8,'Sampling','Trade Sampling','/sampling/trade',31),
(9,'Sampling','Library Sampling','/sampling/library',32),
(10,'Sampling','Sampling Approval','/sampling/approvals',33),
(11,'Sampling','Self-Stock Request','/self-stock',34),
(12,'Sampling','Self-Stock Approval','/self-stock/approvals',35);

INSERT INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id FROM profiles p CROSS JOIN menus m;

SELECT 'CRM backend upgrade completed' AS result;
