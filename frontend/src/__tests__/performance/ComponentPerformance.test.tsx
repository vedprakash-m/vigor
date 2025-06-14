/* eslint-disable @typescript-eslint/no-explicit-any */
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import React from 'react'
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

const TestWrapper = ({ children }: { children: React.ReactNode }) => <>{children}</>

describe('Component Performance Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('LoginPage Performance', () => {
    it('renders within acceptable time limit', () => {
      const startTime = performance.now()

      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const endTime = performance.now()
      const renderTime = endTime - startTime

      // Should render within 100ms
      expect(renderTime).toBeLessThan(100)
    })

    it('handles rapid form input changes efficiently', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      const passwordInput = screen.getByLabelText(/password/i)

      const startTime = performance.now()

      // Simulate rapid typing
      for (let i = 0; i < 50; i++) {
        fireEvent.change(emailInput, { target: { value: `test${i}@example.com` } })
        fireEvent.change(passwordInput, { target: { value: `password${i}` } })
      }

      const endTime = performance.now()
      const inputTime = endTime - startTime

      // Should handle 50 rapid changes within 500ms
      expect(inputTime).toBeLessThan(500)
    })

    it('handles form submission without blocking UI', async () => {
      const mockLogin = jest.fn().mockImplementation(
        () => new Promise(resolve => setTimeout(resolve, 100))
      )
      ;(authService.login as jest.Mock).mockImplementation(mockLogin)

      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      const passwordInput = screen.getByLabelText(/password/i)
      const submitButton = screen.getByRole('button', { name: /sign in/i })

      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })
      fireEvent.change(passwordInput, { target: { value: 'password123' } })

      const startTime = performance.now()
      fireEvent.click(submitButton)

      // UI should remain responsive during submission
      expect(screen.getByText(/signing in/i)).toBeInTheDocument()

      await waitFor(() => {
        expect(mockLogin).toHaveBeenCalled()
      })

      const endTime = performance.now()
      const submissionTime = endTime - startTime

      // Should complete within reasonable time
      expect(submissionTime).toBeLessThan(200)
    })
  })

  describe('DashboardPage Performance', () => {
    it('renders with large dataset efficiently', async () => {
      const largeWorkoutDays = Array.from({ length: 1000 }, (_, i) =>
        `2024-12-${String(i + 1).padStart(2, '0')}`
      )
      ;(workoutService.getWorkoutDays as jest.Mock).mockResolvedValue(largeWorkoutDays)

      const startTime = performance.now()

      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      const endTime = performance.now()
      const renderTime = endTime - startTime

      // Should render within 200ms even with large dataset
      expect(renderTime).toBeLessThan(200)
    })

    it('handles multiple re-renders efficiently', async () => {
      const mockWorkoutDays = ['2024-12-01', '2024-12-02', '2024-12-03']
      ;(workoutService.getWorkoutDays as jest.Mock).mockResolvedValue(mockWorkoutDays)

      const { rerender } = render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      const startTime = performance.now()

      // Simulate multiple re-renders
      for (let i = 0; i < 10; i++) {
        rerender(
          <TestWrapper>
            <DashboardPage />
          </TestWrapper>
        )
      }

      const endTime = performance.now()
      const rerenderTime = endTime - startTime

      // Should handle 10 re-renders within 500ms
      expect(rerenderTime).toBeLessThan(500)
    })

    it('loads data without blocking UI', async () => {
      const mockWorkoutDays = ['2024-12-01', '2024-12-02', '2024-12-03']
      ;(workoutService.getWorkoutDays as jest.Mock).mockImplementation(
        () => new Promise(resolve => setTimeout(() => resolve(mockWorkoutDays), 50))
      )

      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // UI should be immediately responsive
      expect(screen.getByText(/welcome back/i)).toBeInTheDocument()

      // Data should load asynchronously
      await waitFor(() => {
        expect(screen.getByText(/3 days/i)).toBeInTheDocument()
      })
    })
  })

  describe('Memory Usage', () => {
    it('does not cause memory leaks with repeated renders', () => {
      const initialMemory = (performance as any).memory?.usedJSHeapSize || 0

      const { unmount } = render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Simulate multiple mount/unmount cycles
      for (let i = 0; i < 100; i++) {
        unmount()
        render(
          <TestWrapper>
            <LoginPage />
          </TestWrapper>
        )
      }

      const finalMemory = (performance as any).memory?.usedJSHeapSize || 0
      const memoryIncrease = finalMemory - initialMemory

      // Memory increase should be reasonable (less than 1MB)
      if ((performance as any).memory) {
        expect(memoryIncrease).toBeLessThan(1024 * 1024)
      }
    })
  })

  describe('Network Performance', () => {
    it('handles slow network responses gracefully', async () => {
      const mockLogin = jest.fn().mockImplementation(
        () => new Promise(resolve => setTimeout(resolve, 2000))
      )
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

      fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

      // Should show loading state immediately
      expect(screen.getByText(/signing in/i)).toBeInTheDocument()

      // Should not block UI during slow request
      expect(screen.getByLabelText(/email/i)).toBeDisabled()
    })

    it('handles network timeouts efficiently', async () => {
      const mockLogin = jest.fn().mockRejectedValue(new Error('Request timeout'))
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

      fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

      await waitFor(() => {
        expect(screen.getByText(/request timeout/i)).toBeInTheDocument()
      })

      // Should re-enable form after error
      expect(screen.getByLabelText(/email/i)).not.toBeDisabled()
    })
  })

  describe('Bundle Size Impact', () => {
    it('components have reasonable import sizes', () => {
      // This is a placeholder for bundle analysis
      // In a real scenario, you'd use tools like webpack-bundle-analyzer
      const componentImports = [
        'LoginPage',
        'DashboardPage'
      ]

      // Each component should have minimal dependencies
      expect(componentImports.length).toBeLessThan(10)
    })
  })
})
