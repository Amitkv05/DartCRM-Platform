import { apiClient } from "@/api/apiClient";

const data = (promise) => promise.then((r) => r.data);

export const authApi = {
  login: (payload) => data(apiClient.post("/auth/login", payload, { skipAuth: true })),
  logout: (refreshToken) => data(apiClient.post("/auth/logout", { refreshToken })),
  forgotPassword: (email) => data(apiClient.post("/auth/forgot-password", { email }, { skipAuth: true })),
  resetPassword: (payload) => data(apiClient.post("/auth/reset-password", payload, { skipAuth: true })),
  changePassword: (payload) => data(apiClient.post("/auth/change-password", payload)),
};

export const setupApi = {
  setup: (key) => data(apiClient.get("/setup", { params: key ? { key } : {} })),
  menus: () => data(apiClient.get("/menus")),
  geography: (params = {}) => data(apiClient.get("/geography", { params })),
};

export const executiveApi = {
  myHierarchy: () => data(apiClient.get("/executives/me/hierarchy")),
  downHierarchy: () => data(apiClient.get("/executives/down-hierarchy")),
  get: (id) => data(apiClient.get(`/executives/${id}`)),
};

export const customerApi = {
  masterData: () => data(apiClient.get("/customers/master-data")),
  cities: () => data(apiClient.get("/customers/search-cities")),
  list: (params = {}) => data(apiClient.get("/customers", { params })),
  search: (params = {}) => data(apiClient.get("/customers/search", { params })),
  bookSellers: (params = {}) => data(apiClient.get("/customers/book-sellers", { params })),
  get: (id) => data(apiClient.get(`/customers/${id}`)),
  create: (payload) => data(apiClient.post("/customers", payload)),
  update: (id, payload) => data(apiClient.put(`/customers/${id}`, payload)),
  requestDelete: (id) => data(apiClient.post(`/customers/${id}/delete-request`)),
};

export const contactApi = {
  list: (customerId) => data(apiClient.get(`/contacts/customer/${customerId}`)),
  get: (id) => data(apiClient.get(`/contacts/${id}`)),
  create: (payload) => data(apiClient.post("/contacts", payload)),
  update: (id, payload) => data(apiClient.put(`/contacts/${id}`, payload)),
  delete: (id) => data(apiClient.delete(`/contacts/${id}`)),
};

export const attendanceApi = {
  today: () => data(apiClient.get("/attendance/today")),
  checkIn: (payload) => data(apiClient.post("/attendance/check-in", payload)),
  checkOut: (payload) => data(apiClient.post("/attendance/check-out", payload)),
  submitLocations: (payload) => data(apiClient.post("/attendance/locations", payload)),
};

export const planApi = {
  list: (params = {}) => data(apiClient.get("/plans", { params })),
  create: (payload) => data(apiClient.post("/plans", payload)),
};

export const visitApi = {
  dsrEntry: (params) => data(apiClient.get("/visits/dsr-entry", { params })),
  followUpExecutives: (departmentId) => data(apiClient.get("/visits/follow-up-executives", { params: { departmentId } })),
  create: (payload) => data(apiClient.post("/visits", payload)),
  details: (params) => data(apiClient.get("/visits/details", { params })),
  backdateRequests: () => data(apiClient.get("/visits/backdate-requests")),
  requestBackdate: (payload) => data(apiClient.post("/visits/backdate-requests", payload)),
};

function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () => reject(new Error("Could not read the selected file"));
    reader.readAsDataURL(file);
  });
}

export const fileApi = {
  upload: async (file, module = "visit") => {
    if (!file) throw new Error("Select a file to upload");
    if (file.size > 10 * 1024 * 1024) throw new Error("Document size cannot exceed 10 MB");
    const base64String = await fileToBase64(file);
    const extension = String(file.name || "").split(".").pop()?.toLowerCase() || "";
    return data(apiClient.post("/files/upload", {
      fileName: file.name,
      fileExtension: extension,
      base64String,
      module,
    }, { timeout: 60_000 }));
  },
};

export const catalogApi = {
  seriesClassLevels: () => data(apiClient.get("/catalog/series-class-levels")),
  titles: (params = {}) => data(apiClient.get("/catalog/titles", { params })),
  searchTitles: (query) => data(apiClient.get("/catalog/titles/search", { params: { query } })),
  shipmentModes: () => data(apiClient.get("/catalog/shipment-modes")),
};

export const samplingApi = {
  details: (params) => data(apiClient.get("/sampling/details", { params })),
  shipTo: (params) => data(apiClient.get("/sampling/ship-to", { params })),
  create: (payload) => data(apiClient.post("/sampling/customer", payload)),
  requests: () => data(apiClient.get("/sampling/requests")),
  approvals: () => data(apiClient.get("/sampling/approvals")),
  requestDetails: (id) => data(apiClient.get(`/sampling/requests/${id}`)),
};

export const selfStockApi = {
  masterData: () => data(apiClient.get("/self-stock/master-data")),
  tradeAddresses: () => data(apiClient.get("/self-stock/trade-addresses")),
  create: (payload) => data(apiClient.post("/self-stock/requests", payload)),
  requests: () => data(apiClient.get("/self-stock/requests")),
  approvals: () => data(apiClient.get("/self-stock/approvals")),
  requestDetails: (id) => data(apiClient.get(`/self-stock/requests/${id}`)),
};

export const approvalApi = {
  list: (module) => data(apiClient.get("/approvals", { params: module ? { module } : {} })),
  mine: (params = {}) => data(apiClient.get("/approvals/mine/history", { params })),
  details: (id) => data(apiClient.get(`/approvals/${id}`)),
  action: (id, payload) => data(apiClient.post(`/approvals/${id}/action`, payload)),
  bulkAction: (payload) => data(apiClient.post("/approvals/bulk-action", payload)),
};

export const notificationApi = {
  list: () => data(apiClient.get("/notifications")),
  markRead: (id) => data(apiClient.patch(`/notifications/${id}/read`)),
};

export const eProductApi = {
  productsByBrand: (brandId) => data(apiClient.get(`/e-products/brands/${brandId}/products`)),
  details: (eProductId, params = {}) => data(apiClient.get(`/e-products/${eProductId}/details`, { params })),
};

export const adminApi = {
  roleMeta: () => data(apiClient.get("/admin/role-management/meta")),
  users: (params = {}) => data(apiClient.get("/admin/users", { params })),
  user: (id) => data(apiClient.get(`/admin/users/${id}`)),
  createUser: (payload) => data(apiClient.post("/admin/users", payload)),
  updateUser: (id, payload) => data(apiClient.patch(`/admin/users/${id}`, payload)),
  deactivateUser: (id) => data(apiClient.delete(`/admin/users/${id}`)),
  reactivateUser: (id) => data(apiClient.post(`/admin/users/${id}/reactivate`)),
  approvalRoles: () => data(apiClient.get("/admin/executives/approval-roles")),
  updateApprovalRole: (id, approvalEnabled) => data(apiClient.patch(`/admin/executives/${id}/approval-role`, { approvalEnabled })),
  requestHistory: (params = {}) => data(apiClient.get("/admin/request-history", { params })),
  requestHistoryDetails: (id) => data(apiClient.get(`/admin/request-history/${id}`)),
  deleteHistory: (id) => data(apiClient.delete(`/admin/request-history/${id}`)),
  bulkDeleteHistory: (historyIds) => data(apiClient.post("/admin/request-history/bulk-delete", { historyIds })),
};
