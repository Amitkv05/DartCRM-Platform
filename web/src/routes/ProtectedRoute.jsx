import { useEffect } from "react";
import { Navigate, Outlet } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { useQuery } from "@tanstack/react-query";
import { executiveApi, setupApi } from "@/api/crmApi";
import { clearSession, setMenus, updateContext } from "@/features/auth/authSlice";
import LoadingState from "@/components/common/LoadingState";

export default function ProtectedRoute() {
  const dispatch = useDispatch();
  const initialized = useSelector((s) => s.auth.initialized);
  const user = useSelector((s) => s.auth.user);
  const accessToken = useSelector((s) => s.auth.accessToken);
  const enabled = Boolean(initialized && user && accessToken);

  const menuQ = useQuery({
    queryKey: ["menus"],
    queryFn: setupApi.menus,
    enabled,
    staleTime: 5 * 60_000,
    retry: 1,
  });
  const setupQ = useQuery({
    queryKey: ["application-setup"],
    queryFn: () => setupApi.setup(),
    enabled,
    staleTime: 5 * 60_000,
    retry: 1,
  });
  const hierarchyQ = useQuery({
    queryKey: ["my-hierarchy"],
    queryFn: executiveApi.myHierarchy,
    enabled,
    staleTime: 5 * 60_000,
    retry: 1,
  });

  useEffect(() => {
    if (menuQ.data?.menus) dispatch(setMenus(menuQ.data.menus));
  }, [menuQ.data, dispatch]);

  useEffect(() => {
    if (setupQ.data?.setup) dispatch(updateContext({ applicationSetup: setupQ.data.setup }));
  }, [setupQ.data, dispatch]);

  useEffect(() => {
    if (hierarchyQ.data) {
      dispatch(updateContext({
        upHierarchy: hierarchyQ.data.upHierarchy || [],
        downHierarchy: hierarchyQ.data.downHierarchy || [],
      }));
    }
  }, [hierarchyQ.data, dispatch]);

  useEffect(() => {
    const onExpired = () => dispatch(clearSession());
    window.addEventListener("dartcrm:session-expired", onExpired);
    return () => window.removeEventListener("dartcrm:session-expired", onExpired);
  }, [dispatch]);

  if (!initialized) {
    return <div className="grid min-h-screen place-items-center bg-slate-50 dark:bg-slate-950"><LoadingState label="Restoring your CRM session…"/></div>;
  }
  if (!user || !accessToken) return <Navigate to="/login" replace />;
  if (menuQ.isLoading || setupQ.isLoading || hierarchyQ.isLoading) {
    return <div className="grid min-h-screen place-items-center bg-slate-50 dark:bg-slate-950"><LoadingState label="Loading role, setup and hierarchy…"/></div>;
  }
  return <Outlet />;
}
