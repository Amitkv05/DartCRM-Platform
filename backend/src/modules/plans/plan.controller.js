import { db } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { getSetupMap } from "../../services/setup.service.js";

export async function getPlanList(req, res) {
  const executiveId = Number(req.query.executiveId || req.user.executiveId);
  const [rows] = await db.execute(
    `SELECT vp.id, vp.plan_date, vp.plan_type, vp.visit_purpose_id, vpr.name AS visit_purpose,
            c.id AS customer_id, c.customer_code, c.customer_name, c.customer_type, c.address,
            ci.name AS city
     FROM visit_plans vp
     JOIN customers c ON c.id = vp.customer_id
     LEFT JOIN visit_purposes vpr ON vpr.id = vp.visit_purpose_id
     LEFT JOIN cities ci ON ci.id = c.city_id
     WHERE vp.executive_id = ? AND vp.plan_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 1 DAY)
     ORDER BY vp.plan_date, vp.id`, [executiveId]
  );
  const today = new Date().toISOString().slice(0, 10);
  const tomorrow = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
  res.json({
    status: "success",
    todayPlan: rows.filter((r) => String(r.plan_date).slice(0,10) === today && r.plan_type !== "TRAVEL"),
    tomorrowPlan: rows.filter((r) => String(r.plan_date).slice(0,10) === tomorrow && r.plan_type !== "TRAVEL"),
    travelPlan: rows.filter((r) => r.plan_type === "TRAVEL"),
  });
}

export async function createPlan(req, res) {
  if (!req.body.customerId || !req.body.planDate) throw new AppError("customerId and planDate are required", 400);
  const planType = String(req.body.planType || "VISIT").trim().toUpperCase();
  if (planType === "TRAVEL") {
    const setup = await getSetupMap();
    const advance = Number(setup.TravelPlanAdvanceDays || 0);
    const maxDays = Number(setup.TravelPlanMaxDays || 63);
    const planDate = new Date(`${req.body.planDate}T00:00:00Z`);
    const today = new Date();
    const dayMs = 86400000;
    const diff = Math.floor((Date.UTC(planDate.getUTCFullYear(), planDate.getUTCMonth(), planDate.getUTCDate()) - Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate())) / dayMs);
    if (diff < advance) throw new AppError(`Travel plan must be at least ${advance} days in advance`, 409);
    if (diff > maxDays) throw new AppError(`Travel plan cannot be more than ${maxDays} days in the future`, 409);
  }
  const [result] = await db.execute(
    `INSERT INTO visit_plans (executive_id, customer_id, visit_purpose_id, plan_date, plan_type, remarks, created_by_user_id)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [req.body.executiveId || req.user.executiveId, req.body.customerId, req.body.visitPurposeId || null,
     req.body.planDate, planType, req.body.remarks || null, req.user.userId]
  );
  res.status(201).json({ status: "success", planId: result.insertId });
}
