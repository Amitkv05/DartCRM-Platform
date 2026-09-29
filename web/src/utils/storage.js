const keys = {
  apiToken: "dartcrm.apiToken",
  apiTokenExpiresAt: "dartcrm.apiTokenExpiresAt",
  accessToken: "dartcrm.accessToken",
  refreshToken: "dartcrm.refreshToken",
  user: "dartcrm.user",
  authContext: "dartcrm.authContext",
};

function safeGet(key) {
  try { return localStorage.getItem(key); } catch { return null; }
}

function safeSet(key, value) {
  try {
    if (value === undefined || value === null || value === "") localStorage.removeItem(key);
    else localStorage.setItem(key, String(value));
  } catch { /* storage can be unavailable in private/restricted browser contexts */ }
}

function safeJsonGet(key) {
  try { return JSON.parse(safeGet(key) || "null"); } catch { return null; }
}

function safeJsonSet(key, value) {
  safeSet(key, value ? JSON.stringify(value) : null);
}

export const tokenStorage = {
  getApiToken: () => safeGet(keys.apiToken),
  getApiTokenExpiry: () => safeGet(keys.apiTokenExpiresAt),
  setApiToken(value, expiresAt) {
    safeSet(keys.apiToken, value);
    if (expiresAt) safeSet(keys.apiTokenExpiresAt, expiresAt);
  },
  clearApiToken() {
    safeSet(keys.apiToken, null);
    safeSet(keys.apiTokenExpiresAt, null);
  },
  isApiTokenUsable(skewMs = 60_000) {
    const token = safeGet(keys.apiToken);
    if (!token) return false;
    const rawExpiry = safeGet(keys.apiTokenExpiresAt);
    if (!rawExpiry) return true; // old saved token: let backend validate it once
    const expiry = new Date(rawExpiry).getTime();
    return Number.isFinite(expiry) && expiry > Date.now() + skewMs;
  },

  getAccessToken: () => safeGet(keys.accessToken),
  setAccessToken: (value) => safeSet(keys.accessToken, value),
  getRefreshToken: () => safeGet(keys.refreshToken),
  setRefreshToken: (value) => safeSet(keys.refreshToken, value),

  getUser: () => safeJsonGet(keys.user),
  setUser: (value) => safeJsonSet(keys.user, value),
  getAuthContext: () => safeJsonGet(keys.authContext),
  setAuthContext: (value) => safeJsonSet(keys.authContext, value),

  saveSession(payload) {
    safeSet(keys.accessToken, payload?.accessToken);
    safeSet(keys.refreshToken, payload?.refreshToken);
    safeJsonSet(keys.user, payload?.user || null);
    safeJsonSet(keys.authContext, {
      applicationSetup: payload?.applicationSetup || null,
      upHierarchy: payload?.upHierarchy || [],
      downHierarchy: payload?.downHierarchy || [],
      cityAccess: payload?.cityAccess || [],
      territoryAccess: payload?.territoryAccess || [],
      productDivision: payload?.productDivision || [],
      entryAccess: payload?.entryAccess || [],
    });
  },

  // Same logout behavior as the Flutter app: user JWTs/session are removed,
  // while the shared application API token can stay and be reused.
  clearSession() {
    safeSet(keys.accessToken, null);
    safeSet(keys.refreshToken, null);
    safeJsonSet(keys.user, null);
    safeJsonSet(keys.authContext, null);
  },

  clearAll() {
    this.clearSession();
    this.clearApiToken();
  },
};
