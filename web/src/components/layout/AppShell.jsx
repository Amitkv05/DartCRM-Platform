import { Outlet, useLocation } from "react-router-dom";
import { useSelector } from "react-redux";
import Sidebar from "@/components/layout/Sidebar";
import Topbar from "@/components/layout/Topbar";
import { cn } from "@/lib/utils";

export default function AppShell() {
  const location = useLocation();
  const sidebarCollapsed = useSelector((s) => s.ui.sidebarCollapsed);

  return (
    <div className="crm-shell min-h-screen">
      <div className="crm-ambient crm-ambient-cyan" />
      <div className="crm-ambient crm-ambient-red" />
      <Sidebar />
      <div className={cn("crm-main", sidebarCollapsed && "crm-main-collapsed")}>
        <Topbar />
        <main className="crm-content min-h-screen px-3 pb-8 pt-3 sm:px-5 lg:px-6 lg:pb-10 lg:pt-4">
          <div className="mx-auto max-w-[1680px]">
            <div key={location.pathname} className="crm-page-enter">
              <Outlet />
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
