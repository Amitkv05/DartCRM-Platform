import { Outlet } from "react-router-dom";
import Sidebar from "@/components/layout/Sidebar";
import Topbar from "@/components/layout/Topbar";

export default function AppShell() {
  return <div className="min-h-screen bg-slate-50 dark:bg-slate-950"><Sidebar/><div className="lg:pl-72"><Topbar/><main className="app-grid-bg min-h-[calc(100vh-4rem)] p-4 sm:p-6 lg:p-8"><div className="mx-auto max-w-[1600px]"><Outlet/></div></main></div></div>;
}
