import { useMemo } from "react";
import { useQueries, useQuery } from "@tanstack/react-query";
import { Link, useNavigate } from "react-router-dom";
import { ChevronRight, MapPin } from "lucide-react";
import { customerApi, planApi, setupApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import {
  WorkflowSection,
  EmptyMessage,
} from "@/components/parity/WorkflowSection";
import { Button } from "@/components/ui/button";
import { planRow } from "@/utils/parity";

export default function PlansPage({ day = "today" }) {
  const nav = useNavigate();
  const planQ = useQuery({
    queryKey: ["plans", "flutter-parity"],
    queryFn: () => planApi.list({}),
  });
  const geoQ = useQuery({
    queryKey: ["geography", "plan-list"],
    queryFn: () => setupApi.geography(),
  });
  const baseRows = useMemo(() => {
    const raw =
      day === "tomorrow"
        ? planQ.data?.tomorrowPlan || []
        : planQ.data?.todayPlan || [];
    return raw.map(planRow);
  }, [planQ.data, day]);
  const detailsQ = useQueries({
    queries: baseRows.map((p) => ({
      queryKey: ["customer", p.customerId, "plan-list"],
      queryFn: () => customerApi.get(p.customerId),
      enabled: Boolean(p.customerId),
      staleTime: 60_000,
    })),
  });
  const rows = useMemo(() => {
    const cityMap = new Map(
      (geoQ.data?.geography || []).map((g) => [Number(g.city_id), g]),
    );
    return baseRows.map((p, i) => {
      const c = detailsQ[i]?.data?.customer || {};
      const contacts = detailsQ[i]?.data?.contacts || [];
      const primary =
        contacts.find((x) => Number(x.primary_contact) === 1) || contacts[0];
      const geo = cityMap.get(Number(c.city_id));
      return {
        ...p,
        refCode: p.refCode || c.ref_code || "",
        address: p.address || c.address || "",
        city: p.city || c.city || geo?.city || "",
        state: p.state || geo?.state || "",
        email: p.email || primary?.email || c.email || "",
        mobile: p.mobile || primary?.mobile || c.mobile || "",
        contact:
          p.contact ||
          [primary?.first_name, primary?.last_name].filter(Boolean).join(" "),
      };
    });
  }, [baseRows, detailsQ, geoQ.data]);
  if (planQ.isLoading || geoQ.isLoading) return <LoadingState />;
  if (planQ.isError) return <ErrorState error={planQ.error} />;
  const title = day === "tomorrow" ? "Tomorrow's Plan" : "Today's Plan";
  return (
    <>
      <PageHeader
        title="Travel Plan"
        description="View Today's Plan and Tomorrow's Plan with the same customer-first flow as the Flutter app."
      />
      <div className="mb-4 flex gap-2 rounded-xl border border-white/[.07] bg-white/[.018] p-2 backdrop-blur-xl">
        <Button asChild variant={day === "today" ? "primary" : "ghost"}>
          <Link to="/plans/today">Today's Plan</Link>
        </Button>
        <Button asChild variant={day === "tomorrow" ? "primary" : "ghost"}>
          <Link to="/plans/tomorrow">Tomorrow's Plan</Link>
        </Button>
      </div>
      <WorkflowSection title={title}>
        {!rows.length ? (
          <EmptyMessage>No plans available</EmptyMessage>
        ) : (
          <div className="space-y-3">
            {rows.map((p, index) => (
              <button
                type="button"
                key={`${p.id}-${p.customerId}-${index}`}
                onClick={() =>
                  nav(`/plans/${day}/customer/${p.customerId}`, {
                    state: { plan: p.raw },
                  })
                }
                className="flex w-full items-start justify-between gap-4 rounded-xl border border-white/[.07] bg-white/[.022] p-4 text-left transition-all hover:-translate-y-0.5 hover:border-white/[.13] hover:bg-white/[.04]"
              >
                <div className="min-w-0 flex-1">
                  <h3 className="text-base font-bold text-violet-800 dark:text-violet-300">
                    {p.customerName} <span>({p.customerCode})</span>
                  </h3>
                  <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">
                    {p.address || "No address"}
                  </p>
                  <p className="mt-1 flex items-center gap-1 text-sm text-slate-600 dark:text-slate-400">
                    <MapPin size={14} />
                    {[p.city, p.state].filter(Boolean).join(", ") || "—"}
                  </p>
                  <div className="mt-2 grid gap-1 text-sm sm:grid-cols-2">
                    <p>
                      <b>Mail:</b>{" "}
                      <span className="text-slate-500">{p.email || "—"}</span>
                    </p>
                    <p>
                      <b>Type:</b>{" "}
                      <span className="text-slate-500">
                        {p.customerType || "—"}
                      </span>
                    </p>
                    <p className="sm:col-span-2">
                      <b>Purpose:</b>{" "}
                      <span className="text-slate-500">
                        {p.visitPurpose || "—"}
                      </span>
                    </p>
                    {p.contact && (
                      <p>
                        <b>Contact:</b>{" "}
                        <span className="text-slate-500">{p.contact}</span>
                      </p>
                    )}
                    {p.mobile && (
                      <p>
                        <b>Phone:</b>{" "}
                        <span className="text-slate-500">{p.mobile}</span>
                      </p>
                    )}
                  </div>
                </div>
                <ChevronRight className="mt-2 shrink-0 text-slate-400" />
              </button>
            ))}
          </div>
        )}
      </WorkflowSection>
    </>
  );
}
