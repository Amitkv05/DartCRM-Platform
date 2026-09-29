import { Navigate, Route, Routes } from "react-router-dom";
import ProtectedRoute from "@/routes/ProtectedRoute";
import AdminOnly from "@/routes/AdminOnly";
import AppShell from "@/components/layout/AppShell";
import LoginPage from "@/features/auth/LoginPage";
import ResetPasswordPage from "@/features/auth/ResetPasswordPage";
import DashboardPage from "@/features/dashboard/DashboardPage";
import CustomersPage from "@/features/customers/CustomersPage";
import CustomerFormPage from "@/features/customers/CustomerFormPage";
import CustomerDetailsPage from "@/features/customers/CustomerDetailsPage";
import VisitSearchPage from "@/features/visits/VisitSearchPage";
import VisitSearchResultsPage from "@/features/visits/VisitSearchResultsPage";
import VisitEntryPage from "@/features/visits/VisitEntryPage";
import BackdateRequestPage from "@/features/visits/BackdateRequestPage";
import SamplingSearchPage from "@/features/sampling/SamplingSearchPage";
import SamplingResultsPage from "@/features/sampling/SamplingResultsPage";
import SamplingDetailPage from "@/features/sampling/SamplingDetailPage";
import SelfStockRequestPage from "@/features/selfstock/SelfStockRequestPage";
import ApprovalInboxPage from "@/features/approvals/ApprovalInboxPage";
import ApprovalDetailsPage from "@/features/approvals/ApprovalDetailsPage";
import MyRequestHistoryPage from "@/features/approvals/MyRequestHistoryPage";
import PlansPage from "@/features/plans/PlansPage";
import PlanDetailsPage from "@/features/plans/PlanDetailsPage";
import AttendancePage from "@/features/attendance/AttendancePage";
import NotificationsPage from "@/features/notifications/NotificationsPage";
import EProductsPage from "@/features/eproducts/EProductsPage";
import SettingsPage from "@/features/settings/SettingsPage";
import AdminUsersPage from "@/features/admin/AdminUsersPage";
import AdminRequestHistoryPage from "@/features/admin/AdminRequestHistoryPage";
import NotFoundPage from "@/features/misc/NotFoundPage";

const approvalModules = {
  "customer-sampling": "CUSTOMER_SAMPLING",
  "self-stock": "SELF_STOCK",
  "customer-create": "CUSTOMER_CREATE",
  "customer-update": "CUSTOMER_UPDATE",
  "customer-delete": "CUSTOMER_DELETE",
  "contact-create": "CONTACT_CREATE",
  "visit-backdate": "VISIT_BACKDATE",
};

export default function AppRoutes() {
  return <Routes>
    <Route path="/login" element={<LoginPage/>}/>
    <Route path="/reset-password" element={<ResetPasswordPage/>}/>
    <Route element={<ProtectedRoute/>}>
      <Route element={<AppShell/>}>
        <Route index element={<Navigate to="/dashboard" replace/>}/>
        <Route path="/dashboard" element={<DashboardPage/>}/>
        <Route path="/customers/school" element={<CustomersPage customerType="SCHOOL"/>}/>
        <Route path="/customers/trade" element={<CustomersPage customerType="TRADE"/>}/>
        <Route path="/customers/library" element={<CustomersPage customerType="LIBRARY"/>}/>
        <Route path="/customers/institute" element={<CustomersPage customerType="INSTITUTE"/>}/>
        <Route path="/customers/new" element={<CustomerFormPage/>}/>
        <Route path="/customers/:id" element={<CustomerDetailsPage/>}/>
        <Route path="/customers/:id/edit" element={<CustomerFormPage/>}/>
        <Route path="/plans/today" element={<PlansPage day="today"/>}/>
        <Route path="/plans/tomorrow" element={<PlansPage day="tomorrow"/>}/>
        <Route path="/plans/:day/customer/:customerId" element={<PlanDetailsPage/>}/>
        <Route path="/visits/new" element={<VisitSearchPage/>}/>
        <Route path="/visits/search-results" element={<VisitSearchResultsPage/>}/>
        <Route path="/visits/customer/:customerId" element={<VisitEntryPage/>}/>
        <Route path="/visits/backdate-request" element={<BackdateRequestPage/>}/>
        <Route path="/sampling/school" element={<SamplingSearchPage customerType="SCHOOL"/>}/>
        <Route path="/sampling/trade" element={<SamplingSearchPage customerType="TRADE"/>}/>
        <Route path="/sampling/library" element={<SamplingSearchPage customerType="LIBRARY"/>}/>
        <Route path="/sampling/:type/results" element={<SamplingResultsPage/>}/>
        <Route path="/sampling/:type/customer/:customerId" element={<SamplingDetailPage/>}/>
        <Route path="/self-stock" element={<SelfStockRequestPage/>}/>
        <Route path="/approvals" element={<ApprovalInboxPage/>}/>
        {Object.entries(approvalModules).map(([slug, module]) => <Route key={slug} path={`/approvals/${slug}`} element={<ApprovalInboxPage module={module}/>}/>)}
        <Route path="/approvals/:approvalId" element={<ApprovalDetailsPage/>}/>
        <Route path="/requests/my-history" element={<MyRequestHistoryPage/>}/>
        <Route path="/notifications" element={<NotificationsPage/>}/>
        <Route path="/attendance" element={<AttendancePage/>}/>
        <Route path="/e-products" element={<EProductsPage/>}/>
        <Route path="/settings" element={<SettingsPage/>}/>
        <Route element={<AdminOnly/>}>
          <Route path="/admin/users" element={<AdminUsersPage/>}/>
          <Route path="/admin/request-history" element={<AdminRequestHistoryPage/>}/>
        </Route>
        <Route path="*" element={<NotFoundPage/>}/>
      </Route>
    </Route>
    <Route path="*" element={<Navigate to="/login" replace/>}/>
  </Routes>;
}
