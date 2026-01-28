import { PublicClientApplication } from '@azure/msal-browser'
import { MsalProvider } from '@azure/msal-react'
import { ChakraProvider, defaultSystem } from '@chakra-ui/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Route, BrowserRouter as Router, Routes, useParams } from 'react-router-dom'
import AdminAuditSecurity from './components/AdminAuditSecurity'
import AnalyticsDashboard from './components/AnalyticsDashboard'
import BulkUserOperations from './components/BulkUserOperations'
import ErrorBoundary from './components/ErrorBoundary'
import { Layout } from './components/Layout'
import LLMAnalyticsSimple from './components/LLMAnalyticsSimple'
import LLMConfigurationManagement from './components/LLMConfigurationSimple'
import LLMHealthMonitoring from './components/LLMHealthMonitoring'
import { OAuthCallback } from './components/OAuthCallback'
import { ProtectedRoute } from './components/ProtectedRoute'
import UserManagement from './components/UserManagement'
import { msalConfig } from './config/authConfig'
import { AuthProvider } from './contexts/AuthContext'
import AdminPage from './pages/AdminPage'
import { ForgotPasswordPage } from './pages/ForgotPasswordPage'
import LLMOrchestrationPage from './pages/LLMOrchestrationPage'
import { LoginPage } from './pages/LoginPage'
import { ResetPasswordPage } from './pages/ResetPasswordPage'
import TierManagementPage from './pages/TierManagementPage'
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
          <MsalProvider instance={msalInstance}>
            <AuthProvider>
              <Router>
                <Routes>
                  {/* Public routes */}
                  <Route path="/" element={<LoginPage />} />
                  <Route path="/login" element={<LoginPage />} />
                  <Route path="/forgot-password" element={<ForgotPasswordPage />} />
                  <Route path="/reset-password" element={<ResetPasswordPage />} />
                  <Route path="/oauth/callback/:provider" element={<OAuthCallbackWrapper />} />

                  {/* Admin Dashboard routes */}
                  <Route path="/admin" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<AdminPage />} />
                    <Route path="llm-health" element={<LLMHealthMonitoring />} />
                    <Route path="users" element={<UserManagement />} />
                    <Route path="llm-config" element={<LLMConfigurationManagement />} />
                    <Route path="analytics" element={<LLMAnalyticsSimple />} />
                    <Route path="system-analytics" element={<AnalyticsDashboard />} />
                    <Route path="audit" element={<AdminAuditSecurity />} />
                    <Route path="bulk-ops" element={<BulkUserOperations />} />
                    <Route path="tiers" element={<TierManagementPage />} />
                  </Route>
                  <Route path="/llm" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                    <Route index element={<LLMOrchestrationPage />} />
                  </Route>
                </Routes>
              </Router>
            </AuthProvider>
          </MsalProvider>
        </QueryClientProvider>
      </ChakraProvider>
    </ErrorBoundary>
  )
}

export default App
