CREATE DATABASE IF NOT EXISTS crm_dummy_v2
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE crm_dummy_v2;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS approval_item_history;
DROP TABLE IF EXISTS approval_history;
DROP TABLE IF EXISTS approval_requests;
DROP TABLE IF EXISTS customer_change_requests;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS self_stock_request_items;
DROP TABLE IF EXISTS self_stock_requests;
DROP TABLE IF EXISTS customer_sampling_request_items;
DROP TABLE IF EXISTS customer_sampling_requests;
DROP TABLE IF EXISTS sampling_budgets;
DROP TABLE IF EXISTS followups;
DROP TABLE IF EXISTS visit_eproduct_promotion_classes;
DROP TABLE IF EXISTS visit_eproduct_promotions;
DROP TABLE IF EXISTS visit_documents;
DROP TABLE IF EXISTS visit_joint_executives;
DROP TABLE IF EXISTS visits;
DROP TABLE IF EXISTS backdate_requests;
DROP TABLE IF EXISTS executive_locations;
DROP TABLE IF EXISTS checkin_checkout;
DROP TABLE IF EXISTS visit_plans;
DROP TABLE IF EXISTS visit_purposes;
DROP TABLE IF EXISTS sampling_types;
DROP TABLE IF EXISTS shipment_modes;
DROP TABLE IF EXISTS e_product_classes;
DROP TABLE IF EXISTS e_products;
DROP TABLE IF EXISTS prospects;
DROP TABLE IF EXISTS sales_stages;
DROP TABLE IF EXISTS brands;
DROP TABLE IF EXISTS academic_sessions;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS series;
DROP TABLE IF EXISTS class_levels;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS customer_school_details;
DROP TABLE IF EXISTS customer_contacts;
DROP TABLE IF EXISTS customer_executives;
DROP TABLE IF EXISTS customer_category_map;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS affiliate_types;
DROP TABLE IF EXISTS institute_levels;
DROP TABLE IF EXISTS institute_types;
DROP TABLE IF EXISTS purchase_modes;
DROP TABLE IF EXISTS customer_categories;
DROP TABLE IF EXISTS adoption_roles;
DROP TABLE IF EXISTS contact_designations;
DROP TABLE IF EXISTS salutations;
DROP TABLE IF EXISTS data_sources;
DROP TABLE IF EXISTS chain_schools;
DROP TABLE IF EXISTS boards;
DROP TABLE IF EXISTS profile_menus;
DROP TABLE IF EXISTS menus;
DROP TABLE IF EXISTS application_setup;
DROP TABLE IF EXISTS executive_cities;
DROP TABLE IF EXISTS executive_territories;
DROP TABLE IF EXISTS executive_product_divisions;
DROP TABLE IF EXISTS cities;
DROP TABLE IF EXISTS districts;
DROP TABLE IF EXISTS states;
DROP TABLE IF EXISTS countries;
DROP TABLE IF EXISTS territories;
DROP TABLE IF EXISTS product_divisions;
DROP TABLE IF EXISTS executives;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS password_reset_tokens;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS profiles;
DROP TABLE IF EXISTS api_tokens;
DROP TABLE IF EXISTS api_clients;
DROP TABLE IF EXISTS request_sequences;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE api_clients (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  client_name VARCHAR(100) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  client_secret_hash CHAR(64) NOT NULL,
  status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE api_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  client_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME NULL,
  revoked_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_api_token_client FOREIGN KEY (client_id) REFERENCES api_clients(id) ON DELETE CASCADE,
  INDEX idx_api_tokens_active (token_hash, revoked_at, expires_at)
) ENGINE=InnoDB;

CREATE TABLE profiles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  level_rank INT NOT NULL,
  is_admin TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  status ENUM('ACTIVE','BLOCKED','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  last_login_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE refresh_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  created_ip VARCHAR(64) NULL,
  user_agent VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_refresh_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_refresh_active (user_id, revoked_at, expires_at)
) ENGINE=InnoDB;

