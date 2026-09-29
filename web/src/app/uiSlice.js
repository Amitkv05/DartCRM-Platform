import { createSlice } from "@reduxjs/toolkit";

const savedTheme = typeof localStorage !== "undefined" ? localStorage.getItem("dartcrm.theme") : null;
const slice = createSlice({
  name: "ui",
  initialState: { sidebarOpen: false, theme: savedTheme || "light" },
  reducers: {
    toggleSidebar(state) { state.sidebarOpen = !state.sidebarOpen; },
    closeSidebar(state) { state.sidebarOpen = false; },
    setTheme(state, action) {
      state.theme = action.payload;
      try { localStorage.setItem("dartcrm.theme", action.payload); } catch { /* noop */ }
    },
  },
});
export const { toggleSidebar, closeSidebar, setTheme } = slice.actions;
export default slice.reducer;
