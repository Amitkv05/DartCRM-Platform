import { db } from "../config/db.js";

export async function getSetupMap(executor = db) {
  const [rows] = await executor.execute(
    "SELECT key_name, key_value FROM application_setup WHERE is_active = 1"
  );
  return Object.fromEntries(rows.map((row) => [row.key_name, row.key_value]));
}

export async function getSetupValue(key, executor = db) {
  const [rows] = await executor.execute(
    "SELECT key_value FROM application_setup WHERE key_name = ? AND is_active = 1 LIMIT 1",
    [key]
  );
  return rows[0]?.key_value ?? null;
}