CREATE TABLE password_reset_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reset_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE departments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE executives (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL UNIQUE,
  executive_code VARCHAR(40) NOT NULL UNIQUE,
  executive_name VARCHAR(150) NOT NULL,
  email VARCHAR(190) NULL,
  mobile VARCHAR(30) NULL,
  designation VARCHAR(150) NULL,
  department_id BIGINT UNSIGNED NULL,
  profile_id BIGINT UNSIGNED NOT NULL,
  manager_executive_id BIGINT UNSIGNED NULL,
  approval_enabled TINYINT(1) NOT NULL DEFAULT 0,
  menu_access_mode ENUM('PROFILE','CUSTOM') NOT NULL DEFAULT 'PROFILE',
  status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_exec_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_exec_profile FOREIGN KEY (profile_id) REFERENCES profiles(id),
  CONSTRAINT fk_exec_department FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
  CONSTRAINT fk_exec_manager FOREIGN KEY (manager_executive_id) REFERENCES executives(id) ON DELETE SET NULL,
  INDEX idx_exec_manager (manager_executive_id),
  INDEX idx_exec_profile (profile_id)
) ENGINE=InnoDB;

CREATE TABLE product_divisions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(30) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE executive_product_divisions (
  executive_id BIGINT UNSIGNED NOT NULL,
  product_division_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (executive_id, product_division_id),
  CONSTRAINT fk_epd_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE,
  CONSTRAINT fk_epd_div FOREIGN KEY (product_division_id) REFERENCES product_divisions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE territories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE countries (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE states (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  country_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  CONSTRAINT fk_state_country FOREIGN KEY (country_id) REFERENCES countries(id),
  UNIQUE KEY uk_state (country_id, name)
) ENGINE=InnoDB;

CREATE TABLE districts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  state_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  CONSTRAINT fk_district_state FOREIGN KEY (state_id) REFERENCES states(id),
  UNIQUE KEY uk_district (state_id, name)
) ENGINE=InnoDB;

CREATE TABLE cities (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  district_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  CONSTRAINT fk_city_district FOREIGN KEY (district_id) REFERENCES districts(id),
  INDEX idx_city_name (name)
) ENGINE=InnoDB;

CREATE TABLE executive_territories (
  executive_id BIGINT UNSIGNED NOT NULL,
  territory_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (executive_id, territory_id),
  CONSTRAINT fk_et_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE,
  CONSTRAINT fk_et_territory FOREIGN KEY (territory_id) REFERENCES territories(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE executive_cities (
  executive_id BIGINT UNSIGNED NOT NULL,
  city_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (executive_id, city_id),
  CONSTRAINT fk_ec_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE,
  CONSTRAINT fk_ec_city FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE application_setup (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  key_name VARCHAR(120) NOT NULL UNIQUE,
  key_value VARCHAR(500) NULL,
  description VARCHAR(1000) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE menus (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  menu_name VARCHAR(100) NOT NULL,
  child_menu_name VARCHAR(120) NOT NULL,
  route_path VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  requires_approval_role TINYINT(1) NOT NULL DEFAULT 0,
  admin_only TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE profile_menus (
  profile_id BIGINT UNSIGNED NOT NULL,
  menu_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (profile_id, menu_id),
  CONSTRAINT fk_pm_profile FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
  CONSTRAINT fk_pm_menu FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE

) ENGINE=InnoDB;

CREATE TABLE executive_menu_overrides (
  executive_id BIGINT UNSIGNED NOT NULL,
  menu_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (executive_id, menu_id),
  CONSTRAINT fk_emo_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE,
  CONSTRAINT fk_emo_menu FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE boards (

  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE chain_schools (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE data_sources (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE salutations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE contact_designations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE adoption_roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE customer_categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE purchase_modes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE institute_types (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE institute_levels (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE affiliate_types (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE classes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  class_num_id INT NULL UNIQUE,
  name VARCHAR(40) NOT NULL UNIQUE,
  sort_order INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE academic_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  session_name VARCHAR(40) NOT NULL UNIQUE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT chk_academic_session_dates CHECK (end_date >= start_date)
) ENGINE=InnoDB;

CREATE TABLE brands (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  brand_name VARCHAR(150) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE sales_stages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  stage_name VARCHAR(250) NOT NULL UNIQUE,
  sequence_num INT NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE prospects (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  prospect_name VARCHAR(500) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE customers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_code VARCHAR(50) NULL UNIQUE,
  customer_type ENUM('SCHOOL','INSTITUTE','TRADE','LIBRARY') NOT NULL,
  customer_name VARCHAR(200) NOT NULL,
  ref_code VARCHAR(100) NULL,
  email VARCHAR(190) NULL,
  mobile VARCHAR(30) NULL,
  address VARCHAR(500) NOT NULL,
  city_id BIGINT UNSIGNED NOT NULL,
  pincode VARCHAR(20) NOT NULL,
  key_customer TINYINT(1) NOT NULL DEFAULT 0,
  customer_status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  validation_status ENUM('PENDING_APPROVAL','VALIDATED','REJECTED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  delete_request_status ENUM('NONE','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'NONE',
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  gst_number VARCHAR(40) NULL,
  pan_number VARCHAR(40) NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  created_by_executive_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_customer_city FOREIGN KEY (city_id) REFERENCES cities(id),
  CONSTRAINT fk_customer_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  CONSTRAINT fk_customer_exec FOREIGN KEY (created_by_executive_id) REFERENCES executives(id),
  INDEX idx_customer_name (customer_name),
  INDEX idx_customer_type_status (customer_type, validation_status, customer_status)
) ENGINE=InnoDB;

CREATE TABLE customer_category_map (
  customer_id BIGINT UNSIGNED NOT NULL,
  category_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (customer_id, category_id),
  CONSTRAINT fk_ccm_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  CONSTRAINT fk_ccm_category FOREIGN KEY (category_id) REFERENCES customer_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE customer_executives (
  customer_id BIGINT UNSIGNED NOT NULL,
  executive_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (customer_id, executive_id),
  CONSTRAINT fk_ce_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  CONSTRAINT fk_ce_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE customer_contacts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT UNSIGNED NOT NULL,
  customer_type ENUM('SCHOOL','INSTITUTE','TRADE','LIBRARY') NOT NULL,
  primary_contact TINYINT(1) NOT NULL DEFAULT 0,
  salutation_id BIGINT UNSIGNED NULL,
  designation_id BIGINT UNSIGNED NULL,
  first_name VARCHAR(100) NULL,
  last_name VARCHAR(100) NULL,
  email VARCHAR(190) NULL,
  mobile VARCHAR(30) NULL,
  contact_status ENUM('ACTIVE','INACTIVE','DELETED') NOT NULL DEFAULT 'ACTIVE',
  validation_status ENUM('PENDING_APPROVAL','VALIDATED','REJECTED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  residential_address VARCHAR(500) NULL,
  residential_city_id BIGINT UNSIGNED NULL,
  residential_pincode VARCHAR(20) NULL,
  birthday DATE NULL,
  anniversary DATE NULL,
  data_source_id BIGINT UNSIGNED NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_contact_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  CONSTRAINT fk_contact_salutation FOREIGN KEY (salutation_id) REFERENCES salutations(id) ON DELETE SET NULL,
  CONSTRAINT fk_contact_designation FOREIGN KEY (designation_id) REFERENCES contact_designations(id) ON DELETE SET NULL,
  CONSTRAINT fk_contact_city FOREIGN KEY (residential_city_id) REFERENCES cities(id) ON DELETE SET NULL,
  CONSTRAINT fk_contact_source FOREIGN KEY (data_source_id) REFERENCES data_sources(id) ON DELETE SET NULL,
  CONSTRAINT fk_contact_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  INDEX idx_contact_customer (customer_id, contact_status)
) ENGINE=InnoDB;

CREATE TABLE customer_school_details (
  customer_id BIGINT UNSIGNED PRIMARY KEY,
  board_id BIGINT UNSIGNED NULL,
  chain_school_id BIGINT UNSIGNED NULL,
  start_class_id BIGINT UNSIGNED NULL,
  end_class_id BIGINT UNSIGNED NULL,
  medium_instruction VARCHAR(80) NULL,
  ranking VARCHAR(20) NULL,
  sampling_month TINYINT UNSIGNED NULL,
  decision_month TINYINT UNSIGNED NULL,
  purchase_mode_id BIGINT UNSIGNED NULL,
  CONSTRAINT fk_school_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  CONSTRAINT fk_school_board FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE SET NULL,
  CONSTRAINT fk_school_chain FOREIGN KEY (chain_school_id) REFERENCES chain_schools(id) ON DELETE SET NULL,
  CONSTRAINT fk_school_purchase FOREIGN KEY (purchase_mode_id) REFERENCES purchase_modes(id) ON DELETE SET NULL,
  CONSTRAINT fk_school_start_class FOREIGN KEY (start_class_id) REFERENCES classes(id) ON DELETE SET NULL,
  CONSTRAINT fk_school_end_class FOREIGN KEY (end_class_id) REFERENCES classes(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE subjects (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE class_levels (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  sort_order INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE series (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE books (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  series_id BIGINT UNSIGNED NULL,
  subject_id BIGINT UNSIGNED NULL,
  class_level_id BIGINT UNSIGNED NULL,
  title VARCHAR(250) NOT NULL,
  isbn VARCHAR(40) NULL UNIQUE,
  author VARCHAR(160) NULL,
  list_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  book_num VARCHAR(30) NULL,
  book_type VARCHAR(40) NULL,
  physical_stock INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_book_series FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE SET NULL,
  CONSTRAINT fk_book_subject FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
  CONSTRAINT fk_book_class_level FOREIGN KEY (class_level_id) REFERENCES class_levels(id) ON DELETE SET NULL,
  INDEX idx_book_title (title),
  INDEX idx_book_series (series_id)
) ENGINE=InnoDB;

CREATE TABLE e_products (
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

CREATE TABLE e_product_classes (
  e_product_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (e_product_id, class_id),
  CONSTRAINT fk_epc_product FOREIGN KEY (e_product_id) REFERENCES e_products(id) ON DELETE CASCADE,
  CONSTRAINT fk_epc_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE shipment_modes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE sampling_types (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE visit_purposes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE visit_plans (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  executive_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  visit_purpose_id BIGINT UNSIGNED NULL,
  plan_date DATE NOT NULL,
  plan_type ENUM('VISIT','TRAVEL') NOT NULL DEFAULT 'VISIT',
  remarks VARCHAR(500) NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_plan_exec FOREIGN KEY (executive_id) REFERENCES executives(id),
  CONSTRAINT fk_plan_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_plan_purpose FOREIGN KEY (visit_purpose_id) REFERENCES visit_purposes(id) ON DELETE SET NULL,
  CONSTRAINT fk_plan_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  INDEX idx_plan_exec_date (executive_id, plan_date)
) ENGINE=InnoDB;

CREATE TABLE checkin_checkout (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  executive_id BIGINT UNSIGNED NOT NULL,
  work_date DATE NOT NULL,
  check_in_at DATETIME NULL,
  check_in_latitude DECIMAL(10,7) NULL,
  check_in_longitude DECIMAL(10,7) NULL,
  check_in_address VARCHAR(500) NULL,
  check_out_at DATETIME NULL,
  check_out_latitude DECIMAL(10,7) NULL,
  check_out_longitude DECIMAL(10,7) NULL,
  check_out_address VARCHAR(500) NULL,
  entered_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_attendance_exec FOREIGN KEY (executive_id) REFERENCES executives(id),
  CONSTRAINT fk_attendance_user FOREIGN KEY (entered_by_user_id) REFERENCES users(id),
  UNIQUE KEY uk_attendance_day (executive_id, work_date)
) ENGINE=InnoDB;

CREATE TABLE executive_locations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  executive_id BIGINT UNSIGNED NOT NULL,
  recorded_at DATETIME NOT NULL,
  latitude DECIMAL(10,7) NOT NULL,
  longitude DECIMAL(10,7) NOT NULL,
  address VARCHAR(500) NULL,
  entered_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_location_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE,
  CONSTRAINT fk_location_user FOREIGN KEY (entered_by_user_id) REFERENCES users(id),
  INDEX idx_location_exec_time (executive_id, recorded_at)
) ENGINE=InnoDB;

CREATE TABLE backdate_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  executive_id BIGINT UNSIGNED NOT NULL,
  requested_visit_date DATE NOT NULL,
  reason VARCHAR(1000) NOT NULL,
  status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_backdate_exec FOREIGN KEY (executive_id) REFERENCES executives(id),
  CONSTRAINT fk_backdate_user FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE visits (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  executive_id BIGINT UNSIGNED NOT NULL,
  logged_in_executive_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  customer_type ENUM('SCHOOL','INSTITUTE','TRADE','LIBRARY') NOT NULL,
  customer_contact_id BIGINT UNSIGNED NULL,
  academic_session_id BIGINT UNSIGNED NULL,
  visit_purpose_id BIGINT UNSIGNED NOT NULL,
  other_visit_purpose VARCHAR(500) NULL,
  visit_feedback TEXT NOT NULL,
  visit_date DATE NOT NULL,
  address VARCHAR(500) NOT NULL,
  latitude DECIMAL(10,7) NOT NULL,
  longitude DECIMAL(10,7) NOT NULL,
  request_remarks VARCHAR(1000) NULL,
  send_thankyou_mail TINYINT(1) NOT NULL DEFAULT 0,
  mail_content_type VARCHAR(80) NULL,
  mail_body TEXT NULL,
  web_entry TINYINT(1) NOT NULL DEFAULT 0,
  competing_data_payload LONGTEXT NULL,
  backdate_request_id BIGINT UNSIGNED NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_visit_exec FOREIGN KEY (executive_id) REFERENCES executives(id),
  CONSTRAINT fk_visit_logged_exec FOREIGN KEY (logged_in_executive_id) REFERENCES executives(id),
  CONSTRAINT fk_visit_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_visit_contact FOREIGN KEY (customer_contact_id) REFERENCES customer_contacts(id),
  CONSTRAINT fk_visit_academic_session FOREIGN KEY (academic_session_id) REFERENCES academic_sessions(id) ON DELETE SET NULL,
  CONSTRAINT fk_visit_purpose FOREIGN KEY (visit_purpose_id) REFERENCES visit_purposes(id),
  CONSTRAINT fk_visit_backdate FOREIGN KEY (backdate_request_id) REFERENCES backdate_requests(id) ON DELETE SET NULL,
  CONSTRAINT fk_visit_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  INDEX idx_visit_customer_date (customer_id, visit_date),
  INDEX idx_visit_exec_date (executive_id, visit_date)
) ENGINE=InnoDB;

CREATE TABLE visit_joint_executives (
  visit_id BIGINT UNSIGNED NOT NULL,
  executive_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (visit_id, executive_id),
  CONSTRAINT fk_vje_visit FOREIGN KEY (visit_id) REFERENCES visits(id) ON DELETE CASCADE,
  CONSTRAINT fk_vje_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE visit_documents (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visit_id BIGINT UNSIGNED NOT NULL,
  document_name VARCHAR(200) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_size BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_vdoc_visit FOREIGN KEY (visit_id) REFERENCES visits(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE visit_eproduct_promotions (
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

CREATE TABLE visit_eproduct_promotion_classes (
  promotion_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (promotion_id, class_id),
  CONSTRAINT fk_vepc_promotion FOREIGN KEY (promotion_id) REFERENCES visit_eproduct_promotions(id) ON DELETE CASCADE,
  CONSTRAINT fk_vepc_class FOREIGN KEY (class_id) REFERENCES classes(id)
) ENGINE=InnoDB;

CREATE TABLE followups (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visit_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  department_id BIGINT UNSIGNED NOT NULL,
  assigned_executive_id BIGINT UNSIGNED NOT NULL,
  action_text VARCHAR(1000) NOT NULL,
  followup_date DATE NOT NULL,
  status ENUM('OPEN','DONE','CANCELLED') NOT NULL DEFAULT 'OPEN',
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  CONSTRAINT fk_follow_visit FOREIGN KEY (visit_id) REFERENCES visits(id) ON DELETE SET NULL,
  CONSTRAINT fk_follow_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_follow_department FOREIGN KEY (department_id) REFERENCES departments(id),
  CONSTRAINT fk_follow_exec FOREIGN KEY (assigned_executive_id) REFERENCES executives(id),
  CONSTRAINT fk_follow_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  INDEX idx_follow_exec_date (assigned_executive_id, followup_date, status)
) ENGINE=InnoDB;

CREATE TABLE sampling_budgets (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  executive_id BIGINT UNSIGNED NOT NULL,
  budget_year INT NOT NULL,
  book_id BIGINT UNSIGNED NULL,
  total_units DECIMAL(12,2) NOT NULL DEFAULT 0,
  used_units DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_value DECIMAL(14,2) NOT NULL DEFAULT 0,
  used_value DECIMAL(14,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_budget_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE,
  CONSTRAINT fk_budget_book FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
  UNIQUE KEY uk_budget (executive_id, budget_year, book_id)
) ENGINE=InnoDB;

CREATE TABLE customer_sampling_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  request_number VARCHAR(50) NOT NULL UNIQUE,
  customer_id BIGINT UNSIGNED NOT NULL,
  customer_type ENUM('SCHOOL','INSTITUTE','TRADE','LIBRARY') NOT NULL,
  executive_id BIGINT UNSIGNED NOT NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  origin_visit_id BIGINT UNSIGNED NULL,
  shipment_mode_id BIGINT UNSIGNED NOT NULL,
  shipping_instructions VARCHAR(1000) NULL,
  request_remarks VARCHAR(1000) NULL,
  total_qty DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  in_budget TINYINT(1) NOT NULL DEFAULT 1,
  available_budget DECIMAL(14,2) NULL,
  requested_budget DECIMAL(14,2) NULL,
  request_status VARCHAR(50) NOT NULL DEFAULT 'PENDING_APPROVAL',
  approval_status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  shipment_status ENUM('NOT_READY','READY','PARTIALLY_SHIPPED','SHIPPED') NOT NULL DEFAULT 'NOT_READY',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_csr_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_csr_exec FOREIGN KEY (executive_id) REFERENCES executives(id),
  CONSTRAINT fk_csr_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  CONSTRAINT fk_csr_visit FOREIGN KEY (origin_visit_id) REFERENCES visits(id) ON DELETE SET NULL,
  CONSTRAINT fk_csr_shipmode FOREIGN KEY (shipment_mode_id) REFERENCES shipment_modes(id),
  INDEX idx_csr_exec_status (executive_id, request_status),
  INDEX idx_csr_customer (customer_id)
) ENGINE=InnoDB;

CREATE TABLE customer_sampling_request_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  request_id BIGINT UNSIGNED NOT NULL,
  series_id BIGINT UNSIGNED NULL,
  book_id BIGINT UNSIGNED NOT NULL,
  requested_qty DECIMAL(12,2) NOT NULL,
  previous_approved_qty DECIMAL(12,2) NOT NULL DEFAULT 0,
  approved_qty DECIMAL(12,2) NULL,
  shipped_qty DECIMAL(12,2) NOT NULL DEFAULT 0,
  sampling_type_id BIGINT UNSIGNED NOT NULL,
  sample_to_contact_id BIGINT UNSIGNED NULL,
  sample_given ENUM('SAMPLE_GIVEN','TO_BE_DISPATCHED') NOT NULL,
  ship_to VARCHAR(100) NULL,
  shipping_address VARCHAR(1000) NULL,
  unit_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_csri_request FOREIGN KEY (request_id) REFERENCES customer_sampling_requests(id) ON DELETE CASCADE,
  CONSTRAINT fk_csri_series FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE SET NULL,
  CONSTRAINT fk_csri_book FOREIGN KEY (book_id) REFERENCES books(id),
  CONSTRAINT fk_csri_type FOREIGN KEY (sampling_type_id) REFERENCES sampling_types(id),
  CONSTRAINT fk_csri_contact FOREIGN KEY (sample_to_contact_id) REFERENCES customer_contacts(id) ON DELETE SET NULL,
  INDEX idx_csri_request (request_id)
) ENGINE=InnoDB;

CREATE TABLE self_stock_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  request_number VARCHAR(50) NOT NULL UNIQUE,
  executive_id BIGINT UNSIGNED NOT NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  trade_customer_id BIGINT UNSIGNED NULL,
  ship_to ENUM('RESIDENCE_ADDRESS','BY_HAND','TRADE','TRANSPORT_OFFICE') NOT NULL,
  shipping_address VARCHAR(1000) NULL,
  shipment_mode_id BIGINT UNSIGNED NOT NULL,
  shipping_instructions VARCHAR(1000) NULL,
  request_remarks VARCHAR(1000) NULL,
  in_budget TINYINT(1) NOT NULL DEFAULT 1,
  available_budget DECIMAL(14,2) NULL,
  requested_budget DECIMAL(14,2) NULL,
  request_status VARCHAR(50) NOT NULL DEFAULT 'PENDING_APPROVAL',
  approval_status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  shipment_status ENUM('NOT_READY','READY','PARTIALLY_SHIPPED','SHIPPED') NOT NULL DEFAULT 'NOT_READY',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ssr_exec FOREIGN KEY (executive_id) REFERENCES executives(id),
  CONSTRAINT fk_ssr_user FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  CONSTRAINT fk_ssr_trade FOREIGN KEY (trade_customer_id) REFERENCES customers(id) ON DELETE SET NULL,
  CONSTRAINT fk_ssr_shipmode FOREIGN KEY (shipment_mode_id) REFERENCES shipment_modes(id),
  INDEX idx_ssr_exec_status (executive_id, request_status)
) ENGINE=InnoDB;

CREATE TABLE self_stock_request_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  request_id BIGINT UNSIGNED NOT NULL,
  subject_id BIGINT UNSIGNED NULL,
  series_id BIGINT UNSIGNED NULL,
  book_id BIGINT UNSIGNED NOT NULL,
  requested_qty DECIMAL(12,2) NOT NULL,
  previous_approved_qty DECIMAL(12,2) NOT NULL DEFAULT 0,
  approved_qty DECIMAL(12,2) NULL,
  shipped_qty DECIMAL(12,2) NOT NULL DEFAULT 0,
  unit_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_ssri_request FOREIGN KEY (request_id) REFERENCES self_stock_requests(id) ON DELETE CASCADE,
  CONSTRAINT fk_ssri_subject FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
  CONSTRAINT fk_ssri_series FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE SET NULL,
  CONSTRAINT fk_ssri_book FOREIGN KEY (book_id) REFERENCES books(id),
  INDEX idx_ssri_request (request_id)
) ENGINE=InnoDB;

CREATE TABLE customer_change_requests (
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

CREATE TABLE approval_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  module_name VARCHAR(60) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  request_number VARCHAR(80) NOT NULL,
  requested_by_executive_id BIGINT UNSIGNED NOT NULL,
  current_approver_executive_id BIGINT UNSIGNED NULL,
  current_level INT NOT NULL DEFAULT 1,
  status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  completed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_approval_requester FOREIGN KEY (requested_by_executive_id) REFERENCES executives(id),
  CONSTRAINT fk_approval_approver FOREIGN KEY (current_approver_executive_id) REFERENCES executives(id) ON DELETE SET NULL,
  UNIQUE KEY uk_approval_entity (module_name, entity_id),
  INDEX idx_approval_inbox (current_approver_executive_id, status, module_name)
) ENGINE=InnoDB;

CREATE TABLE approval_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  approval_request_id BIGINT UNSIGNED NOT NULL,
  module_name VARCHAR(60) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  approval_level INT NOT NULL,
  action ENUM('SUBMITTED','APPROVED_LEVEL','APPROVED_FINAL','REJECTED') NOT NULL,
  action_by_executive_id BIGINT UNSIGNED NOT NULL,
  remarks VARCHAR(1000) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ah_request FOREIGN KEY (approval_request_id) REFERENCES approval_requests(id) ON DELETE CASCADE,
  CONSTRAINT fk_ah_exec FOREIGN KEY (action_by_executive_id) REFERENCES executives(id),
  INDEX idx_ah_request (approval_request_id, created_at)

) ENGINE=InnoDB;

CREATE TABLE admin_request_history (
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

CREATE TABLE approval_item_history (

  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  approval_request_id BIGINT UNSIGNED NOT NULL,
  module_name VARCHAR(60) NOT NULL,
  entity_item_id BIGINT UNSIGNED NOT NULL,
  book_id BIGINT UNSIGNED NOT NULL,
  approval_level INT NOT NULL,
  requested_qty DECIMAL(12,2) NOT NULL,
  previous_approved_qty DECIMAL(12,2) NOT NULL DEFAULT 0,
  approved_qty DECIMAL(12,2) NOT NULL,
  approved_by_executive_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_aih_request FOREIGN KEY (approval_request_id) REFERENCES approval_requests(id) ON DELETE CASCADE,
  CONSTRAINT fk_aih_book FOREIGN KEY (book_id) REFERENCES books(id),
  CONSTRAINT fk_aih_exec FOREIGN KEY (approved_by_executive_id) REFERENCES executives(id),
  INDEX idx_aih_request (approval_request_id, approval_level)
) ENGINE=InnoDB;

CREATE TABLE notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  executive_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(180) NOT NULL,
  message VARCHAR(1000) NOT NULL,
  module_name VARCHAR(60) NULL,
  entity_id BIGINT UNSIGNED NULL,
  read_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notification_exec FOREIGN KEY (executive_id) REFERENCES executives(id) ON DELETE CASCADE,
  INDEX idx_notification_inbox (executive_id, read_at, created_at)
) ENGINE=InnoDB;

CREATE TABLE request_sequences (
  module_prefix VARCHAR(20) NOT NULL,
  period CHAR(4) NOT NULL,
  last_number INT NOT NULL DEFAULT 0,
  PRIMARY KEY (module_prefix, period)
) ENGINE=InnoDB;
