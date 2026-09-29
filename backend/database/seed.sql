USE crm_dummy_v2;

INSERT INTO api_clients (id, client_name, email, client_secret_hash, status) VALUES
(1, 'CRM Mobile/Web Client', 'crm-service@example.com', 'c374e8bb8986d98aae15d56844e47da360520a8720a08bd52d0803e24ba7f376', 'ACTIVE');

INSERT INTO profiles (id, code, name, level_rank, is_admin) VALUES
(1, 'L1', 'Field Executive', 1, 0),
(2, 'L2', 'Sales Manager', 2, 0),
(3, 'L3', 'Regional Manager', 3, 0),
(4, 'L4', 'Zonal Manager', 4, 0),
(5, 'L5', 'National Sales Manager', 5, 0),
(6, 'HDA', 'Head / Admin', 6, 1);

INSERT INTO departments (id, name) VALUES
(1, 'Sales Team'),
(2, 'Regional Office Level Support'),
(3, 'Head Office Level Support'),
(4, 'Finance'),
(5, 'Marketing');

-- Demo password for every seeded CRM user: Password@123
-- A sha256$ bootstrap hash is used so seed.sql is portable; changing the password through the API stores bcrypt.
INSERT INTO users (id, email, password_hash, status) VALUES
(1, 'field@crm.local', 'sha256$ff7bd97b1a7789ddd2775122fd6817f3173672da9f802ceec57f284325bf589f', 'ACTIVE'),
(2, 'manager@crm.local', 'sha256$ff7bd97b1a7789ddd2775122fd6817f3173672da9f802ceec57f284325bf589f', 'ACTIVE'),
(3, 'regional@crm.local', 'sha256$ff7bd97b1a7789ddd2775122fd6817f3173672da9f802ceec57f284325bf589f', 'ACTIVE'),
(4, 'zonal@crm.local', 'sha256$ff7bd97b1a7789ddd2775122fd6817f3173672da9f802ceec57f284325bf589f', 'ACTIVE'),
(5, 'national@crm.local', 'sha256$ff7bd97b1a7789ddd2775122fd6817f3173672da9f802ceec57f284325bf589f', 'ACTIVE'),
(6, 'admin@crm.local', 'sha256$ff7bd97b1a7789ddd2775122fd6817f3173672da9f802ceec57f284325bf589f', 'ACTIVE');

-- Insert top-to-bottom so manager foreign keys already exist.
INSERT INTO executives (id, user_id, executive_code, executive_name, email, mobile, designation, department_id, profile_id, manager_executive_id, approval_enabled) VALUES
(1006, 6, 'EXE-HDA', 'CRM Admin', 'admin@crm.local', '9000000006', 'Head Administrator', 3, 6, NULL, 1),
(1005, 5, 'EXE-L5', 'National Manager', 'national@crm.local', '9000000005', 'National Sales Manager', 3, 5, 1006, 1),
(1004, 4, 'EXE-L4', 'Zonal Manager', 'zonal@crm.local', '9000000004', 'Zonal Sales Manager', 2, 4, 1005, 1),
(1003, 3, 'EXE-L3', 'Regional Manager', 'regional@crm.local', '9000000003', 'Regional Sales Manager', 2, 3, 1004, 1),
(1002, 2, 'EXE-L2', 'Sales Manager', 'manager@crm.local', '9000000002', 'Area Sales Manager', 1, 2, 1003, 1),
(1001, 1, 'EXE-L1', 'Field Executive', 'field@crm.local', '9000000001', 'Business Development Executive', 1, 1, 1002, 0);

INSERT INTO product_divisions (id, code, name) VALUES
(1, 'SCH', 'School Books'),
(2, 'HE', 'Higher Education'),
(3, 'GEN', 'General / Trade');

INSERT INTO executive_product_divisions (executive_id, product_division_id) VALUES
(1001,1),(1001,3),(1002,1),(1002,3),(1003,1),(1003,2),(1003,3),(1004,1),(1004,2),(1004,3),(1005,1),(1005,2),(1005,3),(1006,1),(1006,2),(1006,3);

