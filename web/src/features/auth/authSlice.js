import { createSlice } from "@reduxjs/toolkit";
import { tokenStorage } from "@/utils/storage";

const storedContext = tokenStorage.getAuthContext() || {};
const initialState = {
  initialized: false,
  user: tokenStorage.getUser(),
  accessToken: tokenStorage.getAccessToken(),
  refreshToken: tokenStorage.getRefreshToken(),
  applicationSetup: storedContext.applicationSetup || null,
  upHierarchy: storedContext.upHierarchy || [],
  downHierarchy: storedContext.downHierarchy || [],
  cityAccess: storedContext.cityAccess || [],
  territoryAccess: storedContext.territoryAccess || [],
  productDivision: storedContext.productDivision || [],
  entryAccess: storedContext.entryAccess || [],
  menus: [],
};

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    setInitialized(state, action) {
      state.initialized = action.payload !== false;
    },
    setSession(state, action) {
      const p = action.payload || {};
      state.user = p.user || null;
      state.accessToken = p.accessToken || null;
      state.refreshToken = p.refreshToken || null;
      state.applicationSetup = p.applicationSetup || null;
      state.upHierarchy = p.upHierarchy || [];
      state.downHierarchy = p.downHierarchy || [];
      state.cityAccess = p.cityAccess || [];
      state.territoryAccess = p.territoryAccess || [];
      state.productDivision = p.productDivision || [];
      state.entryAccess = p.entryAccess || [];
      tokenStorage.saveSession(p);
    },
    updateAccessToken(state, action) {
      state.accessToken = action.payload || null;
      tokenStorage.setAccessToken(action.payload || null);
    },
    updateContext(state, action) {
      const p = action.payload || {};
      if (p.applicationSetup !== undefined) state.applicationSetup = p.applicationSetup;
      if (p.upHierarchy !== undefined) state.upHierarchy = p.upHierarchy || [];
      if (p.downHierarchy !== undefined) state.downHierarchy = p.downHierarchy || [];
      if (p.cityAccess !== undefined) state.cityAccess = p.cityAccess || [];
      if (p.territoryAccess !== undefined) state.territoryAccess = p.territoryAccess || [];
      if (p.productDivision !== undefined) state.productDivision = p.productDivision || [];
      if (p.entryAccess !== undefined) state.entryAccess = p.entryAccess || [];
      tokenStorage.setAuthContext({
        applicationSetup: state.applicationSetup,
        upHierarchy: state.upHierarchy,
        downHierarchy: state.downHierarchy,
        cityAccess: state.cityAccess,
        territoryAccess: state.territoryAccess,
        productDivision: state.productDivision,
        entryAccess: state.entryAccess,
      });
    },
    setMenus(state, action) {
      state.menus = action.payload || [];
    },
    clearSession(state) {
      state.user = null;
      state.accessToken = null;
      state.refreshToken = null;
      state.applicationSetup = null;
      state.upHierarchy = [];
      state.downHierarchy = [];
      state.cityAccess = [];
      state.territoryAccess = [];
      state.productDivision = [];
      state.entryAccess = [];
      state.menus = [];
      tokenStorage.clearSession();
    },
  },
});

export const {
  setInitialized,
  setSession,
  updateAccessToken,
  updateContext,
  setMenus,
  clearSession,
} = authSlice.actions;
export default authSlice.reducer;
