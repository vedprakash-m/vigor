import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import React from 'react'
import { BrowserRouter } from 'react-router-dom'
import { AuthProvider } from '../../contexts/AuthContext'
import DashboardPage from '../../pages/DashboardPage'
import { LoginPage } from '../../pages/LoginPage'
import { authService } from '../../services/authService'
import { workoutService } from '../../services/workoutService'

// Mock services
jest.mock('../../services/authService')
jest.mock('../../services/workoutService')
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => jest.fn(),
}))

const TestWrapper = ({ children }: { children: React.ReactNode }) => (
  <BrowserRouter>
    <AuthProvider>
      {children}
    </AuthProvider>
  </BrowserRouter>
)

describe('User Workflow Integration', () => {
  const mockUser = {
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    tier: 'premium',
    fitness_level: 'intermediate',
    goals: ['strength', 'endurance']
  }

  const mockWorkoutDays = ['2024-12-01', '2024-12-02', '2024-12-03']

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Authentication Workflow', () => {
    it('completes full registration and login flow', async () => {
      const mockRegister = jest.fn().mockResolvedValue({ user: mockUser })
      const mockLogin = jest.fn().mockResolvedValue({
        token: 'test-token',
        user: mockUser
      })
      ;(authService.register as jest.Mock).mockImplementation(mockRegister)
      ;(authService.login as jest.Mock).mockImplementation(mockLogin)

      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Navigate to register page
      const registerLink = screen.getByText(/don't have an account/i)
      fireEvent.click(registerLink)

      // Fill registration form
      fireEvent.change(screen.getByLabelText(/username/i), {
        target: { value: 'newuser' }
      })
      fireEvent.change(screen.getByLabelText(/email/i), {
        target: { value: 'new@example.com' }
      })
      fireEvent.change(screen.getByLabelText(/password/i), {
        target: { value: 'password123' }
      })
      fireEvent.change(screen.getByLabelText(/confirm password/i), {
        target: { value: 'password123' }
      })

      // Submit registration
      fireEvent.click(screen.getByRole('button', { name: /register/i }))

      await waitFor(() => {
        expect(mockRegister).toHaveBeenCalledWith({
          username: 'newuser',
          email: 'new@example.com',
          password: 'password123'
        })
      })
    })

    it('handles login and dashboard access', async () => {
      const mockLogin = jest.fn().mockResolvedValue({
        token: 'test-token',
        user: mockUser
      })
      ;(authService.login as jest.Mock).mockImplementation(mockLogin)
      ;(workoutService.getWorkoutDays as jest.Mock).mockResolvedValue(mockWorkoutDays)

      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Fill login form
      fireEvent.change(screen.getByLabelText(/email/i), {
        target: { value: 'test@example.com' }
      })
      fireEvent.change(screen.getByLabelText(/password/i), {
        target: { value: 'password123' }
      })

      // Submit login
      fireEvent.click(screen.getByRole('button', { name: /login/i }))

      await waitFor(() => {
        expect(mockLogin).toHaveBeenCalledWith({
          email: 'test@example.com',
          password: 'password123'
        })
      })
    })
  })

  describe('Dashboard Integration', () => {
    it('loads user data and workout information', async () => {
      ;(workoutService.getWorkoutDays as jest.Mock).mockResolvedValue(mockWorkoutDays)

      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // Verify dashboard loads with user data
      await waitFor(() => {
        expect(screen.getByText(/welcome back, testuser/i)).toBeInTheDocument()
        expect(screen.getByText(/intermediate/i)).toBeInTheDocument()
        expect(screen.getByText(/3 days/i)).toBeInTheDocument()
      })
    })

    it('handles authentication state changes', async () => {
      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // Should handle gracefully
      expect(screen.getByText(/welcome back/i)).toBeInTheDocument()
    })
  })

  describe('Error Handling Integration', () => {
    it('handles network errors gracefully', async () => {
      const mockLogin = jest.fn().mockRejectedValue(new Error('Network error'))
      ;(authService.login as jest.Mock).mockImplementation(mockLogin)

      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      fireEvent.change(screen.getByLabelText(/email/i), {
        target: { value: 'test@example.com' }
      })
      fireEvent.change(screen.getByLabelText(/password/i), {
        target: { value: 'password123' }
      })

      fireEvent.click(screen.getByRole('button', { name: /login/i }))

      await waitFor(() => {
        expect(screen.getByText(/network error/i)).toBeInTheDocument()
      })
    })

    it('handles service failures in dashboard', async () => {
      ;(workoutService.getWorkoutDays as jest.Mock).mockRejectedValue(
        new Error('Failed to fetch workout days')
      )

      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // Should still render the component even if service fails
      expect(screen.getByText(/welcome back/i)).toBeInTheDocument()
    })
  })

  describe('Data Flow Integration', () => {
    it('maintains data consistency across components', async () => {
      const mockLogin = jest.fn().mockResolvedValue({
        token: 'test-token',
        user: mockUser
      })
      ;(authService.login as jest.Mock).mockImplementation(mockLogin)
      ;(workoutService.getWorkoutDays as jest.Mock).mockResolvedValue(mockWorkoutDays)

      // Test that user data flows correctly from login to dashboard
      const { rerender } = render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Simulate successful login
      fireEvent.change(screen.getByLabelText(/email/i), {
        target: { value: 'test@example.com' }
      })
      fireEvent.change(screen.getByLabelText(/password/i), {
        target: { value: 'password123' }
      })

      fireEvent.click(screen.getByRole('button', { name: /login/i }))

      await waitFor(() => {
        expect(mockLogin).toHaveBeenCalled()
      })

      // Rerender with dashboard
      rerender(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // Verify data consistency
      await waitFor(() => {
        expect(screen.getByText(/welcome back, testuser/i)).toBeInTheDocument()
      })
    })
  })

  describe('Performance Integration', () => {
    it('handles multiple rapid interactions', async () => {
      const mockLogin = jest.fn().mockResolvedValue({
        token: 'test-token',
        user: mockUser
      })
      ;(authService.login as jest.Mock).mockImplementation(mockLogin)

      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Rapid form interactions
      const emailInput = screen.getByLabelText(/email/i)
      const passwordInput = screen.getByLabelText(/password/i)

      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })
      fireEvent.change(passwordInput, { target: { value: 'password123' } })
      fireEvent.change(emailInput, { target: { value: 'test2@example.com' } })
      fireEvent.change(passwordInput, { target: { value: 'password456' } })

      // Should handle rapid changes without errors
      expect(emailInput).toHaveValue('test2@example.com')
      expect(passwordInput).toHaveValue('password456')
    })
  })
})
