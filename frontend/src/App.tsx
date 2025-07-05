import { PublicClientApplication } from '@azure/msal-browser'
import { MsalProvider } from '@azure/msal-react'
import { ChakraProvider, defaultSystem } from '@chakra-ui/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Route, BrowserRouter as Router, Routes, useParams } from 'react-router-dom'
import { AccessibilityProvider } from './components/AccessibilityFeatures'
import AdminAuditSecurity from './components/AdminAuditSecurity'
import AnalyticsDashboard from './components/AnalyticsDashboard-temp'
import BulkUserOperations from './components/BulkUserOperations'
import CommunityFeatures from './components/CommunityFeatures-temp'
import EnhancedProgressVisualization from './components/EnhancedProgressVisualization'
import { Layout } from './components/Layout'
import LLMAnalyticsSimple from './components/LLMAnalyticsSimple'
import LLMConfigurationManagement from './components/LLMConfigurationSimple'
import LLMHealthMonitoring from './components/LLMHealthMonitoring'
import { OAuthCallback } from './components/OAuthCallback'
import PremiumFeatures from './components/PremiumFeatures'
import { ProtectedRoute } from './components/ProtectedRoute'
import PWAInstallPrompt from './components/PWAInstallPrompt'
import SocialFeatures from './components/SocialFeatures'
import UserManagement from './components/UserManagement'
import { msalConfig } from './config/authConfig'
import { VedAuthProvider } from './contexts/VedAuthContext'
import AdminPage from './pages/AdminPage'
import { CoachPage } from './pages/CoachPage'
import DashboardPage from './pages/DashboardPage'
import { ForgotPasswordPage } from './pages/ForgotPasswordPage'
import LLMOrchestrationPage from './pages/LLMOrchestrationPage'
import { LoginPage } from './pages/LoginPage'
import { OnboardingPage } from './pages/OnboardingPage'
import PersonalizedDashboardPage from './pages/PersonalizedDashboardPage'
import { ProfilePage } from './pages/ProfilePage'
import { RegisterPage } from './pages/RegisterPage'
import { ResetPasswordPage } from './pages/ResetPasswordPage'
import TierManagementPage from './pages/TierManagementPage'
import { WorkoutPage } from './pages/WorkoutPage'
// Import the animations CSS
import './styles/animations.css'

// Wrapper component to extract provider from URL params
const OAuthCallbackWrapper = () => {
  const { provider } = useParams<{ provider: string }>()
  return <OAuthCallback provider={provider || ''} />
}

// Initialize MSAL instance
const msalInstance = new PublicClientApplication(msalConfig);

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
})

function App() {
  return (
    <ChakraProvider value={defaultSystem}>
      <QueryClientProvider client={queryClient}>
        <AccessibilityProvider>
          <MsalProvider instance={msalInstance}>
            <VedAuthProvider>
              <Router>
                <PWAInstallPrompt />
                <Routes>
                  {/* Public routes */}
                  <Route path="/login" element={<LoginPage />} />
                  <Route path="/register" element={<RegisterPage />} />
                  <Route path="/forgot-password" element={<ForgotPasswordPage />} />
                  <Route path="/reset-password" element={<ResetPasswordPage />} />
                  <Route path="/onboarding" element={<OnboardingPage />} />
                  <Route path="/oauth/callback/:provider" element={<OAuthCallbackWrapper />} />

                  {/* Protected routes */}
                  <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<PersonalizedDashboardPage />} />
                    <Route path="/dashboard" element={<DashboardPage />} />
                    <Route path="/app/dashboard" element={<PersonalizedDashboardPage />} />
                    <Route path="/app/analytics" element={<AnalyticsDashboard />} />
                    <Route path="/app/progress" element={<EnhancedProgressVisualization />} />
                    <Route path="/app/community" element={<CommunityFeatures />} />
                    <Route path="/app/social" element={<SocialFeatures />} />
                    <Route path="/app/premium" element={<PremiumFeatures />} />
                    <Route path="/workouts" element={<WorkoutPage />} />
                    <Route path="/app/workouts" element={<WorkoutPage />} />
                    <Route path="/coach" element={<CoachPage />} />
                    <Route path="/app/coach" element={<CoachPage />} />
                    <Route path="/profile" element={<ProfilePage />} />
                    <Route path="/app/profile" element={<ProfilePage />} />
                    <Route path="/tiers" element={<TierManagementPage />} />
                    <Route path="/admin" element={<AdminPage />} />
                    <Route path="/admin/llm-health" element={<LLMHealthMonitoring />} />
                    <Route path="/admin/users" element={<UserManagement />} />
                    <Route path="/admin/llm-config" element={<LLMConfigurationManagement />} />
                    <Route path="/admin/analytics" element={<LLMAnalyticsSimple />} />
                    <Route path="/admin/audit" element={<AdminAuditSecurity />} />
                    <Route path="/admin/bulk-ops" element={<BulkUserOperations />} />
                    <Route path="/llm" element={<LLMOrchestrationPage />} />
                  </Route>
                </Routes>
              </Router>
            </VedAuthProvider>
          </MsalProvider>
        </AccessibilityProvider>
      </QueryClientProvider>
    </ChakraProvider>
  )
}

export default App
