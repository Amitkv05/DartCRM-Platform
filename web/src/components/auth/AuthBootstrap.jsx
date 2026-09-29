import { useEffect, useState } from "react";
import { useDispatch } from "react-redux";
import { crmBootstrap } from "@/api/apiClient";
import { clearSession, setInitialized, updateAccessToken } from "@/features/auth/authSlice";
import { tokenStorage } from "@/utils/storage";

function Splash() {
  return (
    <div className="grid min-h-screen place-items-center bg-slate-950 text-white">
      <div className="text-center">
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-2xl bg-brand-600 text-2xl font-black shadow-lg">D</div>
        <p className="mt-4 text-lg font-black">DartCRM</p>
        <p className="mt-1 text-sm text-slate-400">Preparing secure CRM session…</p>
        <div className="mx-auto mt-5 h-1.5 w-36 overflow-hidden rounded-full bg-white/10">
          <div className="h-full w-1/2 animate-pulse rounded-full bg-brand-500" />
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
