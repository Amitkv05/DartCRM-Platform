import { useMutation } from "@tanstack/react-query";
import { Trash2 } from "lucide-react";
import { toast } from "sonner";
import { fileApi } from "@/api/crmApi";
import {
  WorkflowSection,
  EmptyMessage,
} from "@/components/parity/WorkflowSection";
import AnimatedFileUpload from "@/components/common/AnimatedFileUpload";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { getErrorMessage } from "@/utils/errors";

export default function DocumentPanel({ documents, onChange }) {
  const upload = useMutation({
    // mutationFn: ({ file, name }) => fileApi.upload(file, "visit"),
    mutationFn: ({ file }) => fileApi.upload(file, "visit"),
    onSuccess: (r, vars) => {
      onChange([
        ...documents,
        {
          documentName: vars.name || r.file.originalFileName || "Document",
          fileName: r.file.fileName,
          fileSize: r.file.fileSize,
          url: r.file.url,
        },
      ]);
      toast.success("Document uploaded");
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  return (
    <WorkflowSection title="Upload Documents">
      <div className="space-y-4">
        <div className="grid gap-4 xl:grid-cols-[minmax(0,.65fr)_minmax(380px,1.35fr)]">
          <div>
            <p className="mb-1.5 text-[10px] font-bold uppercase tracking-[.08em] text-slate-500">Document name</p>
            <Input id="visit-doc-name" placeholder="Document Name (optional)" />
            <p className="mt-2 text-[9px] leading-4 text-slate-600">
              If left empty, DartCRM will use the selected file name. Accepted: JPG, PNG, PDF, DOC, DOCX, XLS, XLSX.
            </p>
          </div>

          <AnimatedFileUpload
            maxSizeMB={10}
            disabled={upload.isPending}
            accept=".jpg,.jpeg,.png,.pdf,.doc,.docx,.xls,.xlsx"
            onValidationError={(message) => toast.error(message)}
            onUpload={async (file) => {
              const name = document.getElementById("visit-doc-name")?.value?.trim() || file.name;
              await upload.mutateAsync({ file, name });
            }}
          />
        </div>

        {!documents.length ? (
          <EmptyMessage>No documents uploaded.</EmptyMessage>
        ) : (
          <div className="crm-table-shell overflow-x-auto rounded-xl border border-white/[.06]">
            <table className="w-full min-w-[650px] text-sm">
              <thead className="bg-white/[.025]">
                <tr>
                  <th className="p-3 text-left text-[9px] uppercase tracking-[.08em] text-slate-500">S.No</th>
                  <th className="p-3 text-left text-[9px] uppercase tracking-[.08em] text-slate-500">Document Name</th>
                  <th className="p-3 text-left text-[9px] uppercase tracking-[.08em] text-slate-500">Uploaded File</th>
                  <th className="p-3 text-right text-[9px] uppercase tracking-[.08em] text-slate-500">Action</th>
                </tr>
              </thead>
              <tbody>
                {documents.map((d, i) => (
                  <tr key={`${d.fileName}-${i}`} className="border-t border-white/[.045]">
                    <td className="p-3">{i + 1}</td>
                    <td className="p-3">{d.documentName}</td>
                    <td className="p-3 text-slate-400">{d.fileName}</td>
                    <td className="p-3 text-right">
                      <Button
                        type="button"
                        size="icon"
                        variant="ghost"
                        className="text-red-400"
                        onClick={() => onChange(documents.filter((_, idx) => idx !== i))}
                      >
                        <Trash2 size={15} />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </WorkflowSection>
  );
}
