import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { KeyRound, ShieldCheck } from "lucide-react";
import { crmBootstrap } from "@/api/apiClient";
import { authApi } from "@/api/crmApi";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FormField } from "@/components/common/FormField";
import { getErrorMessage } from "@/utils/errors";

export default function ResetPasswordPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const [resetToken, setResetToken] = useState(params.get("token") || "");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const mutation = useMutation({
    mutationFn: async () => {
      if (!resetToken.trim()) throw new Error("Reset token is required");
      if (newPassword.length < 8) throw new Error("New password must be at least 8 characters");
      if (newPassword !== confirmPassword) throw new Error("New passwords do not match");
      await crmBootstrap.ensureApiToken();
      return authApi.resetPassword({ resetToken: resetToken.trim(), newPassword });
    },
    onSuccess: () => setTimeout(() => navigate("/login", { replace: true }), 900),
  });

  return (
    <div className="crm-auth-shell relative grid min-h-screen place-items-center overflow-hidden p-5">
      <div className="crm-ambient crm-ambient-cyan" />
      <div className="crm-ambient crm-ambient-red" />
      <div className="w-full max-w-md">
        <div className="crm-auth-panel rounded-[22px] p-7 sm:p-9">
          <div className="mb-5 flex items-center justify-between">
            <div className="grid h-11 w-11 place-items-center rounded-xl border border-brand-400/15 bg-brand-400/[.08] text-brand-300"><KeyRound size={19}/></div>
            <div className="flex items-center gap-1.5 text-[8px] font-semibold uppercase tracking-[.12em] text-emerald-400"><ShieldCheck size={13}/>Secure reset</div>
          </div>
          <h1 className="text-[25px] font-black tracking-[-.04em] text-white">Reset password</h1>
          <p className="mt-2 text-[10px] leading-5 text-slate-500">Enter your reset token and choose a new password. The existing backend reset flow is unchanged.</p>
          <div className="mt-7 space-y-4">
            <FormField label="Reset Token" required><Input value={resetToken} onChange={(e) => setResetToken(e.target.value)} placeholder="Paste reset token" /></FormField>
            <FormField label="New Password" required><Input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="Minimum 8 characters" /></FormField>
            <FormField label="Confirm New Password" required><Input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} /></FormField>
            {mutation.isError && <div className="rounded-xl border border-red-400/15 bg-red-400/[.06] p-3 text-[10px] leading-5 text-red-300">{getErrorMessage(mutation.error)}</div>}
            {mutation.isSuccess && <div className="rounded-xl border border-emerald-400/15 bg-emerald-400/[.06] p-3 text-[10px] text-emerald-300">Password changed. Returning to login…</div>}
            <Button className="w-full" variant="primary" disabled={mutation.isPending} onClick={() => mutation.mutate()}>{mutation.isPending ? "Updating…" : "Reset Password"}</Button>
            <Link className="block text-center text-[10px] font-semibold text-brand-300 transition hover:text-brand-200" to="/login">Back to login</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
