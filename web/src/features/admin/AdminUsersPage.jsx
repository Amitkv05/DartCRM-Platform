import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Edit3, Plus, Power, RotateCcw, Search } from "lucide-react";
import { toast } from "sonner";
import { adminApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import DataTable from "@/components/common/DataTable";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import StatusBadge from "@/components/common/StatusBadge";
import ConfirmDialog from "@/components/common/ConfirmDialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogTitle,
} from "@/components/ui/dialog";
import { getErrorMessage } from "@/utils/errors";

const emptyForm = {
  loginEmail: "",
  password: "",
  executiveCode: "",
  executiveName: "",
  email: "",
  mobile: "",
  designation: "",
  departmentId: "",
  profileId: "",
  managerExecutiveId: "",
  approvalEnabled: false,
  menuAccessMode: "PROFILE",
  cityIds: [],
  territoryIds: [],
  productDivisionIds: [],
  menuIds: [],
};
const toggleId = (values, id) =>
  values.includes(Number(id))
    ? values.filter((x) => x !== Number(id))
    : [...values, Number(id)];

function AccessChecks({ label, options, values, onChange, nameKey = "name" }) {
  return (
    <div>
      <p className="mb-2 text-sm font-semibold">{label}</p>
      <div className="max-h-36 overflow-y-auto rounded-xl border border-slate-200 p-2 dark:border-slate-700">
        <div className="grid gap-1 sm:grid-cols-2">
          {options.length ? (
            options.map((o) => (
              <label
                key={o.id}
                className="flex cursor-pointer items-center gap-2 rounded-lg px-2 py-1.5 text-sm hover:bg-slate-50 dark:hover:bg-slate-800"
              >
                <Checkbox
                  checked={values.includes(Number(o.id))}
                  onChange={() => onChange(toggleId(values, o.id))}
                />
                <span className="truncate">{o[nameKey] || o.code}</span>
              </label>
            ))
          ) : (
            <p className="p-2 text-xs text-slate-500">No options</p>
          )}
        </div>
      </div>
    </div>
  );
}

