import { useEffect, useMemo, useRef, useState } from "react";
import {
  CheckCircle2,
  FileText,
  Image as ImageIcon,
  Paperclip,
  UploadCloud,
  X,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

function prettyBytes(bytes) {
  if (!Number.isFinite(bytes)) return "";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function AnimatedFileUpload({
  accept = ".jpg,.jpeg,.png,.pdf",
  maxSizeMB = 10,
  disabled = false,
  onUpload,
  onValidationError,
  className,
}) {
  const inputRef = useRef(null);
  const progressTimer = useRef(null);
  const resetTimer = useRef(null);
  const [dragging, setDragging] = useState(false);
  const [file, setFile] = useState(null);
  const [status, setStatus] = useState("idle");
  const [progress, setProgress] = useState(0);
  const [message, setMessage] = useState("");

  const previewUrl = useMemo(() => {
    if (!file || !file.type?.startsWith("image/")) return null;
    return URL.createObjectURL(file);
  }, [file]);

  useEffect(() => () => {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
  }, [previewUrl]);

  useEffect(() => () => {
    window.clearInterval(progressTimer.current);
    window.clearTimeout(resetTimer.current);
  }, []);

  const reset = () => {
    window.clearInterval(progressTimer.current);
    window.clearTimeout(resetTimer.current);
    setFile(null);
    setStatus("idle");
    setProgress(0);
    setMessage("");
    if (inputRef.current) inputRef.current.value = "";
  };

  const selectFile = (candidate) => {
    if (!candidate || disabled || status === "uploading") return;
    const acceptedRules = String(accept || "")
      .split(",")
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean);

    if (acceptedRules.length) {
      const fileName = String(candidate.name || "").toLowerCase();
      const mimeType = String(candidate.type || "").toLowerCase();
      const extension = fileName.includes(".")
        ? `.${fileName.split(".").pop()}`
        : "";

      const allowed = acceptedRules.some((rule) => {
        if (rule.startsWith(".")) return extension === rule;
        if (rule.endsWith("/*")) {
          return mimeType.startsWith(rule.slice(0, -1));
        }
        return mimeType === rule;
      });

      if (!allowed) {
        const text = "Only JPG, JPEG, PNG and PDF files are allowed.";
        setStatus("error");
        setMessage(text);
        onValidationError?.(text);
        return;
      }
    }

    const maxBytes = maxSizeMB * 1024 * 1024;
    if (candidate.size > maxBytes) {
      const text = `File size cannot exceed ${maxSizeMB} MB.`;
      setStatus("error");
      setMessage(text);
      onValidationError?.(text);
      return;
    }
    setFile(candidate);
    setStatus("ready");
    setProgress(0);
    setMessage("");
  };

  const upload = async () => {
    if (!file || disabled || status === "uploading") return;
    setStatus("uploading");
    setMessage("");
    setProgress(8);

    window.clearInterval(progressTimer.current);
    progressTimer.current = window.setInterval(() => {
      setProgress((value) => {
        if (value >= 88) return value;
        return Math.min(88, value + Math.max(2, Math.round((92 - value) / 7)));
      });
    }, 180);

    try {
      await onUpload?.(file);
      window.clearInterval(progressTimer.current);
      setProgress(100);
      setStatus("success");
      setMessage("File successfully uploaded!");
      resetTimer.current = window.setTimeout(reset, 1800);
    } catch {
      window.clearInterval(progressTimer.current);
      setStatus("error");
      setProgress(0);
      setMessage("Upload failed. Please try again.");
    }
  };

  const icon = file?.type?.startsWith("image/") ? <ImageIcon size={20} /> : <FileText size={20} />;

  return (
    <div className={cn("crm-upload-widget", className)} data-status={status}>
      <div
        className={cn("crm-upload-dropzone", dragging && "is-dragging", file && "has-file")}
        onDragEnter={(e) => {
          e.preventDefault();
          if (!disabled) setDragging(true);
        }}
        onDragOver={(e) => {
          e.preventDefault();
          if (!disabled) setDragging(true);
        }}
        onDragLeave={(e) => {
          e.preventDefault();
          if (!e.currentTarget.contains(e.relatedTarget)) setDragging(false);
        }}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          selectFile(e.dataTransfer.files?.[0]);
        }}
        onClick={() => !file && !disabled && inputRef.current?.click()}
        role="button"
        tabIndex={disabled ? -1 : 0}
        onKeyDown={(e) => {
          if (!file && !disabled && (e.key === "Enter" || e.key === " ")) {
            e.preventDefault();
            inputRef.current?.click();
          }
        }}
      >
        <input
          ref={inputRef}
          type="file"
          className="sr-only"
          accept={accept}
          disabled={disabled || status === "uploading"}
          onChange={(e) => selectFile(e.target.files?.[0])}
        />

        <div className="crm-upload-orbit" aria-hidden="true">
          <span className="crm-upload-orbit-card crm-upload-orbit-card-left"><FileText size={14} /></span>
          <span className="crm-upload-orbit-card crm-upload-orbit-card-center"><ImageIcon size={15} /></span>
          <span className="crm-upload-orbit-card crm-upload-orbit-card-right"><Paperclip size={13} /></span>
        </div>

        {!file ? (
          <div className="crm-upload-empty">
            <div className="crm-upload-icon"><UploadCloud size={25} /></div>
            <p className="crm-upload-title">Drag & drop a JPG, PNG or PDF file</p>
            <p className="crm-upload-subtitle">or <span>browse files</span> from your computer</p>
            <span className="crm-upload-limit">Maximum file size: {maxSizeMB} MB</span>
          </div>
        ) : (
          <div className="crm-upload-selected" onClick={(e) => e.stopPropagation()}>
            <div className="crm-upload-preview">
              {previewUrl ? <img src={previewUrl} alt="Selected upload preview" /> : icon}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[11px] font-bold text-slate-100">{file.name}</p>
              <p className="mt-1 text-[9px] text-slate-500">{prettyBytes(file.size)} · Ready to upload</p>
            </div>
            <button
              type="button"
              className="crm-upload-remove"
              aria-label="Remove selected file"
              disabled={status === "uploading"}
              onClick={reset}
            >
              <X size={14} />
            </button>
          </div>
        )}
      </div>

      {file && status !== "success" && (
        <Button
          type="button"
          variant="primary"
          className="crm-upload-action w-full"
          disabled={disabled || status === "uploading"}
          loading={status === "uploading"}
          onClick={upload}
        >
          {status === "uploading" ? `Uploading… ${progress}%` : "Upload File"}
        </Button>
      )}

      {status === "uploading" && (
        <div className="crm-upload-progress" aria-label={`Upload progress ${progress}%`}>
          <span style={{ width: `${progress}%` }} />
        </div>
      )}

      {status === "success" && (
        <div className="crm-upload-success" role="status">
          <CheckCircle2 size={18} />
          <span>{message}</span>
        </div>
      )}

      {status === "error" && message && (
        <div className="crm-upload-error" role="alert">{message}</div>
      )}
    </div>
  );
}
