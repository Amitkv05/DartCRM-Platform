import { Badge } from "@/components/ui/badge";
import { titleCase } from "@/utils/format";

export default function StatusBadge({ status }) {
  const value = String(status || "UNKNOWN").toUpperCase();
  const tone = value.includes("APPROVED") || value === "ACTIVE" || value === "VALIDATED" || value === "SUCCESS"
    ? "green"
    : value.includes("REJECT") || value === "INACTIVE" || value === "DELETED" || value === "ERROR"
      ? "red"
      : value.includes("PENDING") ? "amber" : value.includes("LEVEL") ? "purple" : "slate";
  return <Badge tone={tone}>{titleCase(value)}</Badge>;
}