function UserDialog({ open, onOpenChange, editingId, meta, onSaved }) {
  const [form, setForm] = useState(emptyForm);
  const detailQ = useQuery({
    queryKey: ["admin-user", editingId],
    queryFn: () => adminApi.user(editingId),
    enabled: Boolean(open && editingId),
  });
  useEffect(() => {
    if (!open) return;
    if (!editingId) setForm(emptyForm);
  }, [open, editingId]);
  useEffect(() => {
    const e = detailQ.data?.executive;
    if (!e) return;
    setForm({
      loginEmail: e.login_email || "",
      password: "",
      executiveCode: e.executive_code || "",
      executiveName: e.executive_name || "",
      email: e.email || "",
      mobile: e.mobile || "",
      designation: e.designation || "",
      departmentId: e.department_id || "",
      profileId: e.profile_id || "",
      managerExecutiveId: e.manager_executive_id || "",
      approvalEnabled: Boolean(Number(e.approval_enabled)),
      menuAccessMode: e.menu_access_mode || "PROFILE",
      cityIds: (e.cityIds || []).map(Number),
      territoryIds: (e.territoryIds || []).map(Number),
      productDivisionIds: (e.productDivisionIds || []).map(Number),
      menuIds: (e.customMenuIds || []).map(Number),
    });
  }, [detailQ.data]);
  const save = useMutation({
    mutationFn: () => {
      const payload = {
        ...form,
        profileId: Number(form.profileId),
        departmentId: form.departmentId ? Number(form.departmentId) : null,
        managerExecutiveId: form.managerExecutiveId
          ? Number(form.managerExecutiveId)
          : null,
        password: form.password || undefined,
      };
      if (form.menuAccessMode !== "CUSTOM") payload.menuIds = [];
      return editingId
        ? adminApi.updateUser(editingId, payload)
        : adminApi.createUser(payload);
    },
    onSuccess: (r) => {
      toast.success(r.message || "Account saved");
      onSaved();
      onOpenChange(false);
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });
  const selectedProfile = (meta.profiles || []).find(
    (p) => Number(p.id) === Number(form.profileId),
  );
  const managers = (meta.managers || []).filter(
    (m) =>
      Number(m.id) !== Number(editingId) &&
      (Number(m.is_admin) === 1 ||
        !selectedProfile ||
        Number(m.level_rank) > Number(selectedProfile.level_rank)),
  );
  const submit = () => {
    if (
      !form.loginEmail ||
      !form.executiveCode ||
      !form.executiveName ||
      !form.profileId
    )
      return toast.error(
        "Login email, executive code, name and profile are required",
      );
    if (!editingId && form.password.length < 8)
      return toast.error("Password must contain at least 8 characters");
    save.mutate();
  };
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-5xl">
        <DialogTitle>
          {editingId ? "Edit User & Role" : "Create User & Executive"}
        </DialogTitle>
        <DialogDescription>
          Admin controls login, hierarchy, approval permission, geography,
          divisions and menu access here.
        </DialogDescription>
        {detailQ.isLoading ? (
          <LoadingState />
        ) : (
          <div className="mt-5 space-y-5">
            <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
              {[
                ["Login Email", "loginEmail", "email", "name@example.com"],
                ["Executive Code", "executiveCode", "text", "EXE-L2-02"],
                ["Executive Name", "executiveName", "text", "Executive name"],
                ["Email", "email", "email", "Work email"],
                ["Mobile", "mobile", "text", "Mobile"],
                ["Designation", "designation", "text", "Area Manager"],
              ].map(([label, key, type, ph]) => (
                <div key={key}>
                  <p className="mb-1.5 text-sm font-semibold">{label}</p>
                  <Input
                    type={type}
                    placeholder={ph}
                    value={form[key]}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, [key]: e.target.value }))
                    }
                  />
                </div>
              ))}
              <div>
                <p className="mb-1.5 text-sm font-semibold">
                  {editingId ? "Reset Password (optional)" : "Password"}
                </p>
                <Input
                  type="password"
                  placeholder={
                    editingId
                      ? "Leave blank to keep current"
                      : "Minimum 8 characters"
                  }
                  value={form.password}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, password: e.target.value }))
                  }
                />
              </div>
              <div>
                <p className="mb-1.5 text-sm font-semibold">Department</p>
                <Select
                  value={form.departmentId}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, departmentId: e.target.value }))
                  }
                >
                  <option value="">No department</option>
                  {(meta.departments || []).map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.name}
                    </option>
                  ))}
                </Select>
              </div>
              <div>
                <p className="mb-1.5 text-sm font-semibold">Level / Profile</p>
                <Select
                  value={form.profileId}
                  onChange={(e) =>
                    setForm((f) => ({
                      ...f,
                      profileId: e.target.value,
                      managerExecutiveId: "",
                      approvalEnabled:
                        Number(
                          (meta.profiles || []).find(
                            (p) => Number(p.id) === Number(e.target.value),
                          )?.level_rank,
                        ) > 1
                          ? f.approvalEnabled
                          : false,
                    }))
                  }
                >
                  <option value="">Select profile</option>
                  {(meta.profiles || []).map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.code} · {p.name}
                      {p.is_admin ? " (Admin)" : ""}
                    </option>
                  ))}
                </Select>
              </div>
              <div>
                <p className="mb-1.5 text-sm font-semibold">
                  Reporting Manager
                </p>
                <Select
                  value={form.managerExecutiveId}
                  disabled={Boolean(selectedProfile?.is_admin)}
                  onChange={(e) =>
                    setForm((f) => ({
                      ...f,
                      managerExecutiveId: e.target.value,
                    }))
                  }
                >
                  <option value="">
                    {selectedProfile?.is_admin
                      ? "Admin has no manager"
                      : "Select manager"}
                  </option>
                  {managers.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.executive_name} · {m.profile_code}
                    </option>
                  ))}
                </Select>
              </div>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <label className="flex items-center gap-3 rounded-xl border border-slate-200 p-4 dark:border-slate-700">
                <Checkbox
                  checked={form.approvalEnabled}
                  disabled={
                    selectedProfile &&
                    Number(selectedProfile.level_rank) <= 1 &&
                    !selectedProfile.is_admin
                  }
                  onChange={(e) =>
                    setForm((f) => ({
                      ...f,
                      approvalEnabled: e.target.checked,
                    }))
                  }
                />
                <div>
                  <p className="font-semibold">Can Approve Requests</p>
                  <p className="text-xs text-slate-500">
                    L1 remains request-only. Disabled approvers are skipped
                    automatically.
                  </p>
                </div>
              </label>
              <div className="rounded-xl border border-slate-200 p-4 dark:border-slate-700">
                <p className="mb-2 font-semibold">Menu Access</p>
                <Select
                  value={form.menuAccessMode}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, menuAccessMode: e.target.value }))
                  }
                >
                  <option value="PROFILE">Use Profile Default</option>
                  <option value="CUSTOM">Custom Menu Access</option>
                </Select>
              </div>
            </div>
            <div className="grid gap-4 lg:grid-cols-3">
              <AccessChecks
                label="City Access"
                options={meta.cities || []}
                values={form.cityIds}
                onChange={(v) => setForm((f) => ({ ...f, cityIds: v }))}
              />
              <AccessChecks
                label="Territory Access"
                options={meta.territories || []}
                values={form.territoryIds}
                onChange={(v) => setForm((f) => ({ ...f, territoryIds: v }))}
              />
              <AccessChecks
                label="Product Divisions"
                options={meta.productDivisions || []}
                values={form.productDivisionIds}
                onChange={(v) =>
                  setForm((f) => ({ ...f, productDivisionIds: v }))
                }
              />
            </div>
            {form.menuAccessMode === "CUSTOM" && (
              <AccessChecks
                label="Custom Menus"
                options={(meta.menus || []).map((m) => ({
                  ...m,
                  name: `${m.menu_name} · ${m.child_menu_name}`,
                }))}
                values={form.menuIds}
                onChange={(v) => setForm((f) => ({ ...f, menuIds: v }))}
              />
            )}
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => onOpenChange(false)}>
                Cancel
              </Button>
              <Button
                variant="primary"
                disabled={save.isPending}
                onClick={submit}
              >
                {save.isPending ? "Saving…" : "Save Account"}
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}

