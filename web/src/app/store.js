import { configureStore } from "@reduxjs/toolkit";
import auth from "@/features/auth/authSlice";
import ui from "@/app/uiSlice";

export const store = configureStore({ reducer: { auth, ui } });
