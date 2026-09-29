import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { KeyRound } from "lucide-react";
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
    <div className="grid min-h-screen place-items-center bg-slate-50 p-5 dark:bg-slate-950">
      <div className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-7 shadow-soft dark:border-slate-800 dark:bg-slate-900 sm:p-9">
        <div className="mb-5 grid h-12 w-12 place-items-center rounded-2xl bg-brand-100 text-brand-700 dark:bg-brand-950"><KeyRound size={22}/></div>
        <h1 className="text-2xl font-black">Reset password</h1>
        <p className="mt-2 text-sm text-slate-500">Enter the reset token and choose a new password.</p>
        <div className="mt-6 space-y-4">
          <FormField label="Reset Token" required><Input value={resetToken} onChange={(e) => setResetToken(e.target.value)} placeholder="Paste reset token" /></FormField>
          <FormField label="New Password" required><Input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="Minimum 8 characters" /></FormField>
          <FormField label="Confirm New Password" required><Input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} /></FormField>
          {mutation.isError && <div className="rounded-xl bg-red-50 p-3 text-sm text-red-700 dark:bg-red-950/30 dark:text-red-300">{getErrorMessage(mutation.error)}</div>}
          {mutation.isSuccess && <div className="rounded-xl bg-emerald-50 p-3 text-sm text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-300">Password changed. Returning to login…</div>}
          <Button className="w-full" variant="primary" disabled={mutation.isPending} onClick={() => mutation.mutate()}>{mutation.isPending ? "Updating…" : "Reset Password"}</Button>
          <Link className="block text-center text-sm font-semibold text-brand-700" to="/login">Back to login</Link>
        </div>
      </div>
    </div>
  );
}
