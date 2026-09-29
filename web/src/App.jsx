import AppRoutes from "@/routes/AppRoutes";
import AuthBootstrap from "@/components/auth/AuthBootstrap";
import AppErrorBoundary from "@/components/common/AppErrorBoundary";
import { useThemeSync } from "@/hooks/useThemeSync";

export default function App() {
  useThemeSync();
  return (
    <AppErrorBoundary>
      <AuthBootstrap>
        <AppRoutes />
      </AuthBootstrap>
    </AppErrorBoundary>
  );
}