INSERT INTO territories (id, name) VALUES
(1, 'Delhi East'),
(2, 'Delhi Central'),
(3, 'NCR'),
(4, 'Mumbai');

INSERT INTO countries (id, name) VALUES (1, 'India');
INSERT INTO states (id, country_id, name) VALUES
(1,1,'Delhi'),(2,1,'Uttar Pradesh'),(3,1,'Maharashtra');
INSERT INTO districts (id, state_id, name) VALUES
(1,1,'Delhi'),(2,2,'Gautam Buddha Nagar'),(3,2,'Lucknow'),(4,3,'Mumbai');
INSERT INTO cities (id, district_id, name) VALUES
(1,1,'Delhi'),(2,1,'New Delhi'),(3,2,'Noida'),(4,3,'Lucknow'),(5,4,'Mumbai');

INSERT INTO executive_territories (executive_id, territory_id) VALUES
(1001,1),(1001,2),(1002,1),(1002,2),(1002,3),(1003,1),(1003,2),(1003,3),(1004,1),(1004,2),(1004,3),(1004,4),(1005,1),(1005,2),(1005,3),(1005,4),(1006,1),(1006,2),(1006,3),(1006,4);
INSERT INTO executive_cities (executive_id, city_id) VALUES
(1001,1),(1001,2),(1002,1),(1002,2),(1002,3),(1003,1),(1003,2),(1003,3),(1003,4),(1004,1),(1004,2),(1004,3),(1004,4),(1004,5),(1005,1),(1005,2),(1005,3),(1005,4),(1005,5),(1006,1),(1006,2),(1006,3),(1006,4),(1006,5);

INSERT INTO application_setup (key_name, key_value, description) VALUES
('ApprovedContactsNew', 'HDA,L4,L5', 'Profiles that create contacts directly as validated.'),
('ApprovedCustomerMasterNew', 'HDA', 'Profiles that create customers directly as validated.'),
('BackDateRequestDaysExpense', '10', 'Maximum age in days for an expense backdate request.'),
('BackDateRequestDaysVisit', '10', 'Maximum age in days for a visit backdate request.'),
('BackDateVisitEntry', '15', 'Maximum age in days for visit entry after approved backdate request.'),
('CustomerContactFirstLastNameMandatory', 'F', 'F=First, L=Last, B=Both.'),
('CustomerContactMobileEmailMandatory', 'N', 'M=Mobile, E=Email, A=Any, B=Both, N=None.'),
('CustomerTypes', 'SCHOOL,INSTITUTE,TRADE,LIBRARY', 'Enabled customer types.'),
('DisplayBookCode', 'N', 'Y=Book code, N=ISBN.'),
('DisplayFollowUpAction', 'Yes', 'Show follow-up action during visit entry.'),
('ExpenseEntryDays', '15', 'Normal expense entry age.'),
('ExpenseFutureDays', '15', 'Maximum future expense range.'),
('SamplingBudgetCheckApplied', 'Yes', 'Apply sampling budget checks.'),
('SamplingBudgetFor', 'overall', 'overall or titlewise.'),
('SamplingBudgetType', 'units', 'units or value.'),
('SamplingCustomerMaxQtyAllowed', '10', 'Maximum requested quantity per customer sampling line.'),
('SamplingEntryWithoutBudget', 'Yes', 'Allow request when budget is unavailable.'),
('SamplingSelfStockMaxQtyAllowed', '999', 'Maximum self-stock quantity per line.'),
('SchoolMobileEmailMandatory', 'M', 'M=Mobile, E=Email, A=Any, B=Both, N=None.'),
('TeacherMobileEmailMandatory', 'E', 'M=Mobile, E=Email, A=Any, B=Both, N=None.'),
('TravelPlanAdvanceDays', '3', 'Travel plan should be submitted this many days in advance.'),
('TravelPlanMaxDays', '63', 'Maximum future travel-plan date.'),
('VisitEntryDays', '3', 'Normal number of days after visit date for entry.'),
('VisitFeedbackMandatory', 'Yes', 'Visit feedback is mandatory.'),
('VisitFeedbackMinChar', '40', 'Minimum feedback characters.'),
('VisitBooksSampling', 'Y', 'Show book sampling controls during Visit/DSR entry.'),
('VisitEProducts', 'Y', 'Show E-Product promotion controls during Visit/DSR entry.');

