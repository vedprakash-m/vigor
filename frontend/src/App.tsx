import { MsalProvider } from '@azure/msal-react'
import { ChakraProvider, defaultSystem, Spinner } from '@chakra-ui/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { lazy, Suspense } from 'react'
import { Navigate, Route, BrowserRouter as Router, Routes, useParams } from 'react-router-dom'
import { AdminProtectedRoute } from './components/AdminProtectedRoute'
import ErrorBoundary from './components/ErrorBoundary'
import { Layout } from './components/Layout'
import { OAuthCallback } from './components/OAuthCallback'
import { msalInstance } from './config/msalInstance'
import { AuthProvider } from './contexts/AuthContext'
// Import the animations CSS
import './styles/animations.css'

// Task 7.2.3: Lazy-load page components for code splitting
const AdminPage = lazy(() => import('./pages/AdminPage'))
const LoginPage = lazy(() => import('./pages/LoginPage').then(m => ({ default: m.LoginPage })))
const TierManagementPage = lazy(() => import('./pages/TierManagementPage'))
const AdminAuditSecurity = lazy(() => import('./components/AdminAuditSecurity'))
const AnalyticsDashboard = lazy(() => import('./components/AnalyticsDashboard'))
const BulkUserOperations = lazy(() => import('./components/BulkUserOperations'))
const LLMAnalyticsSimple = lazy(() => import('./components/LLMAnalyticsSimple'))
const LLMConfigurationManagement = lazy(() => import('./components/LLMConfigurationSimple'))
const LLMHealthMonitoring = lazy(() => import('./components/LLMHealthMonitoring'))
const UserManagement = lazy(() => import('./components/UserManagement'))

// Wrapper component to extract provider from URL params
const OAuthCallbackWrapper = () => {
  const { provider } = useParams<{ provider: string }>()
  return <OAuthCallback provider={provider || ''} />
}

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
                <Suspense fallback={<Spinner size="xl" />}>
                  <Routes>
                    {/* Public routes */}
                    <Route path="/" element={<Navigate to="/admin" replace />} />
                    <Route path="/login" element={<LoginPage />} />
                    <Route path="/oauth/callback/:provider" element={<OAuthCallbackWrapper />} />

                    {/* Admin Dashboard routes - Admin access required */}
                    <Route path="/admin" element={<AdminProtectedRoute><Layout /></AdminProtectedRoute>}>
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
                  </Routes>
                </Suspense>
              </Router>
            </AuthProvider>
          </MsalProvider>
        </QueryClientProvider>
      </ChakraProvider>
    </ErrorBoundary>
  )
}

export default App
