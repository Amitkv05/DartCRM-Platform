import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useDispatch, useSelector } from "react-redux";
import { Navigate, useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Eye, EyeOff, KeyRound, LockKeyhole, Mail, ShieldCheck } from "lucide-react";
import { crmBootstrap } from "@/api/apiClient";
import { authApi, setupApi } from "@/api/crmApi";
import { setMenus, setSession } from "@/features/auth/authSlice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FormField } from "@/components/common/FormField";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "@/components/ui/dialog";
import { getErrorMessage } from "@/utils/errors";

const schema = z.object({
  email: z.string().email("Enter a valid email"),
  password: z.string().min(6, "Password is required"),
});

export default function LoginPage() {
  const [showPassword, setShowPassword] = useState(false);
  const [forgotOpen, setForgotOpen] = useState(false);
  const [forgotEmail, setForgotEmail] = useState("");
  const [forgotResult, setForgotResult] = useState(null);
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const user = useSelector((s) => s.auth.user);
  const accessToken = useSelector((s) => s.auth.accessToken);
  const { register, handleSubmit, getValues, formState: { errors } } = useForm({ resolver: zodResolver(schema) });

  const mutation = useMutation({
    mutationFn: async (payload) => {
      // Explicitly mirrors the Flutter login flow:
      // 1) ensure/generate shared API token, 2) call user login.
      await crmBootstrap.ensureApiToken();
      return authApi.login(payload);
    },
    onSuccess: async (payload) => {
      dispatch(setSession(payload));
      try {
        const menuPayload = await queryClient.fetchQuery({
          queryKey: ["menus"],
          queryFn: setupApi.menus,
        });
        dispatch(setMenus(menuPayload?.menus || []));
      } catch {
        // ProtectedRoute retries menu loading, so login itself should not fail
        // just because menu loading had a temporary network error.
      }
      navigate("/dashboard", { replace: true });
    },
  });

  const forgot = useMutation({
    mutationFn: async (email) => {
      await crmBootstrap.ensureApiToken();
      return authApi.forgotPassword(email);
    },
    onSuccess: (result) => setForgotResult(result),
  });

  if (user && accessToken) return <Navigate to="/dashboard" replace />;

  const openForgot = () => {
    setForgotEmail(getValues("email") || "");
    setForgotResult(null);
    setForgotOpen(true);
  };

  return (
    <div className="grid min-h-screen lg:grid-cols-[1.1fr_.9fr]">
      <section className="relative hidden overflow-hidden bg-brand-950 p-12 text-white lg:flex lg:flex-col lg:justify-between">
        <div className="absolute inset-0 opacity-20 [background-image:radial-gradient(circle_at_20%_20%,#3b82f6_0,transparent_28%),radial-gradient(circle_at_80%_70%,#2563eb_0,transparent_30%)]" />
        <div className="relative z-10 flex items-center gap-3"><div className="grid h-11 w-11 place-items-center rounded-2xl bg-brand-600 text-xl font-black">D</div><div><p className="text-lg font-black">DartCRM</p><p className="text-xs text-slate-400">Sales & Field Operations Platform</p></div></div>
        <div className="relative z-10 max-w-xl">
          <div className="mb-5 inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-3 py-1.5 text-xs font-semibold text-blue-200"><ShieldCheck size={15}/>Same V4 auth + hierarchy flow as mobile</div>
          <h1 className="text-5xl font-black leading-[1.08] tracking-tight">One workspace for customers, visits, sampling and approvals.</h1>
          <p className="mt-5 max-w-lg text-base leading-7 text-slate-300">The web client automatically creates the shared API token, signs in the executive, refreshes JWTs, loads role menus and reuses the same CRM V4 APIs as the Flutter app.</p>
        </div>
        <p className="relative z-10 text-xs text-slate-500">DartCRM Web · React + Vite · CRM Backend V4</p>
      </section>

      <section className="flex items-center justify-center bg-slate-50 p-5 dark:bg-slate-950 sm:p-10">
        <div className="w-full max-w-md">
          <div className="mb-8 lg:hidden"><div className="flex items-center gap-3"><div className="grid h-10 w-10 place-items-center rounded-xl bg-brand-900 font-black text-white">D</div><p className="text-lg font-black">DartCRM</p></div></div>
          <div className="rounded-3xl border border-slate-200 bg-white p-7 shadow-soft dark:border-slate-800 dark:bg-slate-900 sm:p-9">
            <h2 className="text-2xl font-black tracking-tight">Welcome back</h2>
            <p className="mt-2 text-sm text-slate-500">Sign in with your CRM executive account. API token generation is automatic.</p>
            <form className="mt-7 space-y-5" onSubmit={handleSubmit((values) => mutation.mutate(values))}>
              <FormField label="Email" required error={errors.email?.message}>
                <div className="relative"><Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={17}/><Input autoComplete="email" className="pl-10" placeholder="field@crm.local" {...register("email")}/></div>
              </FormField>
              <FormField label="Password" required error={errors.password?.message}>
                <div className="relative"><LockKeyhole className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={17}/><Input autoComplete="current-password" type={showPassword ? "text" : "password"} className="pl-10 pr-10" placeholder="••••••••" {...register("password")}/><button type="button" aria-label="Toggle password visibility" className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400" onClick={() => setShowPassword((v) => !v)}>{showPassword ? <EyeOff size={17}/> : <Eye size={17}/>}</button></div>
              </FormField>
              {mutation.isError && <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">{getErrorMessage(mutation.error)}</div>}
              <div className="flex items-center justify-between gap-3">
                <Button type="button" variant="ghost" className="px-0 text-slate-500" onClick={openForgot}><KeyRound size={15}/>Forgot password?</Button>
                <Button type="submit" variant="primary" className="min-w-32" disabled={mutation.isPending}>{mutation.isPending ? "Signing in…" : "Sign in"}</Button>
              </div>
            </form>
          </div>
        </div>
      </section>

      <Dialog open={forgotOpen} onOpenChange={setForgotOpen}>
        <DialogContent className="max-w-md">
          <DialogTitle>Forgot password</DialogTitle>
          <DialogDescription>Same password-reset request API used by the CRM backend.</DialogDescription>
          <div className="mt-4 space-y-4">
            <FormField label="Account Email" required>
              <Input type="email" value={forgotEmail} onChange={(e) => setForgotEmail(e.target.value)} placeholder="field@crm.local" />
            </FormField>
            {forgot.isError && <div className="rounded-xl bg-red-50 p-3 text-sm text-red-700 dark:bg-red-950/30 dark:text-red-300">{getErrorMessage(forgot.error)}</div>}
            {forgotResult && <div className="rounded-xl bg-emerald-50 p-3 text-sm text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-300"><p>{forgotResult.message || "Password reset request created."}</p>{forgotResult.debugResetToken && <><p className="mt-2 break-all font-mono text-xs">Development reset token: {forgotResult.debugResetToken}</p><Button type="button" variant="outline" className="mt-3 w-full" onClick={() => navigate(`/reset-password?token=${encodeURIComponent(forgotResult.debugResetToken)}`)}>Open Reset Password</Button></>}</div>}
            <Button className="w-full" variant="primary" disabled={forgot.isPending || !forgotEmail.trim()} onClick={() => forgot.mutate(forgotEmail.trim())}>{forgot.isPending ? "Requesting…" : "Request password reset"}</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
