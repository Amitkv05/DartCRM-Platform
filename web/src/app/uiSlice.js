import { createSlice } from "@reduxjs/toolkit";

const savedTheme = typeof localStorage !== "undefined" ? localStorage.getItem("dartcrm.dashboard.theme") : null;
const savedSidebarCollapsed = typeof localStorage !== "undefined"
  ? localStorage.getItem("dartcrm.dashboard.sidebarCollapsed") === "true"
  : false;

const slice = createSlice({
  name: "ui",
  initialState: {
    sidebarOpen: false,
    sidebarCollapsed: savedSidebarCollapsed,
    theme: savedTheme || "dark",
  },
  reducers: {
    toggleSidebar(state) { state.sidebarOpen = !state.sidebarOpen; },
    closeSidebar(state) { state.sidebarOpen = false; },
    toggleSidebarCollapse(state) {
      state.sidebarCollapsed = !state.sidebarCollapsed;
      try {
        localStorage.setItem("dartcrm.dashboard.sidebarCollapsed", String(state.sidebarCollapsed));
      } catch { /* noop */ }
    },
    setSidebarCollapsed(state, action) {
      state.sidebarCollapsed = Boolean(action.payload);
      try {
        localStorage.setItem("dartcrm.dashboard.sidebarCollapsed", String(state.sidebarCollapsed));
      } catch { /* noop */ }
    },
    setTheme(state, action) {
      state.theme = action.payload;
      try { localStorage.setItem("dartcrm.dashboard.theme", action.payload); } catch { /* noop */ }
    },
  },
});

export const {
  toggleSidebar,
  closeSidebar,
  toggleSidebarCollapse,
  setSidebarCollapsed,
  setTheme,
} = slice.actions;
export default slice.reducer;
