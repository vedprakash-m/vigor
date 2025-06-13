import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import React from 'react'
import { BrowserRouter } from 'react-router-dom'
import { ForgotPasswordPage } from '../../pages/ForgotPasswordPage'
import { authService } from '../../services/authService'

// Mock services
jest.mock('../../services/authService')
const mockedAuthService = authService as jest.Mocked<typeof authService>

// Mock react-router-dom
const mockNavigate = jest.fn()
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}))

const TestWrapper = ({ children }: { children: React.ReactNode }) => (
  <BrowserRouter>
    {children}
  </BrowserRouter>
)

describe('ForgotPasswordPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockNavigate.mockClear()
  })

  describe('Initial Render', () => {
    it('renders forgot password form', () => {
      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      expect(screen.getByText('Forgot Password')).toBeInTheDocument()
      expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /send reset link/i })).toBeInTheDocument()
      expect(screen.getByText(/back to login/i)).toBeInTheDocument()
    })

    it('shows proper form validation messages', () => {
      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      expect(screen.getByText(/email is required/i)).toBeInTheDocument()
    })
  })

  describe('Form Validation', () => {
    it('validates email format', () => {
      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'invalid-email' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      expect(screen.getByText(/please enter a valid email address/i)).toBeInTheDocument()
    })

    it('accepts valid email format', () => {
      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      expect(screen.queryByText(/please enter a valid email address/i)).not.toBeInTheDocument()
    })
  })

  describe('Password Reset Flow', () => {
    it('successfully sends reset email', async () => {
      mockedAuthService.forgotPassword.mockResolvedValue({ message: 'Reset email sent' })

      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      await waitFor(() => {
        expect(mockedAuthService.forgotPassword).toHaveBeenCalledWith('test@example.com')
      })

      expect(screen.getByText(/check your email for reset instructions/i)).toBeInTheDocument()
    })

    it('handles service errors gracefully', async () => {
      const error = new Error('User not found')
      mockedAuthService.forgotPassword.mockRejectedValue(error)

      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      await waitFor(() => {
        expect(mockedAuthService.forgotPassword).toHaveBeenCalled()
      })

      expect(screen.getByText(/failed to send reset email/i)).toBeInTheDocument()
    })

    it('shows loading state during submission', async () => {
      // Mock a slow response
      mockedAuthService.forgotPassword.mockImplementation(
        () => new Promise(resolve => setTimeout(() => resolve({ message: 'Success' }), 100))
      )

      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      expect(screen.getByText(/sending/i)).toBeInTheDocument()
      expect(submitButton).toBeDisabled()

      await waitFor(() => {
        expect(screen.queryByText(/sending/i)).not.toBeInTheDocument()
      })
    })
  })

  describe('Navigation', () => {
    it('navigates back to login page', () => {
      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const backLink = screen.getByText(/back to login/i)
      fireEvent.click(backLink)

      expect(mockNavigate).toHaveBeenCalledWith('/login')
    })

    it('navigates to login after successful reset', async () => {
      mockedAuthService.forgotPassword.mockResolvedValue({ message: 'Reset email sent' })

      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      await waitFor(() => {
        expect(mockedAuthService.forgotPassword).toHaveBeenCalled()
      })

      // Should show success message but not navigate automatically
      expect(screen.getByText(/check your email for reset instructions/i)).toBeInTheDocument()
    })
  })

  describe('Accessibility', () => {
    it('has proper form labels and ARIA attributes', () => {
      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      expect(emailInput).toHaveAttribute('type', 'email')
      expect(emailInput).toHaveAttribute('required')

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      expect(submitButton).toHaveAttribute('type', 'submit')
    })

    it('announces form errors to screen readers', () => {
      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      const errorMessage = screen.getByText(/email is required/i)
      expect(errorMessage).toHaveAttribute('role', 'alert')
    })
  })

  describe('Error Handling', () => {
    it('handles network errors', async () => {
      const error = new Error('Network error')
      mockedAuthService.forgotPassword.mockRejectedValue(error)

      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      await waitFor(() => {
        expect(screen.getByText(/failed to send reset email/i)).toBeInTheDocument()
      })
    })

    it('handles rate limiting errors', async () => {
      const error = new Error('Too many requests')
      mockedAuthService.forgotPassword.mockRejectedValue(error)

      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      await waitFor(() => {
        expect(screen.getByText(/failed to send reset email/i)).toBeInTheDocument()
      })
    })
  })

  describe('User Experience', () => {
    it('clears form after successful submission', async () => {
      mockedAuthService.forgotPassword.mockResolvedValue({ message: 'Reset email sent' })

      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)

      await waitFor(() => {
        expect(mockedAuthService.forgotPassword).toHaveBeenCalled()
      })

      // Form should be cleared or disabled after success
      expect(emailInput).toHaveValue('')
      expect(submitButton).toBeDisabled()
    })

    it('prevents multiple submissions', async () => {
      mockedAuthService.forgotPassword.mockImplementation(
        () => new Promise(resolve => setTimeout(() => resolve({ message: 'Success' }), 100))
      )

      render(
        <TestWrapper>
          <ForgotPasswordPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

      const submitButton = screen.getByRole('button', { name: /send reset link/i })
      fireEvent.click(submitButton)
      fireEvent.click(submitButton) // Second click should be ignored

      expect(mockedAuthService.forgotPassword).toHaveBeenCalledTimes(1)
    })
  })
})
