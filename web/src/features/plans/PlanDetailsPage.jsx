import { useLocation, useNavigate, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, MapPin } from "lucide-react";
import { customerApi, visitApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import {
  WorkflowSection,
  InfoLine,
  EmptyMessage,
} from "@/components/parity/WorkflowSection";
import { Button } from "@/components/ui/button";
import { planRow } from "@/utils/parity";

export default function PlanDetailsPage() {
  const { customerId } = useParams();
  const id = Number(customerId);
  const nav = useNavigate();
  const location = useLocation();
  const plan = planRow(location.state?.plan || {});
  const customer = useQuery({
    queryKey: ["customer", id, "plan-detail"],
    queryFn: () => customerApi.get(id),
    enabled: Boolean(id),
  });
  const history = useQuery({
    queryKey: ["visit-history", id, "plan-detail"],
    queryFn: () => visitApi.details({ customerId: id }),
    enabled: Boolean(id),
  });
  if (customer.isLoading) return <LoadingState />;
  if (customer.isError) return <ErrorState error={customer.error} />;
  const c = customer.data?.customer || {};
  const contacts = customer.data?.contacts || [];
  const primary =
    contacts.find((x) => Number(x.primary_contact) === 1) || contacts[0];
  return (
    <>
      <PageHeader
        title="Plan Details"
        description="Open the planned customer and continue directly into DSR Entry."
        actions={
          <Button variant="outline" onClick={() => nav(-1)}>
            <ArrowLeft size={15} />
            Back
          </Button>
        }
      />
      <div className="grid gap-4 lg:grid-cols-2">
        <WorkflowSection title="Customer Information">
          <div className="space-y-2">
            <h3 className="text-lg font-bold text-violet-800 dark:text-violet-300">
              {c.customer_name || plan.customerName}
            </h3>
            <InfoLine
              label="Customer Code"
              value={c.customer_code || plan.customerCode}
            />
            <InfoLine
              label="Customer Type"
              value={c.customer_type || plan.customerType}
            />
            <InfoLine label="Address" value={c.address || plan.address} />
            <InfoLine label="City" value={c.city || plan.city} />
            <InfoLine
              label="Contact"
              value={[primary?.first_name, primary?.last_name]
                .filter(Boolean)
                .join(" ")}
            />
            <InfoLine label="Email" value={primary?.email || c.email} />
            <InfoLine label="Mobile" value={primary?.mobile || c.mobile} />
            <InfoLine label="Visit Purpose" value={plan.visitPurpose} />
            <div className="pt-3">
              <Button
                variant="primary"
                onClick={() => nav(`/visits/customer/${id}`)}
              >
                <MapPin size={16} />
                DSR Entry
              </Button>
            </div>
          </div>
        </WorkflowSection>
        <WorkflowSection title="Recent Visit Details">
          {history.isLoading ? (
            <LoadingState />
          ) : (history.data?.visits || []).length ? (
            <div className="space-y-3">
              {history.data.visits.slice(0, 5).map((v) => (
                <div
                  key={v.id}
                  className="rounded-lg border p-3 text-sm dark:border-slate-800"
                >
                  <p className="font-semibold">
                    {String(v.visit_date).slice(0, 10)} ·{" "}
                    {v.visit_purpose || "Visit"}
                  </p>
                  <p className="mt-1 text-slate-500">
                    {v.visit_feedback || "No feedback"}
                  </p>
                  <p className="mt-1 text-xs text-slate-400">
                    Visited by {v.executive_name || "—"}
                    {v.person_met ? ` · Person met: ${v.person_met}` : ""}
                  </p>
                </div>
              ))}
            </div>
          ) : (
            <EmptyMessage>
              No previous visit entry is available for this customer yet.
            </EmptyMessage>
          )}
        </WorkflowSection>
      </div>
      <div className="mt-4">
        <WorkflowSection title="School / Account Details">
          <div className="grid gap-3 sm:grid-cols-2">
            <InfoLine label="Reference Code" value={c.ref_code} />
            <InfoLine label="Validation" value={c.validation_status} />
            <InfoLine label="Status" value={c.customer_status} />
            <InfoLine
              label="Assigned Contacts"
              value={String(contacts.length)}
            />
          </div>
        </WorkflowSection>
      </div>
    </>
  );
}
