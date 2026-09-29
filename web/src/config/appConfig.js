export const appConfig = Object.freeze({
  apiBaseUrl: String(
    import.meta.env.VITE_API_BASE_URL || "http://localhost:5000/api",
  ).replace(/\/$/, ""),
  serviceEmail: String(
    import.meta.env.VITE_CRM_SERVICE_EMAIL || "crm-service@example.com",
  ).trim(),
  serviceSecret: String(
    import.meta.env.VITE_CRM_SERVICE_SECRET || "crm-service-secret",
  ).trim(),
  fixedApiToken: String(import.meta.env.VITE_API_TOKEN || "").trim(),
});
