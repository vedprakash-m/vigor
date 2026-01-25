import { PublicClientApplication } from '@azure/msal-browser'
import { MsalProvider } from '@azure/msal-react'
import { ChakraProvider, defaultSystem } from '@chakra-ui/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Route, BrowserRouter as Router, Routes, useParams } from 'react-router-dom'
import { AccessibilityProvider } from './components/AccessibilityFeatures'
import AdminAuditSecurity from './components/AdminAuditSecurity'
import AnalyticsDashboard from './components/AnalyticsDashboard'
import BulkUserOperations from './components/BulkUserOperations'
import CommunityFeatures from './components/CommunityFeatures'
import EnhancedProgressVisualization from './components/EnhancedProgressVisualization'
import ErrorBoundary from './components/ErrorBoundary'
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
import { AuthProvider } from './contexts/AuthContext'
import AdminPage from './pages/AdminPage'
import { CoachPage } from './pages/CoachPage'
import DashboardPage from './pages/DashboardPage'
import { ForgotPasswordPage } from './pages/ForgotPasswordPage'
import { LandingPage } from './pages/LandingPage'
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
    <ErrorBoundary>
      <ChakraProvider value={defaultSystem}>
        <QueryClientProvider client={queryClient}>
          <AccessibilityProvider>
            <MsalProvider instance={msalInstance}>
              <AuthProvider>
                <Router>
                  <PWAInstallPrompt />
                  <Routes>
                  {/* Public routes */}
                  <Route path="/" element={<LandingPage />} />
                  <Route path="/login" element={<LoginPage />} />
                  <Route path="/register" element={<RegisterPage />} />
                  <Route path="/forgot-password" element={<ForgotPasswordPage />} />
                  <Route path="/reset-password" element={<ResetPasswordPage />} />
                  <Route path="/onboarding" element={<OnboardingPage />} />
                  <Route path="/oauth/callback/:provider" element={<OAuthCallbackWrapper />} />

                  {/* Protected routes - under /app */}
                  <Route path="/app" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<PersonalizedDashboardPage />} />
                    <Route path="dashboard" element={<PersonalizedDashboardPage />} />
                    <Route path="analytics" element={<AnalyticsDashboard />} />
                    <Route path="progress" element={<EnhancedProgressVisualization />} />
                    <Route path="community" element={<CommunityFeatures />} />
                    <Route path="social" element={<SocialFeatures />} />
                    <Route path="premium" element={<PremiumFeatures />} />
                    <Route path="workouts" element={<WorkoutPage />} />
                    <Route path="coach" element={<CoachPage />} />
                    <Route path="profile" element={<ProfilePage />} />
                    <Route path="tiers" element={<TierManagementPage />} />
                  </Route>

                  {/* Legacy routes for backward compatibility */}
                  <Route path="/dashboard" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<DashboardPage />} />
                  </Route>
                  <Route path="/workouts" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<WorkoutPage />} />
                  </Route>
                  <Route path="/coach" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<CoachPage />} />
                  </Route>
                  <Route path="/profile" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<ProfilePage />} />
                  </Route>

                  {/* Admin routes */}
                  <Route path="/admin" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<AdminPage />} />
                    <Route path="llm-health" element={<LLMHealthMonitoring />} />
                    <Route path="users" element={<UserManagement />} />
                    <Route path="llm-config" element={<LLMConfigurationManagement />} />
                    <Route path="analytics" element={<LLMAnalyticsSimple />} />
                    <Route path="audit" element={<AdminAuditSecurity />} />
                    <Route path="bulk-ops" element={<BulkUserOperations />} />
                  </Route>
                  <Route path="/llm" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<LLMOrchestrationPage />} />
                  </Route>
                </Routes>
              </Router>
            </AuthProvider>
          </MsalProvider>
        </AccessibilityProvider>
      </QueryClientProvider>
    </ChakraProvider>
    </ErrorBoundary>
  )
}

export default App
