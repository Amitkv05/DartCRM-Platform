import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useDispatch, useSelector } from "react-redux";
import { Navigate, useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Activity, Eye, EyeOff, KeyRound, LockKeyhole, Mail, ShieldCheck, Sparkles } from "lucide-react";
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
      await crmBootstrap.ensureApiToken();
      return authApi.login(payload);
    },
    onSuccess: async (payload) => {
      dispatch(setSession(payload));
      try {
        const menuPayload = await queryClient.fetchQuery({ queryKey: ["menus"], queryFn: setupApi.menus });
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
    <div className="crm-auth-shell relative grid min-h-screen overflow-hidden lg:grid-cols-[1.08fr_.92fr]">
      <div className="crm-ambient crm-ambient-cyan" />
      <div className="crm-ambient crm-ambient-red" />
      <div className="crm-auth-orbit -left-40 -top-44 h-[520px] w-[520px]" />
      <div className="crm-auth-orbit -bottom-64 left-[30%] h-[620px] w-[620px]" />

      <section className="relative hidden min-h-screen overflow-hidden p-12 text-white lg:flex lg:flex-col lg:justify-between xl:p-16">
        <div className="flex items-center gap-3">
          <div className="crm-brand-mark h-11 w-11 rounded-xl text-base">D</div>
          <div><p className="text-[15px] font-black tracking-wide">DartCRM</p><p className="mt-1 text-[8px] font-semibold uppercase tracking-[.18em] text-slate-600">Sales & Field Operations</p></div>
        </div>

        <div className="relative z-10 max-w-[650px] pb-6">
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-emerald-400/10 bg-emerald-400/[.055] px-3 py-1.5 text-[9px] font-semibold text-emerald-300">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-400" /> CRM V4 secure session
          </div>
          <h1 className="max-w-[610px] text-[44px] font-black leading-[1.06] tracking-[-.055em] xl:text-[54px]">One operational command center for your complete field workflow.</h1>
          <p className="mt-6 max-w-[560px] text-[12px] leading-6 text-slate-500">Customers, plans, visits, sampling, approvals and activity stay connected through the same existing DartCRM APIs—now inside a focused dashboard experience.</p>

          <div className="mt-9 grid max-w-[590px] grid-cols-3 gap-3">
            {[
              [ShieldCheck, "Protected", "JWT + API token"],
              [Activity, "Live", "CRM operations"],
              [Sparkles, "Unified", "Role-aware workspace"],
            ].map(([Icon, title, sub]) => (
              <div key={title} className="rounded-[14px] border border-white/[.07] bg-white/[.025] p-4 backdrop-blur-lg">
                <Icon size={16} className="text-brand-400" />
                <p className="mt-4 text-[10px] font-bold text-slate-200">{title}</p>
                <p className="mt-1 text-[8px] text-slate-600">{sub}</p>
              </div>
            ))}
          </div>
        </div>
        <p className="text-[8px] font-semibold uppercase tracking-[.18em] text-slate-700">DartCRM Web · Operations Suite</p>
      </section>

      <section className="relative flex items-center justify-center p-5 sm:p-10 lg:border-l lg:border-white/[.045]">
        <div className="w-full max-w-[440px]">
          <div className="mb-7 flex items-center gap-3 lg:hidden"><div className="crm-brand-mark h-10 w-10">D</div><div><p className="text-[14px] font-black text-white">DartCRM</p><p className="text-[8px] uppercase tracking-[.15em] text-slate-600">Operations Suite</p></div></div>
          <div className="crm-auth-panel rounded-[22px] p-6 sm:p-8">
            <div className="mb-7">
              <div className="mb-4 grid h-10 w-10 place-items-center rounded-[11px] border border-brand-400/15 bg-brand-400/[.08] text-brand-300"><LockKeyhole size={18}/></div>
              <p className="text-[8px] font-bold uppercase tracking-[.18em] text-slate-600">Secure Access</p>
              <h2 className="mt-2 text-[26px] font-black tracking-[-.04em] text-white">Welcome back</h2>
              <p className="mt-2 text-[10px] leading-5 text-slate-500">Sign in with your CRM executive account. Existing authentication and API flows remain unchanged.</p>
            </div>

            <form className="space-y-5" onSubmit={handleSubmit((values) => mutation.mutate(values))}>
              <FormField label="Email" required error={errors.email?.message}>
                <div className="relative"><Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-600" size={15}/><Input autoComplete="email" className="pl-10" placeholder="field@crm.local" {...register("email")}/></div>
              </FormField>
              <FormField label="Password" required error={errors.password?.message}>
                <div className="relative"><LockKeyhole className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-600" size={15}/><Input autoComplete="current-password" type={showPassword ? "text" : "password"} className="pl-10 pr-10" placeholder="••••••••" {...register("password")}/><button type="button" aria-label="Toggle password visibility" className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-600 transition hover:text-slate-300" onClick={() => setShowPassword((v) => !v)}>{showPassword ? <EyeOff size={16}/> : <Eye size={16}/>}</button></div>
              </FormField>
              {mutation.isError && <div className="rounded-xl border border-red-400/15 bg-red-400/[.07] px-4 py-3 text-[10px] leading-5 text-red-300">{getErrorMessage(mutation.error)}</div>}
              <div className="flex flex-col-reverse gap-2 pt-1 sm:flex-row sm:items-center sm:justify-between">
                <Button type="button" variant="ghost" className="justify-start px-1 text-slate-500" onClick={openForgot}><KeyRound size={14}/>Forgot password?</Button>
                <Button type="submit" variant="primary" className="min-w-32" disabled={mutation.isPending}>{mutation.isPending ? "Signing in…" : "Sign in"}</Button>
              </div>
            </form>
          </div>
          <p className="mt-4 text-center text-[8px] text-slate-700">Protected access · Role based menus · Automatic token refresh</p>
        </div>
      </section>

      <Dialog open={forgotOpen} onOpenChange={setForgotOpen}>
        <DialogContent className="max-w-md">
          <DialogTitle>Forgot password</DialogTitle>
          <DialogDescription>Use the existing CRM password-reset request API.</DialogDescription>
          <div className="mt-5 space-y-4">
            <FormField label="Account Email" required><Input type="email" value={forgotEmail} onChange={(e) => setForgotEmail(e.target.value)} placeholder="field@crm.local" /></FormField>
            {forgot.isError && <div className="rounded-xl border border-red-400/15 bg-red-400/[.06] p-3 text-[10px] text-red-300">{getErrorMessage(forgot.error)}</div>}
            {forgotResult && <div className="rounded-xl border border-emerald-400/15 bg-emerald-400/[.06] p-3 text-[10px] leading-5 text-emerald-300"><p>{forgotResult.message || "Password reset request created."}</p>{forgotResult.debugResetToken && <><p className="mt-2 break-all font-mono text-[9px]">Development reset token: {forgotResult.debugResetToken}</p><Button type="button" variant="outline" className="mt-3 w-full" onClick={() => navigate(`/reset-password?token=${encodeURIComponent(forgotResult.debugResetToken)}`)}>Open Reset Password</Button></>}</div>}
            <Button className="w-full" variant="primary" disabled={forgot.isPending || !forgotEmail.trim()} onClick={() => forgot.mutate(forgotEmail.trim())}>{forgot.isPending ? "Requesting…" : "Request password reset"}</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