INSERT INTO menus (id, menu_name, child_menu_name, route_path, sort_order, requires_approval_role, admin_only) VALUES
(1,'Customer','School List','/customers/school',10,0,0),
(2,'Customer','Trade List','/customers/trade',11,0,0),
(3,'Customer','Library List','/customers/library',12,0,0),
(4,'Visit/DSR','View Today''s Plan','/plans/today',20,0,0),
(5,'Visit/DSR','View Tomorrow''s Plan','/plans/tomorrow',21,0,0),
(6,'Visit/DSR','Visit Entry','/visits/new',22,0,0),
(7,'Sampling','School Sampling','/sampling/school',30,0,0),
(8,'Sampling','Trade Sampling','/sampling/trade',31,0,0),
(9,'Sampling','Library Sampling','/sampling/library',32,0,0),
(10,'Sampling','Customer Sampling Approval','/approvals/customer-sampling',40,1,0),
(11,'Sampling','Self-Stock Request','/self-stock',33,0,0),
(12,'Sampling','Self-Stock Approval','/approvals/self-stock',41,1,0),
(13,'Customer Approvals','Customer Create Approval','/approvals/customer-create',50,1,0),
(14,'Customer Approvals','Customer Update Approval','/approvals/customer-update',51,1,0),
(15,'Customer Approvals','Customer Delete Approval','/approvals/customer-delete',52,1,0),
(16,'Customer Approvals','Contact Approval','/approvals/contact-create',53,1,0),
(17,'Visit/DSR','Visit Backdate Approval','/approvals/visit-backdate',23,1,0),
(18,'Admin','User & Role Management','/admin/users',90,0,1),
(19,'Visit/DSR','Visit Backdate Request','/visits/backdate-request',24,0,0),
(20,'Admin','Request & Approval History','/admin/request-history',91,0,1),
(21,'Requests','My Request History','/requests/my-history',60,0,0);

-- Request menus are available to every profile.
INSERT INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id FROM profiles p JOIN menus m ON m.requires_approval_role = 0 AND m.admin_only = 0;

-- Approval menus are available only to manager/admin profiles. The API also checks each executive's approval_enabled flag.
INSERT INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id FROM profiles p JOIN menus m ON m.requires_approval_role = 1
WHERE p.level_rank >= 2;

-- Admin-only menu is mapped only to admin profiles.
INSERT INTO profile_menus (profile_id, menu_id)
SELECT p.id, m.id FROM profiles p JOIN menus m ON m.admin_only = 1
WHERE p.is_admin = 1;

INSERT INTO boards (id, name) VALUES (1,'CBSE'),(2,'ICSE'),(3,'State Board');
INSERT INTO chain_schools (id, name) VALUES (1,'Delhi Public School'),(2,'Kendriya Vidyalaya');
INSERT INTO data_sources (id, name) VALUES (1,'CRM Entry'),(2,'Field Visit'),(3,'Imported');
INSERT INTO salutations (id, name) VALUES (1,'Mr.'),(2,'Ms.'),(3,'Mrs.'),(4,'Dr.'),(5,'Prof.');
INSERT INTO contact_designations (id, name) VALUES (1,'Principal'),(2,'Teacher'),(3,'Coordinator'),(4,'Librarian'),(5,'Proprietor'),(6,'Accountant');
INSERT INTO adoption_roles (id, name) VALUES (1,'Decision Maker'),(2,'Influencer'),(3,'User');
INSERT INTO customer_categories (id, name) VALUES (1,'Bookseller'),(2,'Distributor'),(3,'Library Supplier');
INSERT INTO purchase_modes (id, name) VALUES (1,'Open'),(2,'Direct'),(3,'BookSeller');
INSERT INTO institute_types (id, name) VALUES (1,'Private'),(2,'Government');
INSERT INTO institute_levels (id, name) VALUES (1,'UG'),(2,'PG'),(3,'Both');
INSERT INTO affiliate_types (id, name) VALUES (1,'Unaffiliated'),(2,'Autonomous'),(3,'University Affiliated');

