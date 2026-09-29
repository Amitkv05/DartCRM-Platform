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
  const unread = (data?.notifications || []).filter(
    (n) => !n.is_read && !n.read_at,
  ).length;
  const logout = useMutation({
    mutationFn: () => {
      const refreshToken = tokenStorage.getRefreshToken();
      return refreshToken
        ? authApi.logout(refreshToken)
        : Promise.resolve({ status: "success" });
    },
    onSettled: () => {
      dispatch(clearSession());
      queryClient.clear();
      navigate("/login", { replace: true });
    },
  });

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-slate-200 bg-white/95 px-4 backdrop-blur dark:border-slate-800 dark:bg-slate-950/90 lg:px-6">
      <Button
        variant="ghost"
        size="icon"
        className="lg:hidden"
        onClick={() => dispatch(toggleSidebar())}
      >
        <Menu size={20} />
      </Button>
      <div className="relative hidden flex-1 sm:block sm:max-w-md">
        <Search
          className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
          size={17}
        />
        <input
          className="h-10 w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-3 text-sm outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100 dark:border-slate-800 dark:bg-slate-900"
          placeholder="Search CRM…"
          onKeyDown={(e) => {
            if (e.key === "Enter" && e.currentTarget.value.trim())
              navigate(
                `/customers/school?search=${encodeURIComponent(e.currentTarget.value.trim())}`,
              );
          }}
        />
      </div>
      <div className="ml-auto flex items-center gap-1.5">
        <Button
          variant="ghost"
          size="icon"
          onClick={() =>
            dispatch(setTheme(theme === "dark" ? "light" : "dark"))
          }
        >
          {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
        </Button>
        <Button
          variant="ghost"
          size="icon"
          className="relative"
          onClick={() => navigate("/notifications")}
        >
          <Bell size={18} />
          {unread > 0 && (
            <span className="absolute right-1 top-1 min-w-4 rounded-full bg-red-500 px-1 text-center text-[10px] font-bold leading-4 text-white">
              {Math.min(unread, 99)}
            </span>
          )}
        </Button>
        <DropdownMenu.Root>
          <DropdownMenu.Trigger asChild>
            <button className="ml-1 flex items-center gap-2 rounded-xl px-2 py-1.5 hover:bg-slate-100 dark:hover:bg-slate-800">
              <div className="grid h-9 w-9 place-items-center rounded-full bg-brand-900 text-sm font-bold text-white">
                {initials(user?.executiveName)}
              </div>
              <div className="hidden text-left md:block">
                <p className="max-w-36 truncate text-sm font-semibold">
                  {user?.executiveName}
                </p>
                <p className="text-xs text-slate-500">{user?.profileCode}</p>
              </div>
            </button>
          </DropdownMenu.Trigger>
          <DropdownMenu.Portal>
            <DropdownMenu.Content
              sideOffset={8}
              align="end"
              className="z-50 min-w-52 rounded-xl border border-slate-200 bg-white p-1.5 shadow-xl dark:border-slate-800 dark:bg-slate-900"
            >
              <DropdownMenu.Item
                className="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-sm outline-none hover:bg-slate-100 dark:hover:bg-slate-800"
                onSelect={() => navigate("/settings")}
              >
                <UserRound size={16} />
                Profile & Settings
              </DropdownMenu.Item>
              <DropdownMenu.Separator className="my-1 h-px bg-slate-100 dark:bg-slate-800" />
              <DropdownMenu.Item
                className="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-sm text-red-600 outline-none hover:bg-red-50"
                onSelect={() => logout.mutate()}
              >
                <LogOut size={16} />
                Sign out
              </DropdownMenu.Item>
            </DropdownMenu.Content>
          </DropdownMenu.Portal>
        </DropdownMenu.Root>
      </div>
    </header>
  );
}