export default function AdminUsersPage() {
  const qc = useQueryClient();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [dialog, setDialog] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [deactivate, setDeactivate] = useState(null);
  const metaQ = useQuery({
    queryKey: ["admin-role-meta"],
    queryFn: adminApi.roleMeta,
  });
  const usersQ = useQuery({
    queryKey: ["admin-users", status, search],
    queryFn: () =>
      adminApi.users({
        status: status || undefined,
        search: search || undefined,
      }),
  });
  const deactivateM = useMutation({
    mutationFn: adminApi.deactivateUser,
    onSuccess: (r) => {
      toast.success(r.message);
      setDeactivate(null);
      qc.invalidateQueries({ queryKey: ["admin-users"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });
  const reactivateM = useMutation({
    mutationFn: adminApi.reactivateUser,
    onSuccess: (r) => {
      toast.success(r.message);
      qc.invalidateQueries({ queryKey: ["admin-users"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });
  const columns = useMemo(
    () => [
      {
        accessorKey: "executive_code",
        header: "Executive",
        cell: ({ row }) => (
          <div>
            <p className="font-semibold">{row.original.executive_name}</p>
            <p className="font-mono text-xs text-slate-500">
              {row.original.executive_code}
            </p>
          </div>
        ),
      },
      {
        accessorKey: "profile_code",
        header: "Role / Level",
        cell: ({ row }) => (
          <div className="flex gap-2">
            <Badge tone={row.original.is_admin ? "purple" : "blue"}>
              {row.original.profile_code}
            </Badge>
            <span className="text-xs text-slate-500">
              L{row.original.level_rank}
            </span>
          </div>
        ),
      },
      {
        accessorKey: "manager_name",
        header: "Manager",
        cell: ({ getValue }) => getValue() || "—",
      },
      {
        accessorKey: "approval_enabled",
        header: "Approval",
        cell: ({ getValue }) => (
          <Badge tone={Number(getValue()) ? "green" : "slate"}>
            {Number(getValue()) ? "Yes" : "No"}
          </Badge>
        ),
      },
      {
        accessorKey: "pending_approvals",
        header: "Pending",
        cell: ({ getValue }) => (
          <Badge tone={Number(getValue()) ? "amber" : "slate"}>
            {getValue() || 0}
          </Badge>
        ),
      },
      {
        accessorKey: "status",
        header: "Status",
        cell: ({ getValue }) => <StatusBadge status={getValue()} />,
      },
      {
        id: "actions",
        header: "",
        cell: ({ row }) => (
          <div className="flex justify-end gap-1">
            <Button
              size="icon"
              variant="ghost"
              onClick={() => {
                setEditingId(row.original.executive_id);
                setDialog(true);
              }}
              title="Edit"
            >
              <Edit3 size={16} />
            </Button>
            {row.original.status === "ACTIVE" ? (
              <Button
                size="icon"
                variant="ghost"
                className="text-red-600"
                title="Deactivate"
                onClick={() => setDeactivate(row.original)}
              >
                <Power size={16} />
              </Button>
            ) : (
              <Button
                size="icon"
                variant="ghost"
                className="text-emerald-600"
                title="Reactivate"
                onClick={() => reactivateM.mutate(row.original.executive_id)}
              >
                <RotateCcw size={16} />
              </Button>
            )}
          </div>
        ),
      },
    ],
    [reactivateM],
  );
  if (metaQ.isLoading) return <LoadingState />;
  if (metaQ.isError) return <ErrorState error={metaQ.error} />;
  return (
    <>
      <PageHeader
        title="User & Role Management"
        description="Admin-only control centre for accounts, hierarchy, approval rights and access."
        actions={
          <Button
            variant="primary"
            onClick={() => {
              setEditingId(null);
              setDialog(true);
            }}
          >
            <Plus size={16} />
            Add Account
          </Button>
        }
      />
      <div className="mb-4 flex flex-wrap gap-2">
        <div className="relative min-w-64 max-w-md flex-1">
          <Search
            size={16}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
          />
          <Input
            className="pl-9"
            placeholder="Search name, code or login…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <Select
          className="w-40"
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          <option value="">All statuses</option>
          <option value="ACTIVE">Active</option>
          <option value="INACTIVE">Inactive</option>
        </Select>
      </div>
      {usersQ.isLoading ? (
        <LoadingState />
      ) : usersQ.isError ? (
        <ErrorState error={usersQ.error} />
      ) : (
        <DataTable columns={columns} data={usersQ.data?.executives || []} />
      )}
      <UserDialog
        open={dialog}
        onOpenChange={setDialog}
        editingId={editingId}
        meta={metaQ.data || {}}
        onSaved={() => {
          qc.invalidateQueries({ queryKey: ["admin-users"] });
          qc.invalidateQueries({ queryKey: ["menus"] });
        }}
      />
      <ConfirmDialog
        open={Boolean(deactivate)}
        onOpenChange={(v) => !v && setDeactivate(null)}
        title="Deactivate account?"
        description={`This disables ${deactivate?.executive_name || "the account"}. Any assigned pending approvals will be reassigned upward.`}
        confirmLabel="Deactivate"
        destructive
        onConfirm={() => deactivateM.mutate(deactivate.executive_id)}
      />
    </>
  );
}
