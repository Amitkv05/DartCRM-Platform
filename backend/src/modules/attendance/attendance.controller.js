import { db, withTransaction } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { requireFields } from "../../utils/validation.js";

export async function checkIn(req, res) {
  requireFields(req.body, ["latitude", "longitude"]);
  const executiveId = req.user.executiveId;
  const today = new Date().toISOString().slice(0, 10);
  const result = await withTransaction(async (connection) => {
    const [rows] = await connection.execute(
      "SELECT * FROM checkin_checkout WHERE executive_id = ? AND work_date = ? FOR UPDATE",
      [executiveId, today]
    );
    if (rows[0]?.check_in_at) throw new AppError("Already checked in for today", 409);
    if (rows[0]) {
      await connection.execute(
        `UPDATE checkin_checkout SET check_in_at = CURRENT_TIMESTAMP, check_in_latitude = ?, check_in_longitude = ?,
         check_in_address = ? WHERE id = ?`,
        [req.body.latitude, req.body.longitude, req.body.address || null, rows[0].id]
      );
      return rows[0].id;
    }
    const [insert] = await connection.execute(
      `INSERT INTO checkin_checkout
       (executive_id, work_date, check_in_at, check_in_latitude, check_in_longitude, check_in_address, entered_by_user_id)
       VALUES (?, ?, CURRENT_TIMESTAMP, ?, ?, ?, ?)`,
      [executiveId, today, req.body.latitude, req.body.longitude, req.body.address || null, req.user.userId]
    );
    return insert.insertId;
  });
  res.status(201).json({ status: "success", attendanceId: result, message: "Checked In successfully", currentTime: new Date().toISOString() });
}

export async function checkOut(req, res) {
  requireFields(req.body, ["latitude", "longitude"]);
  const executiveId = req.user.executiveId;
  const today = new Date().toISOString().slice(0, 10);
  await withTransaction(async (connection) => {
    const [rows] = await connection.execute(
      "SELECT * FROM checkin_checkout WHERE executive_id = ? AND work_date = ? FOR UPDATE",
      [executiveId, today]
    );
    const record = rows[0];
    if (!record?.check_in_at) throw new AppError("Check-in is required before checkout", 409);
    if (record.check_out_at) throw new AppError("Already checked out for today", 409);
    await connection.execute(
      `UPDATE checkin_checkout SET check_out_at = CURRENT_TIMESTAMP, check_out_latitude = ?, check_out_longitude = ?,
       check_out_address = ? WHERE id = ?`,
      [req.body.latitude, req.body.longitude, req.body.address || null, record.id]
    );
  });
  res.json({ status: "success", message: "Checked Out successfully" });
}

export async function todayStatus(req, res) {
  const today = new Date().toISOString().slice(0, 10);
  const [rows] = await db.execute(
    "SELECT * FROM checkin_checkout WHERE executive_id = ? AND work_date = ? LIMIT 1",
    [req.user.executiveId, today]
  );
  res.json({ status: "success", attendance: rows[0] || null });
}

export async function submitLocations(req, res) {
  if (!Array.isArray(req.body.locations) || req.body.locations.length === 0) throw new AppError("locations array is required", 400);
  await withTransaction(async (connection) => {
    for (const item of req.body.locations) {
      requireFields(item, ["latitude", "longitude"]);
      await connection.execute(
        `INSERT INTO executive_locations (executive_id, recorded_at, latitude, longitude, address, entered_by_user_id)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [req.user.executiveId, item.recordedAt || new Date(), item.latitude, item.longitude, item.address || null, req.user.userId]
      );
    }
  });
  res.status(201).json({ status: "success", message: "Executive location submitted successfully" });
}
