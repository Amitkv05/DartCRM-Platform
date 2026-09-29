import { useMutation } from "@tanstack/react-query";
import { FileUp, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { fileApi } from "@/api/crmApi";
import {
  WorkflowSection,
  EmptyMessage,
} from "@/components/parity/WorkflowSection";
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
      <div className="space-y-3">
        <div className="grid gap-3 md:grid-cols-[1fr_1.5fr_auto]">
          <Input id="visit-doc-name" placeholder="Document Name" />
          <label className="flex h-10 cursor-pointer items-center rounded-lg border border-slate-200 bg-white px-3 text-sm dark:border-slate-700 dark:bg-slate-950">
            <FileUp size={15} className="mr-2" />
            {upload.isPending ? "Uploading…" : "Choose PDF / Image / Document"}
            <input
              type="file"
              className="hidden"
              disabled={upload.isPending}
              accept=".jpg,.jpeg,.png,.pdf,.doc,.docx,.xls,.xlsx"
              onChange={(e) => {
                const f = e.target.files?.[0];
                if (!f) return;
                const name =
                  document.getElementById("visit-doc-name")?.value?.trim() ||
                  f.name;
                upload.mutate({ file: f, name });
                e.target.value = "";
              }}
            />
          </label>
          <span className="self-center text-xs text-slate-500">Max 10 MB</span>
        </div>
        {!documents.length ? (
          <EmptyMessage>No documents uploaded.</EmptyMessage>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[650px] text-sm">
              <thead className="bg-amber-100 dark:bg-amber-950/30">
                <tr>
                  <th className="p-2 text-left">S.No</th>
                  <th className="p-2 text-left">Document Name</th>
                  <th className="p-2 text-left">Uploaded File</th>
                  <th className="p-2 text-right">Action</th>
                </tr>
              </thead>
              <tbody>
                {documents.map((d, i) => (
                  <tr
                    key={`${d.fileName}-${i}`}
                    className="border-t dark:border-slate-800"
                  >
                    <td className="p-2">{i + 1}</td>
                    <td className="p-2">{d.documentName}</td>
                    <td className="p-2">{d.fileName}</td>
                    <td className="p-2 text-right">
                      <Button
                        type="button"
                        size="icon"
                        variant="ghost"
                        className="text-red-600"
                        onClick={() =>
                          onChange(documents.filter((_, idx) => idx !== i))
                        }
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
