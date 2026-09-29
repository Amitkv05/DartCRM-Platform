import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { ArrowLeft, LocateFixed, MapPin, Search } from "lucide-react";
import { toast } from "sonner";
import { customerApi, samplingApi, visitApi } from "@/api/crmApi";
import PageHeader from "@/components/common/PageHeader";
import LoadingState from "@/components/common/LoadingState";
import ErrorState from "@/components/common/ErrorState";
import {
  WorkflowSection,
  InfoLine,
  EmptyMessage,
} from "@/components/parity/WorkflowSection";
import { FormField } from "@/components/common/FormField";
import { Select } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import VisitSamplingPanel from "@/features/visits/VisitSamplingPanel";
import FollowUpPanel from "@/features/visits/FollowUpPanel";
import DocumentPanel from "@/features/visits/DocumentPanel";
import EProductPanel from "@/features/visits/EProductPanel";
import { getErrorMessage } from "@/utils/errors";
import { isDateInsideRanges, todayIso } from "@/utils/parity";
import {
  buildSamplingPayloadItems,
  validateSamplingContainers,
} from "@/components/parity/SamplingContainers";

const emptySampling = {
  items: [],
  containerSettings: {},
  shipmentModeId: "",
  shippingInstructions: "",
  requestRemarks: "",
};

function ToggleRow({ label, value, onChange }) {
  return (
    <div className="flex items-center justify-between gap-4 rounded-lg border border-slate-200 bg-slate-50 px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-950">
      <span className="font-semibold">{label}</span>
      <div className="flex items-center gap-2">
        <Button
          type="button"
          size="sm"
          variant={value ? "primary" : "outline"}
          onClick={() => onChange(true)}
        >
          Yes
        </Button>
        <Button
          type="button"
          size="sm"
          variant={!value ? "primary" : "outline"}
          onClick={() => onChange(false)}
        >
          No
        </Button>
      </div>
    </div>
  );
}

