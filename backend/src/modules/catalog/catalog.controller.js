import { db } from "../../config/db.js";

export async function seriesAndClassLevels(req, res) {
  const [classLevels] = await db.execute("SELECT id, name FROM class_levels ORDER BY sort_order");
  const [series] = await db.execute("SELECT id, name FROM series WHERE is_active = 1 ORDER BY name");
  res.json({ status: "success", classLevels, series });
}

export async function titles(req, res) {
  const where = ["b.is_active = 1"];
  const params = [];
  if (req.query.seriesId) { where.push("b.series_id = ?"); params.push(req.query.seriesId); }
  if (req.query.bookISBN) { where.push("(b.isbn LIKE ? OR b.title LIKE ?)"); const q=`%${req.query.bookISBN}%`; params.push(q,q); }
  if (req.query.classLevelId) { where.push("b.class_level_id = ?"); params.push(req.query.classLevelId); }
  const [rows] = await db.execute(
    `SELECT b.id AS book_id, b.title, b.isbn, b.author, b.list_price, b.book_num, b.book_type,
            b.physical_stock, b.series_id, b.subject_id, s.name AS series_name, b.class_level_id
     FROM books b LEFT JOIN series s ON s.id = b.series_id
     WHERE ${where.join(" AND ")} ORDER BY b.title`, params
  );
  res.json({ status: "success", titles: rows });
}

export async function titleNotInSeries(req, res) {
  req.query.bookISBN = req.query.query || req.query.titleOrISBN || "";
  req.query.seriesId = null;
  return titles(req, res);
}

export async function shipmentModes(req, res) {
  const [rows] = await db.execute("SELECT id AS shipment_mode_id, name AS shipment_mode FROM shipment_modes WHERE is_active = 1 ORDER BY id");
  res.json({ status: "success", shipmentModes: rows });
}
