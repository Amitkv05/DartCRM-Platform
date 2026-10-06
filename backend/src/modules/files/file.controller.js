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

function decodeBase64Document(value) {
  const raw = String(value || "").trim();
  const base64 = raw.includes(",") ? raw.slice(raw.indexOf(",") + 1) : raw;
  const compact = base64.replace(/\s+/g, "");

  // Buffer.from(..., "base64") is intentionally permissive and silently
  // ignores invalid characters. Validate the encoded text before decoding so
  // malformed payloads cannot be stored as files.
  if (
    !compact ||
    compact.length % 4 !== 0 ||
    !/^[A-Za-z0-9+/]*={0,2}$/.test(compact)
  ) {
    throw new AppError("Invalid Base64 document data", 400);
  }

  const bytes = Buffer.from(compact, "base64");
  if (!bytes.length) {
    throw new AppError("Uploaded document is empty", 400);
  }

  return bytes;
}

function hasExpectedSignature(bytes, extension) {
  if (extension === "pdf") {
    return (
      bytes.length >= 5 &&
      bytes[0] === 0x25 && // %
      bytes[1] === 0x50 && // P
      bytes[2] === 0x44 && // D
      bytes[3] === 0x46 && // F
      bytes[4] === 0x2d // -
    );
  }

  if (extension === "jpg" || extension === "jpeg") {
    return (
      bytes.length >= 3 &&
      bytes[0] === 0xff &&
      bytes[1] === 0xd8 &&
      bytes[2] === 0xff
    );
  }

  if (extension === "png") {
    const signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    return (
      bytes.length >= signature.length &&
      signature.every((value, index) => bytes[index] === value)
    );
  }

  return false;
}

export async function uploadFile(req, res) {
  requireFields(req.body, ["fileName", "base64String"]);

  const suppliedExtension = String(
    req.body.fileExtension || path.extname(req.body.fileName).slice(1),
  )
    .trim()
    .toLowerCase();

  if (!allowedExtensions.has(suppliedExtension)) {
    throw new AppError("Only PDF, JPG, JPEG and PNG files are allowed", 400);
  }

  const fileNameExtension = path.extname(String(req.body.fileName || ""))
    .slice(1)
    .trim()
    .toLowerCase();

  // Do not allow a client to claim a different extension in fileExtension
  // than the extension shown in fileName.
  if (fileNameExtension && fileNameExtension !== suppliedExtension) {
    throw new AppError("File extension does not match the uploaded file name", 400);
  }

  const bytes = decodeBase64Document(req.body.base64String);

  if (bytes.length > maxFileBytes) {
    throw new AppError("Document size cannot exceed 10 MB", 413);
  }

  if (!hasExpectedSignature(bytes, suppliedExtension)) {
    throw new AppError(
      "Uploaded file content does not match its PDF/JPG/PNG extension",
      400,
    );
  }

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