export default function VisitEntryPage() {
  const { customerId: routeCustomerId } = useParams();
  const nav = useNavigate();
  const user = useSelector((state) => state.auth.user);
  const customerId = Number(routeCustomerId || 0);
  const [visitDate, setVisitDate] = useState(todayIso());
  const [purposeId, setPurposeId] = useState("");
  const [personMet, setPersonMet] = useState("");
  const [jointIds, setJointIds] = useState([]);
  const [academicSessionId, setAcademicSessionId] = useState("");
  const [feedback, setFeedback] = useState("");
  const [address, setAddress] = useState("");
  const [lat, setLat] = useState("");
  const [lng, setLng] = useState("");
  const [locationError, setLocationError] = useState("");
  const [samplingDone, setSamplingDone] = useState(false);
  const [sampling, setSampling] = useState(emptySampling);
  const [eProducts, setEProducts] = useState(false);
  const [promotions, setPromotions] = useState([]);
  const [followUpEnabled, setFollowUpEnabled] = useState(false);
  const [followUps, setFollowUps] = useState([]);
  const [documents, setDocuments] = useState([]);
  const [showPastVisits, setShowPastVisits] = useState(false);
  const [showPastSampling, setShowPastSampling] = useState(false);

  const customerQ = useQuery({
    queryKey: ["customer", customerId, "visit"],
    queryFn: () => customerApi.get(customerId),
    enabled: Boolean(customerId),
  });
  const dsrQ = useQuery({
    queryKey: ["dsr-entry", customerId],
    queryFn: () => visitApi.dsrEntry({ customerId }),
    enabled: Boolean(customerId),
  });
  const pastVisitsQ = useQuery({
    queryKey: ["visit-history", customerId],
    queryFn: () => visitApi.details({ customerId }),
    enabled: Boolean(customerId && showPastVisits),
  });
  const pastSamplingQ = useQuery({
    queryKey: ["sampling-history", "visit-screen"],
    queryFn: samplingApi.requests,
    enabled: showPastSampling,
  });

  const dsr = dsrQ.data;
  const customer = customerQ.data?.customer || dsr?.customerSummary;
  const school = customerQ.data?.school;
  const samplingVisible =
    String(
      dsr?.applicationSetupKeyValue?.[0]?.visitBooksSampling || "N",
    ).toUpperCase() === "Y";
  const eProductVisible =
    String(
      dsr?.applicationSetupKeyValue?.[0]?.visitEProducts || "N",
    ).toUpperCase() === "Y";
  const allowedRanges = useMemo(
    () => dsr?.allowedDateRanges || [],
    [dsr?.allowedDateRanges],
  );
  const allowedText = useMemo(
    () =>
      allowedRanges
        .map((r) =>
          r.fromDate === r.toDate ? r.fromDate : `${r.fromDate} → ${r.toDate}`,
        )
        .join(", "),
    [allowedRanges],
  );

  useEffect(() => {
    if (customer?.address && !address) setAddress(customer.address);
  }, [customer, address]);
  useEffect(() => {
    if (dsr?.academicSessions?.[0] && !academicSessionId)
      setAcademicSessionId(String(dsr.academicSessions[0].id));
  }, [dsr, academicSessionId]);
  useEffect(() => {
    captureLocation(false);
  }, []);
  function captureLocation(showSuccess = true) {
    if (!navigator.geolocation) {
      setLocationError("Location is not supported by this browser.");
      return;
    }
    setLocationError("");
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLat(pos.coords.latitude.toFixed(7));
        setLng(pos.coords.longitude.toFixed(7));
        if (showSuccess) toast.success("Location captured");
      },
      (err) => {
        setLocationError(
          "Location Access is required for Visit Entry. Please allow browser location permission.",
        );
        if (showSuccess) toast.error(err.message);
      },
      { enableHighAccuracy: true, timeout: 12000, maximumAge: 30000 },
    );
  }

  const submit = useMutation({
    mutationFn: async () => {
      if (!customerId || !customer) throw new Error("Customer is missing");
      if (!purposeId) throw new Error("Please select Visit Purpose");
      if (!visitDate || !isDateInsideRanges(visitDate, allowedRanges))
        throw new Error(
          "Visit date is outside the allowed date range. Request backdate approval first if required.",
        );
      if (!feedback.trim()) throw new Error("Visit Feedback is required");
      if (!lat || !lng)
        throw new Error("Location is required before submitting the DSR entry");
      if (samplingDone) {
        const samplingError = validateSamplingContainers(
          sampling.items || [],
          sampling.containerSettings || {},
        );
        if (samplingError) throw new Error(samplingError);
        if (!sampling.shipmentModeId)
          throw new Error("Please select Shipment Mode for Sampling Done");
      }
      const selectedRange = allowedRanges.find(
        (r) => visitDate >= String(r.fromDate) && visitDate <= String(r.toDate),
      );
      const samplingPayload = samplingDone
        ? {
            shipmentModeId: Number(sampling.shipmentModeId),
            shippingInstructions: sampling.shippingInstructions || null,
            requestRemarks: sampling.requestRemarks || null,
            items: buildSamplingPayloadItems(
              sampling.items || [],
              sampling.containerSettings || {},
            ),
          }
        : null;
      return visitApi.create({
        customerId,
        customerType: String(
          customer.customer_type || customer.customerType || "SCHOOL",
        ).toUpperCase(),
        customerContactId: Number(personMet) || null,
        academicSessionId: Number(academicSessionId) || null,
        visitPurposeId: Number(purposeId),
        visitFeedback: feedback.trim(),
        visitDate,
        address: address.trim() || `${lat}, ${lng}`,
        latitude: Number(lat),
        longitude: Number(lng),
        jointExecutiveIds: jointIds.map(Number),
        documents: documents.map(({ documentName, fileName, fileSize }) => ({
          documentName,
          fileName,
          fileSize,
        })),
        followUps: followUps.map(
          ({ departmentId, followUpExecutiveId, action, followUpDate }) => ({
            departmentId,
            followUpExecutiveId,
            action,
            followUpDate,
          }),
        ),
        eProductPromotions: eProducts
          ? promotions.map(({ _brand, _product, _stage, _prospect, ...p }) => p)
          : [],
        sampling: samplingPayload,
        backdateRequestId: selectedRange?.backdateRequestId || null,
        webEntry: "Yes",
      });
    },
    onSuccess: (r) => {
      toast.success(
        `${r.message}${r.sampling?.requestNumber ? ` · Sampling ${r.sampling.requestNumber}` : ""}`,
      );
      nav(`/customers/${customerId}`);
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  if (!customerId)
    return (
      <ErrorState
        error={
          new Error(
            "Open Visit Entry from School Visit search or from Today's/Tomorrow's Plan.",
          )
        }
      />
    );
  if (customerQ.isLoading || dsrQ.isLoading) return <LoadingState />;
  if (customerQ.isError) return <ErrorState error={customerQ.error} />;
  if (dsrQ.isError) return <ErrorState error={dsrQ.error} />;

  const pastSampling = (pastSamplingQ.data?.requests || []).filter(
    (x) => Number(x.customer_id) === customerId,
  );
  return (
    <>
      <PageHeader
        title="School Visit"
        description="Flutter-parity DSR Entry: customer detail, location, sampling, E-Products, follow-up, documents and feedback."
        actions={
          <>
            <Button variant="outline" onClick={() => nav(-1)}>
              <ArrowLeft size={15} />
              Back
            </Button>
            <Button variant="outline" onClick={() => nav("/visits/new")}>
              <Search size={15} />
              New Search
            </Button>
          </>
        }
      />
      <div className="space-y-4">
        {locationError && (
          <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 font-semibold text-red-600 dark:border-red-900 dark:bg-red-950/30">
            {locationError}
          </div>
        )}
        <WorkflowSection title="School Visit">
          <div className="grid gap-5 lg:grid-cols-2">
            <div className="grid gap-4 sm:grid-cols-2">
              <FormField label="Executive Name">
                <Input value={user?.executiveName || ""} disabled />
              </FormField>
              <FormField
                label="Visit Date"
                required
                hint={allowedText ? `Allowed: ${allowedText}` : undefined}
              >
                <Input
                  type="date"
                  value={visitDate}
                  onChange={(e) => setVisitDate(e.target.value)}
                />
              </FormField>
              <FormField label="Visit Purpose" required>
                <Select
                  value={purposeId}
                  onChange={(e) => setPurposeId(e.target.value)}
                >
                  <option value="">--Select--</option>
                  {(dsr?.visitPurpose || []).map((x) => (
                    <option key={x.id} value={x.id}>
                      {x.visit_purpose}
                    </option>
                  ))}
                </Select>
              </FormField>
              <FormField
                label="Person Met"
                hint="Optional when no contact exists."
              >
                <Select
                  value={personMet}
                  onChange={(e) => setPersonMet(e.target.value)}
                >
                  <option value="">--Not specified--</option>
                  {(dsr?.personMet || []).map((x) => (
                    <option
                      key={x.customer_contact_id}
                      value={x.customer_contact_id}
                    >
                      {x.customer_contact_name}
                    </option>
                  ))}
                </Select>
              </FormField>
              <FormField label="Joint Visit With">
                <select
                  multiple
                  className="min-h-24 w-full rounded-lg border border-slate-200 bg-white p-2 text-sm dark:border-slate-700 dark:bg-slate-950"
                  value={jointIds.map(String)}
                  onChange={(e) =>
                    setJointIds(
                      [...e.target.selectedOptions].map((o) => o.value),
                    )
                  }
                >
                  {(dsr?.joinVisit || []).map((x) => (
                    <option key={x.executive_id} value={x.executive_id}>
                      {x.executive_name}
                    </option>
                  ))}
                </select>
              </FormField>
              {eProductVisible && (
                <FormField label="Academic Session">
                  <Select
                    value={academicSessionId}
                    onChange={(e) => setAcademicSessionId(e.target.value)}
                  >
                    <option value="">--Select--</option>
                    {(dsr?.academicSessions || []).map((x) => (
                      <option key={x.id} value={x.id}>
                        {x.session_name}
                      </option>
                    ))}
                  </Select>
                </FormField>
              )}
            </div>
            <div className="grid gap-3">
              {samplingVisible && (
                <ToggleRow
                  label="Sampling Done"
                  value={samplingDone}
                  onChange={setSamplingDone}
                />
              )}{" "}
              {eProductVisible && (
                <ToggleRow
                  label="Visit Products"
                  value={eProducts}
                  onChange={setEProducts}
                />
              )}
              <ToggleRow
                label="Follow Up Action"
                value={followUpEnabled}
                onChange={setFollowUpEnabled}
              />
            </div>
          </div>
        </WorkflowSection>

        <div className="grid gap-4 lg:grid-cols-2">
          <WorkflowSection title="School Basic Details">
            <div className="space-y-2">
              <p className="text-base font-bold">
                {customer?.customer_name || customer?.customerName}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">
                {customer?.address || "—"}
              </p>
              <InfoLine label="Customer Code" value={customer?.customer_code} />
              <InfoLine label="Reference No" value={customer?.ref_code} />
              <InfoLine label="Email" value={customer?.email} />
              <InfoLine label="Mobile" value={customer?.mobile} />
            </div>
          </WorkflowSection>
          <WorkflowSection title="School Enrollment">
            <div className="space-y-2">
              <InfoLine
                label="Start Class"
                value={school?.start_class_num_id ?? school?.start_class_id}
              />
              <InfoLine
                label="End Class"
                value={school?.end_class_num_id ?? school?.end_class_id}
              />
              <InfoLine label="Medium" value={school?.medium_instruction} />
              <InfoLine label="Ranking" value={school?.ranking} />
              <p className="pt-2 text-xs text-slate-500">
                The current V4 backend stores the school start/end class and
                school master data, but it does not store class-wise enrollment
                strength/year history. Those figures are therefore not
                fabricated on the website.
              </p>
            </div>
          </WorkflowSection>
        </div>
        <div className="flex flex-wrap gap-4 px-1 text-sm font-medium text-blue-600 dark:text-blue-400">
          <button onClick={() => setShowPastSampling((v) => !v)}>
            View Past Sampling
          </button>
          <span>||</span>
          <button onClick={() => setShowPastVisits((v) => !v)}>
            View Past Visit
          </button>
          <span>||</span>
          <span className="text-slate-400">
            Past Adoptions (API not available)
          </span>
        </div>
        {showPastSampling && (
          <WorkflowSection title="Past Sampling">
            {pastSamplingQ.isLoading ? (
              <LoadingState />
            ) : pastSampling.length ? (
              <div className="space-y-2">
                {pastSampling.slice(0, 10).map((x) => (
                  <div
                    key={x.id}
                    className="rounded-lg border p-3 text-sm dark:border-slate-800"
                  >
                    <b>{x.request_number}</b> · {x.request_status} · Qty{" "}
                    {x.total_qty}
                  </div>
                ))}
              </div>
            ) : (
              <EmptyMessage>
                No previous sampling request for this customer.
              </EmptyMessage>
            )}
          </WorkflowSection>
        )}
        {showPastVisits && (
          <WorkflowSection title="Past Visit">
            {pastVisitsQ.isLoading ? (
              <LoadingState />
            ) : (pastVisitsQ.data?.visits || []).length ? (
              <div className="space-y-3">
                {pastVisitsQ.data.visits.slice(0, 10).map((v) => (
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
                  </div>
                ))}
              </div>
            ) : (
              <EmptyMessage>
                No previous visit entry is available for this customer yet.
              </EmptyMessage>
            )}
          </WorkflowSection>
        )}

        {samplingVisible && samplingDone && (
          <VisitSamplingPanel
            customerId={customerId}
            value={sampling}
            onChange={setSampling}
          />
        )}
        {eProductVisible && eProducts && (
          <EProductPanel
            dsr={dsr}
            customerId={customerId}
            academicSessionId={academicSessionId}
            rows={promotions}
            onChange={setPromotions}
          />
        )}
        {followUpEnabled && (
          <FollowUpPanel
            departments={dsr?.departments || []}
            visitDate={visitDate}
            rows={followUps}
            onChange={setFollowUps}
          />
        )}
        <DocumentPanel documents={documents} onChange={setDocuments} />
        <WorkflowSection title="Visit Feedback">
          <FormField label="Visit Feedback" required>
            <Textarea
              className="min-h-28"
              maxLength={500}
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              placeholder="Visit feedback"
            />
          </FormField>
        </WorkflowSection>
        <WorkflowSection title="Location & Submit">
          <div className="grid gap-4 md:grid-cols-2">
            <FormField className="md:col-span-2" label="Address">
              <Textarea
                value={address}
                onChange={(e) => setAddress(e.target.value)}
              />
            </FormField>
            <FormField label="Latitude" required>
              <Input value={lat} onChange={(e) => setLat(e.target.value)} />
            </FormField>
            <FormField label="Longitude" required>
              <Input value={lng} onChange={(e) => setLng(e.target.value)} />
            </FormField>
          </div>
          <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
            <Button
              type="button"
              variant="outline"
              onClick={() => captureLocation(true)}
            >
              <LocateFixed size={16} />
              Use Current Location
            </Button>
            <Button
              type="button"
              variant="primary"
              className="min-w-44"
              disabled={submit.isPending}
              onClick={() => submit.mutate()}
            >
              <MapPin size={16} />
              {submit.isPending ? "Submitting DSR…" : "Submit"}
            </Button>
          </div>
        </WorkflowSection>
      </div>
    </>
  );
}
