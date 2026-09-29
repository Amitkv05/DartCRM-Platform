import {
  LayoutDashboard,
  Building2,
  MapPin,
  ClipboardCheck,
  Package,
  Boxes,
  Bell,
  History,
  ShieldCheck,
  CalendarDays,
  Settings,
  BookOpen,
  ContactRound,
  UserCog,
  FileClock,
  LibraryBig,
  Store,
  School,
  Route,
  UserCheck,
  ClipboardList,
} from "lucide-react";

export const pathMeta = {
  "/dashboard": { label: "Dashboard", icon: LayoutDashboard },
  "/customers/school": { label: "School List", icon: School },
  "/customers/trade": { label: "Trade List", icon: Store },
  "/customers/library": { label: "Library List", icon: LibraryBig },
  "/plans/today": { label: "Today's Plan", icon: CalendarDays },
  "/plans/tomorrow": { label: "Tomorrow's Plan", icon: CalendarDays },
  "/visits/new": { label: "Visit Entry", icon: MapPin },
  "/visits/backdate-request": {
    label: "Visit Backdate Request",
    icon: FileClock,
  },
  "/sampling/school": { label: "School Sampling", icon: Package },
  "/sampling/trade": { label: "Trade Sampling", icon: Package },
  "/sampling/library": { label: "Library Sampling", icon: Package },
  "/self-stock": { label: "Self-Stock Request", icon: Boxes },
  "/approvals/customer-sampling": {
    label: "Customer Sampling Approval",
    icon: ClipboardCheck,
  },
  "/approvals/self-stock": {
    label: "Self-Stock Approval",
    icon: ClipboardCheck,
  },
  "/approvals/customer-create": {
    label: "Customer Create Approval",
    icon: UserCheck,
  },
  "/approvals/customer-update": {
    label: "Customer Update Approval",
    icon: ClipboardList,
  },
  "/approvals/customer-delete": {
    label: "Customer Delete Approval",
    icon: ClipboardCheck,
  },
  "/approvals/contact-create": {
    label: "Contact Approval",
    icon: ContactRound,
  },
  "/approvals/visit-backdate": {
    label: "Visit Backdate Approval",
    icon: FileClock,
  },
  "/requests/my-history": { label: "My Request History", icon: History },
  "/admin/users": { label: "User & Role Management", icon: UserCog },
  "/admin/request-history": {
    label: "Request & Approval History",
    icon: ShieldCheck,
  },
  "/notifications": { label: "Notifications", icon: Bell },
  "/e-products": { label: "E-Products", icon: BookOpen },
  "/attendance": { label: "Attendance", icon: Route },
  "/settings": { label: "Settings", icon: Settings },
};

export const fallbackGroups = [
  {
    name: "CRM",
    items: [
      "/dashboard",
      "/customers/school",
      "/customers/trade",
      "/customers/library",
      "/visits/new",
    ],
  },
  {
    name: "Personal",
    items: [
      "/requests/my-history",
      "/notifications",
      "/attendance",
      "/settings",
    ],
  },
];

export function iconForPath(path) {
  return pathMeta[path]?.icon || Building2;
}
