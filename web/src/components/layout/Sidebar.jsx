import { NavLink } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { closeSidebar } from "@/app/uiSlice";
import { ChevronDown, X } from "lucide-react";
import { iconForPath, pathMeta } from "@/config/navigation";
import { cn } from "@/lib/utils";
import { useMemo, useState } from "react";

function NavItem({ path, label }) {
  const Icon = iconForPath(path);
  const dispatch = useDispatch();
  return (
    <NavLink
      to={path}
      onClick={() => dispatch(closeSidebar())}
      className={({ isActive }) => cn(
        "group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition",
        isActive ? "bg-brand-800 text-white shadow-sm" : "text-slate-300 hover:bg-white/5 hover:text-white"
      )}
    >
      <Icon size={18} className="shrink-0" />
      <span className="truncate">{label}</span>
    </NavLink>
  );
}

function Group({ name, children, defaultOpen = true }) {
  const [open, setOpen] = useState(defaultOpen);
  return <div className="mb-4"><button className="mb-1 flex w-full items-center justify-between px-3 py-1 text-[11px] font-bold uppercase tracking-[.16em] text-slate-500" onClick={() => setOpen((v) => !v)}><span>{name}</span><ChevronDown size={14} className={cn("transition", open && "rotate-180")}/></button>{open && <div className="space-y-1">{children}</div>}</div>;
}

export default function Sidebar() {
  const open = useSelector((s) => s.ui.sidebarOpen);
  const menus = useSelector((s) => s.auth.menus);
  const user = useSelector((s) => s.auth.user);
  const dispatch = useDispatch();

  const groups = useMemo(() => {
    const grouped = new Map();
    for (const menu of menus || []) {
      const path = menu.route_path;
      if (!path || !pathMeta[path]) continue;
      const name = menu.menu_name || "CRM";
      if (!grouped.has(name)) grouped.set(name, []);
      grouped.get(name).push({ path, label: menu.child_menu_name || pathMeta[path].label });
    }
    const result = [...grouped.entries()].map(([name, items]) => ({ name, items }));
    if (!result.some((g) => g.items.some((i) => i.path === "/dashboard"))) {
      result.unshift({ name: "Overview", items: [{ path: "/dashboard", label: "Dashboard" }] });
    }
    const utility = [
      { path: "/notifications", label: "Notifications" },
      { path: "/attendance", label: "Attendance" },
      { path: "/e-products", label: "E-Products" },
      { path: "/settings", label: "Settings" },
    ];
    result.push({ name: "Workspace", items: utility });
    return result;
  }, [menus]);

  return (
    <>
      <div className={cn("fixed inset-0 z-40 bg-slate-950/50 lg:hidden", open ? "block" : "hidden")} onClick={() => dispatch(closeSidebar())} />
      <aside className={cn("fixed inset-y-0 left-0 z-50 flex w-72 flex-col bg-brand-950 text-white transition-transform lg:translate-x-0", open ? "translate-x-0" : "-translate-x-full")}>
        <div className="flex h-16 items-center justify-between border-b border-white/10 px-5">
          <div className="flex items-center gap-3">
            <div className="grid h-9 w-9 place-items-center rounded-xl bg-brand-600 font-black shadow-lg">D</div>
            <div><p className="text-sm font-black tracking-wide">DartCRM</p><p className="text-[11px] text-slate-400">Web Operations Suite</p></div>
          </div>
          <button className="rounded-lg p-2 hover:bg-white/10 lg:hidden" onClick={() => dispatch(closeSidebar())}><X size={18}/></button>
        </div>
        <nav className="scrollbar-thin flex-1 overflow-y-auto px-3 py-5">
          {groups.map((group) => <Group key={group.name} name={group.name}>{group.items.map((item) => <NavItem key={item.path} {...item}/>)}</Group>)}
        </nav>
        <div className="border-t border-white/10 p-4">
          <div className="rounded-xl bg-white/5 p-3">
            <p className="truncate text-sm font-semibold">{user?.executiveName || "CRM User"}</p>
            <p className="mt-1 text-xs text-slate-400">{user?.profileName || user?.profileCode || ""}{user?.approvalEnabled ? " · Approver" : ""}</p>
          </div>
        </div>
      </aside>
    </>
  );
}