INSERT INTO subjects (id, name) VALUES (1,'English'),(2,'Mathematics'),(3,'Science'),(4,'Computer Science'),(5,'Social Studies');
INSERT INTO classes (id, class_num_id, name, sort_order) VALUES (1,-3,'Nry',1),(2,-2,'LKG',2),(3,-1,'UKG',3),(4,1,'1',4),(5,2,'2',5),(6,3,'3',6),(7,4,'4',7),(8,5,'5',8),(9,6,'6',9),(10,7,'7',10),(11,8,'8',11),(12,9,'9',12),(13,10,'10',13),(14,11,'11',14),(15,12,'12',15);

INSERT INTO academic_sessions (id, session_name, start_date, end_date, is_active) VALUES
(1,'2025-2026','2025-04-01','2026-03-31',1),
(2,'2026-2027','2026-04-01','2027-03-31',1);

-- Values below are based on the E-Product API contract supplied for this CRM.
INSERT INTO sales_stages (id, stage_name, sequence_num) VALUES
(1,'S0 - Attempted Meeting',1),
(2,'S1 - Met & Intro to Platform/Product',1),
(3,'S2 - Product Demonstration',1),
(4,'S3 - Product Trial',1),
(5,'S4 - Finalising Negotiation & MOU Signing',1),
(6,'S5 - Finalised Terms & Closure',1);

INSERT INTO brands (id, brand_name) VALUES
(1,'Cretile'),
(2,'GSL x CUPA'),
(3,'GSL x HBPE'),
(4,'IIT Guwahati'),
(5,'Tinkrworks'),
(6,'VEX');

INSERT INTO prospects (id, prospect_name) VALUES
(1,'Warm Prospect - interested in product'),
(2,'Cold Prospect - Next Year'),
(3,'Cold Prospect - Using some other Product or Supplier'),
(4,'Cold Prospect - Free Structure does not allow'),
(5,'Cold Prospect - Budget, decision-making authority or timing Issues');
INSERT INTO class_levels (id, name, sort_order) VALUES (1,'Pre-Primary',1),(2,'Primary',2),(3,'Middle',3),(4,'Secondary',4),(5,'Sr. Secondary',5);
INSERT INTO series (id, name) VALUES (1,'THE ENGLISH CIRCLE'),(2,'SCIENCE MISSION'),(3,'STEP BY STEP COMPUTER LEARNING');
INSERT INTO books (id, series_id, subject_id, class_level_id, title, isbn, author, list_price, book_num, book_type, physical_stock) VALUES
(1,1,1,2,'The English Circle - Book 1','9780000000001','Demo Author',280.00,'1','CB',40),
(2,1,1,2,'The English Circle - Book 2','9780000000002','Demo Author',290.00,'2','CB',25),
(3,2,3,3,'Science Mission - Class 6','9780000000003','Demo Author',340.00,'6','CB',18),
(4,3,4,2,'Step by Step Computer Learning - 4','9780000000004','Demo Author',200.00,'4','CB',15),
(5,NULL,1,NULL,'Oxford English Dictionary','9780000000005','Demo Author',550.00,NULL,'REFERENCE',12);


-- Dummy E-Product master rows that satisfy the supplied Brand/Product API examples.
INSERT INTO e_products (id, brand_id, subject_id, product_name, product_code, list_price) VALUES
(2,4,4,'Testing eprodcut 1','EP-02',859.00),
(3,2,4,'testing product 2','Product/02',499.00),
(4,2,4,'testing product 234','testing/01',599.00),
(5,2,4,'Testing eprodcut 1','SDSADSAq',859.00),
(6,2,4,'Vyakarana E-Book','EB01',399.00);

