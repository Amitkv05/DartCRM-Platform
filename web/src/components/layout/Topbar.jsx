import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Bell, LogOut, Menu, Moon, Search, Sun, UserRound } from "lucide-react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { toggleSidebar, setTheme } from "@/app/uiSlice";
import { clearSession } from "@/features/auth/authSlice";
import { authApi, notificationApi } from "@/api/crmApi";
import { initials } from "@/utils/format";
import { tokenStorage } from "@/utils/storage";
import { Button } from "@/components/ui/button";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";

export default function Topbar() {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const user = useSelector((s) => s.auth.user);
  const theme = useSelector((s) => s.ui.theme);
  const { data } = useQuery({
    queryKey: ["notifications"],
    queryFn: notificationApi.list,
    refetchInterval: 60_000,
  });
  const unread = (data?.notifications || []).filter((n) => !n.is_read && !n.read_at).length;
  const logout = useMutation({
    mutationFn: () => {
      const refreshToken = tokenStorage.getRefreshToken();
      return refreshToken ? authApi.logout(refreshToken) : Promise.resolve({ status: "success" });
    },
    onSettled: () => {
      dispatch(clearSession());
      queryClient.clear();
      navigate("/login", { replace: true });
    },
  });

  return (
    <header className="crm-topbar sticky top-3 z-30 mx-3 mt-3 flex min-h-[58px] items-center gap-2 px-2.5 py-2 sm:mx-5 lg:mx-6 lg:mt-4">
      <Button variant="ghost" size="icon" className="shrink-0 lg:hidden" onClick={() => dispatch(toggleSidebar())}>
        <Menu size={18} />
      </Button>

      <div className="crm-search relative min-w-0 flex-1 sm:max-w-xl">
        <Search className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-600" size={15} />
        <input
          className="h-10 w-full rounded-[10px] border border-transparent bg-transparent pl-9 pr-3 text-[11px] text-slate-200 outline-none transition placeholder:text-slate-600 hover:bg-white/[.02] focus:border-white/[.06] focus:bg-white/[.035]"
          placeholder="Search CRM records…"
          onKeyDown={(e) => {
            if (e.key === "Enter" && e.currentTarget.value.trim()) {
              navigate(`/customers/school?search=${encodeURIComponent(e.currentTarget.value.trim())}`);
            }
          }}
        />
      </div>

      <div className="hidden items-center gap-1 rounded-[9px] border border-white/[.055] bg-white/[.018] p-1 md:flex">
        <span className="rounded-md bg-white/[.055] px-2.5 py-1.5 text-[8px] font-semibold uppercase tracking-[.08em] text-slate-300">Live</span>
        <span className="px-2 text-[8px] font-medium text-slate-600">Operations</span>
      </div>

      <div className="ml-auto flex items-center gap-1">
        <Button
          variant="ghost"
          size="icon"
          className="h-9 w-9"
          aria-label="Toggle theme"
          onClick={() => dispatch(setTheme(theme === "dark" ? "light" : "dark"))}
        >
          {theme === "dark" ? <Sun size={16} /> : <Moon size={16} />}
        </Button>
        <Button variant="ghost" size="icon" className="relative h-9 w-9" onClick={() => navigate("/notifications")}>
          <Bell size={16} />
          {unread > 0 && <span className="crm-notification-dot">{Math.min(unread, 99)}</span>}
        </Button>

        <DropdownMenu.Root>
          <DropdownMenu.Trigger asChild>
            <button className="ml-1 flex items-center gap-2 rounded-[10px] border border-transparent px-1.5 py-1 transition hover:border-white/[.06] hover:bg-white/[.035]">
              <div className="crm-user-avatar h-8 w-8 rounded-lg text-[10px]">{initials(user?.executiveName)}</div>
              <div className="hidden max-w-36 text-left md:block">
                <p className="truncate text-[10px] font-bold text-slate-200">{user?.executiveName}</p>
                <p className="mt-0.5 text-[8px] uppercase tracking-[.08em] text-slate-600">{user?.profileCode}</p>
              </div>
            </button>
          </DropdownMenu.Trigger>
          <DropdownMenu.Portal>
            <DropdownMenu.Content
              sideOffset={9}
              align="end"
              className="z-50 min-w-52 rounded-[12px] border border-white/[.09] bg-[#111519]/95 p-1.5 text-slate-300 shadow-2xl backdrop-blur-xl"
            >
              <DropdownMenu.Item
                className="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-[11px] outline-none transition hover:bg-white/[.055] hover:text-white"
                onSelect={() => navigate("/settings")}
              >
                <UserRound size={15} />
                Profile & Settings
              </DropdownMenu.Item>
              <DropdownMenu.Separator className="my-1 h-px bg-white/[.06]" />
              <DropdownMenu.Item
                className="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-[11px] text-red-300 outline-none transition hover:bg-red-500/10"
                onSelect={() => logout.mutate()}
              >
                <LogOut size={15} />
                Sign out
              </DropdownMenu.Item>
            </DropdownMenu.Content>
          </DropdownMenu.Portal>
        </DropdownMenu.Root>
      </div>
    </header>
  );
}
