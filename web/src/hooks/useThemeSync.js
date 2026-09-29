import { useEffect } from "react";
import { useSelector } from "react-redux";

export function useThemeSync() {
  const theme = useSelector((s) => s.ui.theme);
  useEffect(() => {
    document.documentElement.classList.toggle("dark", theme === "dark");
  }, [theme]);
}