INSERT INTO e_product_classes (e_product_id, class_id) VALUES
(2,3),(2,4),(2,5),
(3,4),(3,5),(3,6),
(4,4),(4,5),(4,6),(4,7),
(5,2),(5,3),(5,4),(5,5),
(6,4),(6,5),(6,6),(6,7),(6,8);

INSERT INTO shipment_modes (id, name) VALUES
(1,'AIR COURIER'),(2,'BOOK POST'),(3,'SPEED POST'),(4,'SURFACE COURIER'),(5,'TRANSPORT');
INSERT INTO sampling_types (id, name) VALUES (1,'Promotional Copy'),(2,'Personal Copy'),(3,'Teachers Copy');
INSERT INTO visit_purposes (id, name) VALUES (1,'Meeting'),(2,'Followup'),(3,'Sampling'),(4,'Order Collection'),(5,'Payment Collection');

INSERT INTO customers
(id, customer_code, customer_type, customer_name, ref_code, email, mobile, address, city_id, pincode, key_customer, customer_status, validation_status, latitude, longitude, created_by_user_id, created_by_executive_id)
VALUES
(1,'SCH101','SCHOOL','Demo Public School','ERP-101','school@example.com','9111111111','Laxmi Nagar, Delhi',1,'110092',1,'ACTIVE','VALIDATED',28.6300000,77.2800000,1,1001),
(2,'TR101','TRADE','Demo Books Depot','TR-101','trade@example.com','9222222222','Daryaganj, New Delhi',2,'110002',0,'ACTIVE','VALIDATED',28.6400000,77.2400000,1,1001),
(3,'LR101','LIBRARY','Demo City Library','LIB-101','library@example.com','9333333333','Sector 18, Noida',3,'201301',0,'ACTIVE','VALIDATED',28.5700000,77.3200000,1,1001);

INSERT INTO customer_executives (customer_id, executive_id) VALUES
(1,1001),(1,1002),(2,1001),(2,1002),(3,1001),(3,1002);
INSERT INTO customer_category_map (customer_id, category_id) VALUES (2,1),(3,3);
INSERT INTO customer_school_details (customer_id, board_id, chain_school_id, start_class_id, end_class_id, medium_instruction, ranking, sampling_month, decision_month, purchase_mode_id)
VALUES (1,1,1,1,15,'English','A',11,3,3);
INSERT INTO customer_contacts
(id, customer_id, customer_type, primary_contact, salutation_id, designation_id, first_name, last_name, email, mobile, contact_status, validation_status, residential_address, residential_city_id, residential_pincode, data_source_id, created_by_user_id)
VALUES
(1,1,'SCHOOL',1,4,1,'Riya','Sharma','principal@example.com','9444444444','ACTIVE','VALIDATED','Preet Vihar, Delhi',1,'110092',1,1),
(2,1,'SCHOOL',0,1,2,'Aman','Verma','teacher@example.com','9555555555','ACTIVE','VALIDATED','Mayur Vihar, Delhi',1,'110091',1,1),
(3,2,'TRADE',1,1,5,'Rahul','Jain','owner@example.com','9666666666','ACTIVE','VALIDATED','Karol Bagh, New Delhi',2,'110005',1,1);

INSERT INTO sampling_budgets (executive_id, budget_year, book_id, total_units, used_units, total_value, used_value)
VALUES (1001, YEAR(CURRENT_DATE), NULL, 100, 0, 50000, 0),
       (1002, YEAR(CURRENT_DATE), NULL, 500, 0, 200000, 0);

INSERT INTO visit_plans (executive_id, customer_id, visit_purpose_id, plan_date, plan_type, remarks, created_by_user_id) VALUES
(1001,1,1,CURRENT_DATE,'VISIT','Meet principal',1),
(1001,2,2,DATE_ADD(CURRENT_DATE, INTERVAL 1 DAY),'VISIT','Follow up on order',1),
(1001,3,1,DATE_ADD(CURRENT_DATE, INTERVAL 1 DAY),'TRAVEL','NCR customer visit',1);
