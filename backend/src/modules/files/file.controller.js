import path from "node:path";
import crypto from "node:crypto";
import { mkdir, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { AppError } from "../../utils/AppError.js";
import { requireFields } from "../../utils/validation.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "../../..");
const uploadsRoot = path.join(projectRoot, "uploads");

const allowedExtensions = new Set(["pdf", "jpg", "jpeg", "png"]);
const maxFileBytes = 10 * 1024 * 1024;

function cleanSegment(value, fallback) {
  const cleaned = String(value || "")
    .trim()
    .replace(/[^a-zA-Z0-9_-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60);
  return cleaned || fallback;
}

function cleanBaseName(fileName) {
  const parsed = path.parse(String(fileName || "document"));
  return cleanSegment(parsed.name, "document").slice(0, 80);
}

export async function uploadFile(req, res) {
  requireFields(req.body, ["fileName", "base64String"]);

  const suppliedExtension = String(req.body.fileExtension || path.extname(req.body.fileName).slice(1))
    .trim()
    .toLowerCase();
  if (!allowedExtensions.has(suppliedExtension)) {
    throw new AppError("Only PDF, JPG, JPEG and PNG files are allowed", 400);
  }

  const raw = String(req.body.base64String || "").trim();
  const base64 = raw.includes(",") ? raw.slice(raw.indexOf(",") + 1) : raw;
  let bytes;
  try {
    bytes = Buffer.from(base64, "base64");
  } catch (_) {
    throw new AppError("Invalid Base64 document data", 400);
  }
  if (!bytes.length) throw new AppError("Uploaded document is empty", 400);
  if (bytes.length > maxFileBytes) throw new AppError("Document size cannot exceed 10 MB", 413);

  const moduleName = cleanSegment(req.body.module, "visit").toLowerCase();
  const dir = path.join(uploadsRoot, moduleName);
  await mkdir(dir, { recursive: true });

  const baseName = cleanBaseName(req.body.fileName);
  const unique = `${Date.now()}-${crypto.randomBytes(5).toString("hex")}`;
  const storedName = `${baseName}-${unique}.${suppliedExtension}`;
  await writeFile(path.join(dir, storedName), bytes);

  const relativeUrl = `/uploads/${moduleName}/${storedName}`;
  const protocol = req.protocol || "http";
  const host = req.get("host");
  res.status(201).json({
    status: "success",
    message: "Document uploaded successfully",
    file: {
      fileName: storedName,
      originalFileName: String(req.body.fileName),
      module: moduleName,
      fileSize: bytes.length,
      url: host ? `${protocol}://${host}${relativeUrl}` : relativeUrl,
      relativeUrl,
    },
  });
}
