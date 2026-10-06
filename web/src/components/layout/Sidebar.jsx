import { NavLink } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { closeSidebar, toggleSidebarCollapse } from "@/app/uiSlice";
import {
  ChevronDown,
  MoreHorizontal,
  PanelLeftClose,
  PanelLeftOpen,
  ShieldCheck,
  X,
} from "lucide-react";
import { iconForPath, pathMeta } from "@/config/navigation";
import { cn } from "@/lib/utils";
import { useMemo, useState } from "react";
import { initials } from "@/utils/format";

function NavItem({ path, label, collapsed }) {
  const Icon = iconForPath(path);
  const dispatch = useDispatch();
  return (
    <NavLink
      to={path}
      title={collapsed ? label : undefined}
      onClick={() => dispatch(closeSidebar())}
      className={({ isActive }) => cn("crm-nav-item group", isActive && "active")}
    >
      <span className="crm-nav-icon"><Icon size={16} /></span>
      <span className="crm-nav-label min-w-0 flex-1 truncate">{label}</span>
      <span className="crm-nav-dot" />
    </NavLink>
  );
}

function Group({ name, children, defaultOpen = true, collapsed = false }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className="crm-nav-group mb-4" data-collapsed={collapsed ? "true" : "false"}>
      <button
        type="button"
        className="crm-nav-title"
        onClick={() => !collapsed && setOpen((v) => !v)}
        title={collapsed ? name : undefined}
        aria-expanded={collapsed ? true : open}
      >
        <span className="crm-nav-group-label">{name}</span>
        <ChevronDown
          size={12}
          className={cn("crm-nav-group-chevron transition-transform", open && "rotate-180")}
        />
      </button>
      <div
        className={cn(
          "grid overflow-hidden transition-all duration-200",
          collapsed || open ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-50",
        )}
      >
        <div className="min-h-0 space-y-1">{children}</div>
      </div>
    </div>
  );
}

export default function Sidebar() {
  const open = useSelector((s) => s.ui.sidebarOpen);
  const collapsed = useSelector((s) => s.ui.sidebarCollapsed);
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
    result.push({
      name: "Workspace",
      items: [
        { path: "/notifications", label: "Notifications" },
        { path: "/attendance", label: "Attendance" },
        { path: "/e-products", label: "E-Products" },
        { path: "/settings", label: "Settings" },
      ],
    });
    return result;
  }, [menus]);

  return (
    <>
      <button
        type="button"
        aria-label="Close navigation"
        className={cn("crm-sidebar-overlay lg:hidden", open ? "block" : "hidden")}
        onClick={() => dispatch(closeSidebar())}
      />
      <aside
        className={cn(
          "crm-sidebar",
          collapsed && "crm-sidebar-collapsed",
          open ? "translate-x-0" : "-translate-x-[125%]",
          "lg:translate-x-0",
        )}
      >
        <button
          type="button"
          className="crm-sidebar-collapse hidden lg:grid"
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          title={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          onClick={() => dispatch(toggleSidebarCollapse())}
        >
          {collapsed ? <PanelLeftOpen size={14} /> : <PanelLeftClose size={14} />}
        </button>

        <div className="crm-brand">
          <div className="crm-brand-mark">D</div>
          <div className="crm-brand-copy min-w-0">
            <p className="truncate text-[13px] font-black tracking-[.02em] text-white">DartCRM</p>
            <p className="mt-1 text-[8px] font-semibold uppercase tracking-[.16em] text-slate-600">Operations Suite</p>
          </div>
          <button
            type="button"
            className="ml-auto grid h-8 w-8 place-items-center rounded-lg text-slate-500 transition hover:bg-white/[.06] hover:text-white lg:hidden"
            onClick={() => dispatch(closeSidebar())}
          >
            <X size={16} />
          </button>
        </div>

        <div className="crm-connection-card mx-1 mb-5 flex items-center gap-2 rounded-[11px] border border-emerald-400/10 bg-emerald-400/[.045] px-3 py-2.5">
          <span className="relative flex h-2 w-2 shrink-0">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-40" />
            <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-400" />
          </span>
          <div className="crm-connection-copy min-w-0 flex-1">
            <p className="text-[9px] font-semibold text-emerald-300">CRM V4 Connected</p>
            <p className="mt-0.5 truncate text-[8px] text-slate-600">Secure workspace session</p>
          </div>
          <ShieldCheck size={14} className="crm-connection-shield shrink-0 text-emerald-400/70" />
        </div>

        <nav className="scrollbar-thin min-h-0 flex-1 overflow-y-auto pr-1">
          {groups.map((group) => (
            <Group key={group.name} name={group.name} collapsed={collapsed}>
              {group.items.map((item) => (
                <NavItem key={item.path} {...item} collapsed={collapsed} />
              ))}
            </Group>
          ))}
        </nav>

        <div className="crm-sidebar-user">
          <div className="crm-user-avatar">{initials(user?.executiveName)}</div>
          <div className="crm-user-copy min-w-0 flex-1">
            <p className="truncate text-[10px] font-bold text-slate-200">{user?.executiveName || "CRM User"}</p>
            <p className="mt-1 truncate text-[8px] uppercase tracking-[.08em] text-slate-600">
              {user?.profileName || user?.profileCode || "Executive"}{user?.approvalEnabled ? " · Approver" : ""}
            </p>
          </div>
          <MoreHorizontal size={15} className="crm-user-more text-slate-600" />
        </div>
      </aside>
    </>
  );
}
