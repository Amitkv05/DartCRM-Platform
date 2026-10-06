import { useEffect, useState } from "react";
import { useDispatch } from "react-redux";
import { crmBootstrap } from "@/api/apiClient";
import { clearSession, setInitialized, updateAccessToken } from "@/features/auth/authSlice";
import { tokenStorage } from "@/utils/storage";

function Splash() {
  return (
    <div className="crm-auth-shell relative grid min-h-screen place-items-center overflow-hidden text-white">
      <div className="crm-ambient crm-ambient-cyan" />
      <div className="crm-ambient crm-ambient-red" />
      <div className="text-center">
        <div className="crm-brand-mark mx-auto h-14 w-14 rounded-2xl text-xl">D</div>
        <p className="mt-4 text-[15px] font-black tracking-wide">DartCRM</p>
        <p className="mt-1.5 text-[9px] font-medium text-slate-600">Preparing secure CRM session…</p>
        <div className="mx-auto mt-5 h-1 w-36 overflow-hidden rounded-full bg-white/[.06]">
          <div className="h-full w-1/2 animate-pulse rounded-full bg-gradient-to-r from-brand-600 to-brand-400 shadow-[0_0_12px_rgba(255,91,80,.35)]" />
        </div>
      </div>
    </div>
  );
}

export default function AuthBootstrap({ children }) {
  const dispatch = useDispatch();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        // Same first step as the Flutter app: create/reuse the shared
        // application API token before any normal CRM API is called.
        await crmBootstrap.ensureApiToken();

        const user = tokenStorage.getUser();
        const refreshToken = tokenStorage.getRefreshToken();
        let accessToken = tokenStorage.getAccessToken();

        // A saved account without a refresh token is not a restorable session.
        if ((user && !refreshToken) || (!user && (accessToken || refreshToken))) {
          tokenStorage.clearSession();
          dispatch(clearSession());
        } else if (user && refreshToken && !accessToken) {
          accessToken = await crmBootstrap.refreshAccessToken();
          dispatch(updateAccessToken(accessToken));
        }
      } catch (error) {
        // API-token creation can be retried on the login/API request itself.
        // Only destroy the user session when its refresh failed.
        if (tokenStorage.getUser() && tokenStorage.getRefreshToken() && !tokenStorage.getAccessToken()) {
          tokenStorage.clearSession();
          dispatch(clearSession());
        }
        console.warn("DartCRM startup bootstrap:", error?.message || error);
      } finally {
        if (active) {
          dispatch(setInitialized(true));
          setReady(true);
        }
      }
    })();
    return () => { active = false; };
  }, [dispatch]);

  if (!ready) return <Splash />;
  return children;
}
