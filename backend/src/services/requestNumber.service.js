import { AppError } from "../utils/AppError.js";

export async function nextRequestNumber(prefix, executor) {
  if (!executor) throw new AppError("Database executor is required for request number generation", 500);
  const now = new Date();
  const yy = String(now.getUTCFullYear()).slice(-2);
  const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
  const period = `${mm}${yy}`;

  const [rows] = await executor.execute(
    "SELECT last_number FROM request_sequences WHERE module_prefix = ? AND period = ? FOR UPDATE",
    [prefix, period]
  );

  let next = 1;
  if (rows[0]) {
    next = rows[0].last_number + 1;
    await executor.execute(
      "UPDATE request_sequences SET last_number = ? WHERE module_prefix = ? AND period = ?",
      [next, prefix, period]
    );
  } else {
    await executor.execute(
      "INSERT INTO request_sequences (module_prefix, period, last_number) VALUES (?, ?, 1)",
      [prefix, period]
    );
  }
  return `${prefix}/${period}/${next}`;
}
