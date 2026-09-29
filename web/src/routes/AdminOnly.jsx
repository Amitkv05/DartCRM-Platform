import { Navigate, Outlet } from "react-router-dom";
import { useSelector } from "react-redux";

export default function AdminOnly() {
  const user = useSelector((s) => s.auth.user);
  if (!user?.isAdmin) return <Navigate to="/dashboard" replace />;
  return <Outlet/>;
}
