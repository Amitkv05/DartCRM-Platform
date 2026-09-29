import { db } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { requireFields } from "../../utils/validation.js";

export async function productsByBrand(req, res) {
  const brandId = Number.parseInt(req.params.brandId, 10);
  if (!Number.isInteger(brandId) || brandId <= 0) {
    throw new AppError("brandId must be a positive integer", 400);
  }

  const [brandRows] = await db.execute(
    "SELECT id, brand_name FROM brands WHERE id = ? AND is_active = 1 LIMIT 1",
    [brandId]
  );
  if (!brandRows[0]) throw new AppError("Brand not found", 404);

  const [rows] = await db.execute(
    `SELECT ep.id, ep.product_name, ep.product_code, b.brand_name
     FROM e_products ep
     JOIN brands b ON b.id = ep.brand_id
     WHERE ep.brand_id = ? AND ep.is_active = 1
     ORDER BY ep.product_name, ep.id`,
    [brandId]
  );

  res.json({ status: "success", productList: rows, products: [] });
}

export async function productDetails(req, res) {
  const eProductId = Number.parseInt(req.params.eProductId, 10);
  requireFields(req.query, ["academicSessionId", "customerId"]);
  const academicSessionId = Number.parseInt(req.query.academicSessionId, 10);
  const customerId = Number.parseInt(req.query.customerId, 10);

  if (!Number.isInteger(eProductId) || eProductId <= 0) {
    throw new AppError("eProductId must be a positive integer", 400);
  }
  if (!Number.isInteger(academicSessionId) || academicSessionId <= 0) {
    throw new AppError("academicSessionId must be a positive integer", 400);
  }
  if (!Number.isInteger(customerId) || customerId <= 0) {
    throw new AppError("customerId must be a positive integer", 400);
  }

  const [sessionRows] = await db.execute(
    "SELECT id FROM academic_sessions WHERE id = ? AND is_active = 1 LIMIT 1",
    [academicSessionId]
  );
  if (!sessionRows[0]) throw new AppError("Academic Session not found", 404);

  const [customerRows] = await db.execute(
    "SELECT id FROM customers WHERE id = ? AND customer_status = 'ACTIVE' LIMIT 1",
    [customerId]
  );
  if (!customerRows[0]) throw new AppError("Customer not found", 404);

  const [productRows] = await db.execute(
    `SELECT ep.id AS e_product_id, ep.product_name, ep.list_price,
            COALESCE(s.name, '') AS subject_name
     FROM e_products ep
     LEFT JOIN subjects s ON s.id = ep.subject_id
     WHERE ep.id = ? AND ep.is_active = 1 LIMIT 1`,
    [eProductId]
  );
  const product = productRows[0];
  if (!product) throw new AppError("E-Product not found", 404);

  const [previousRows] = await db.execute(
    `SELECT ss.stage_name, ss.sequence_num
     FROM visit_eproduct_promotions vep
     JOIN visits v ON v.id = vep.visit_id
     JOIN sales_stages ss ON ss.id = vep.sales_stage_id
     WHERE v.customer_id = ? AND vep.e_product_id = ?
     ORDER BY v.visit_date DESC, v.id DESC, vep.id DESC
     LIMIT 1`,
    [customerId, eProductId]
  );
  const previous = previousRows[0];

  const [classes] = await db.execute(
    `SELECT c.class_num_id, c.name AS class_name
     FROM e_product_classes epc
     JOIN classes c ON c.id = epc.class_id
     WHERE epc.e_product_id = ?
     ORDER BY c.sort_order, c.id`,
    [eProductId]
  );

  res.json({
    status: "success",
    productDetails: [
      {
        eProductId: Number(product.e_product_id),
        eProductName: product.product_name,
        listPrice: Number(product.list_price),
        subjectName: product.subject_name,
        previousSalesStage: previous?.stage_name || "",
        previousStageSequenceNum: Number(previous?.sequence_num || 0),
      },
    ],
    classes: classes.map((row) => ({
      classNumId: Number(row.class_num_id),
      className: row.class_name,
    })),
    products: [],
  });
}
