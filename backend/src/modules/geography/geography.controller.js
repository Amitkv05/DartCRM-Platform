import { db } from "../../config/db.js";

export async function geography(req, res) {
  const params = [];
  let where = "1=1";
  if (req.query.cityId) { where += " AND c.id = ?"; params.push(req.query.cityId); }
  if (req.query.stateId) { where += " AND s.id = ?"; params.push(req.query.stateId); }
  const [rows] = await db.execute(
    `SELECT co.id AS country_id, co.name AS country,
            s.id AS state_id, s.name AS state,
            d.id AS district_id, d.name AS district,
            c.id AS city_id, c.name AS city
     FROM cities c
     JOIN districts d ON d.id = c.district_id
     JOIN states s ON s.id = d.state_id
     JOIN countries co ON co.id = s.country_id
     WHERE ${where} ORDER BY co.name, s.name, d.name, c.name`, params
  );
  res.json({ status: "success", geography: rows });
}
