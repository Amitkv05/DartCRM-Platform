import axios from "axios";
import { appConfig } from "@/config/appConfig";
import { tokenStorage } from "@/utils/storage";

const rawClient = axios.create({ baseURL: appConfig.apiBaseUrl, timeout: 20_000 });
export const apiClient = axios.create({ baseURL: appConfig.apiBaseUrl, timeout: 20_000 });

let apiTokenPromise = null;
let refreshPromise = null;

function apiTokenFailure(error) {
  const status = error?.response?.status;
  const message = String(error?.response?.data?.message || error?.message || "");
  return status === 401 && /(api token|x-api-token)/i.test(message);
}

export async function ensureApiToken(force = false) {
  if (appConfig.fixedApiToken) {
    tokenStorage.setApiToken(appConfig.fixedApiToken);
    return appConfig.fixedApiToken;
  }

  if (!force && tokenStorage.isApiTokenUsable()) {
    return tokenStorage.getApiToken();
  }

  // One shared promise prevents multiple screens from creating several tokens
  // at the same moment during startup.
  if (apiTokenPromise) return apiTokenPromise;

  if (!appConfig.serviceEmail || !appConfig.serviceSecret) {
    throw new Error("CRM service account is not configured for API-token generation.");
  }

  apiTokenPromise = rawClient
    .post("/token", {
      email: appConfig.serviceEmail,
      secret: appConfig.serviceSecret,
    })
    .then(({ data }) => {
      const token = String(data?.apiToken || "").trim();
      if (!token) throw new Error("Backend did not return an API token");
      tokenStorage.setApiToken(token, data?.expiresAt || null);
      return token;
    })
    .finally(() => {
      apiTokenPromise = null;
    });

  return apiTokenPromise;
}

export async function refreshAccessToken() {
  if (refreshPromise) return refreshPromise;
  const refreshToken = tokenStorage.getRefreshToken();
  if (!refreshToken) throw new Error("Session expired. Please sign in again.");

  refreshPromise = (async () => {
    let apiToken = await ensureApiToken();
    try {
      const { data } = await rawClient.post(
        "/auth/refresh",
        { refreshToken },
        { headers: { "x-api-token": apiToken } },
      );
      const accessToken = String(data?.accessToken || "").trim();
      if (!accessToken) throw new Error("Refresh response did not contain an access token");
      tokenStorage.setAccessToken(accessToken);
      return accessToken;
    } catch (error) {
      if (apiTokenFailure(error)) {
        tokenStorage.clearApiToken();
        apiToken = await ensureApiToken(true);
        const { data } = await rawClient.post(
          "/auth/refresh",
          { refreshToken },
          { headers: { "x-api-token": apiToken } },
        );
        const accessToken = String(data?.accessToken || "").trim();
        if (!accessToken) throw new Error("Refresh response did not contain an access token");
        tokenStorage.setAccessToken(accessToken);
        return accessToken;
      }
      throw error;
    }
  })().finally(() => {
    refreshPromise = null;
  });

  return refreshPromise;
}

apiClient.interceptors.request.use(async (config) => {
  if (!config.skipApiToken) {
    config.headers = config.headers || {};
    config.headers["x-api-token"] = await ensureApiToken();
  }

  const accessToken = tokenStorage.getAccessToken();
  if (accessToken && !config.skipAuth) {
    config.headers = config.headers || {};
    config.headers.Authorization = `Bearer ${accessToken}`;
  }
  return config;
});

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error?.config || {};
    if (error?.response?.status !== 401) throw error;

    // Shared application token expired/revoked -> create another token and
    // transparently repeat the original request once.
    if (apiTokenFailure(error) && !original._apiTokenRetry) {
      original._apiTokenRetry = true;
      tokenStorage.clearApiToken();
      const newApiToken = await ensureApiToken(true);
      original.headers = original.headers || {};
      original.headers["x-api-token"] = newApiToken;
      return apiClient(original);
    }

    const url = String(original.url || "");
    const isLogin = url.includes("/auth/login");
    const isRefresh = url.includes("/auth/refresh");

    // A normal protected API got a 401 -> refresh JWT once, then retry.
    if (!isLogin && !isRefresh && !original._accessTokenRetry && tokenStorage.getRefreshToken()) {
      original._accessTokenRetry = true;
      try {
        const accessToken = await refreshAccessToken();
        original.headers = original.headers || {};
        original.headers.Authorization = `Bearer ${accessToken}`;
        return apiClient(original);
      } catch (refreshError) {
        tokenStorage.clearSession();
        window.dispatchEvent(new CustomEvent("dartcrm:session-expired"));
        throw refreshError;
      }
    }

    throw error;
  },
);

export const crmBootstrap = {
  ensureApiToken,
  refreshAccessToken,
};
