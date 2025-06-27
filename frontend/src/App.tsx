import { ChakraProvider, defaultSystem } from '@chakra-ui/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Route, BrowserRouter as Router, Routes, useParams } from 'react-router-dom'
import AnalyticsDashboard from './components/AnalyticsDashboard'
import { Layout } from './components/Layout'
import { OAuthCallback } from './components/OAuthCallback'
import PWAInstallPrompt from './components/PWAInstallPrompt'
import { ProtectedRoute } from './components/ProtectedRoute'
import SocialFeatures from './components/SocialFeatures'
import { AuthProvider } from './contexts/AuthContext'
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
    <ChakraProvider value={defaultSystem}>
      <QueryClientProvider client={queryClient}>
        <Router>
          <AuthProvider>
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
                <Route path="/app/community" element={<SocialFeatures />} />
                <Route path="/workouts" element={<WorkoutPage />} />
                <Route path="/app/workouts" element={<WorkoutPage />} />
                <Route path="/coach" element={<CoachPage />} />
                <Route path="/app/coach" element={<CoachPage />} />
                <Route path="/profile" element={<ProfilePage />} />
                <Route path="/app/profile" element={<ProfilePage />} />
                <Route path="/tiers" element={<TierManagementPage />} />
                <Route path="/admin" element={<AdminPage />} />
                <Route path="/llm" element={<LLMOrchestrationPage />} />
              </Route>
            </Routes>
          </AuthProvider>
        </Router>
      </QueryClientProvider>
    </ChakraProvider>
  )
}

export default App
