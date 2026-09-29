-- CRM backend 2.3 deployment-readiness migration.
-- Run ONCE on an existing V2 database after 001_upgrade_previous_v2.sql.
-- Makes DSR/Visit Person Met optional, matching the mobile UI and documented API uncertainty.

SET @db_name := DATABASE();

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'visits'
     AND COLUMN_NAME = 'customer_contact_id' AND IS_NULLABLE = 'NO') > 0,
  'ALTER TABLE visits MODIFY COLUMN customer_contact_id BIGINT UNSIGNED NULL',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
