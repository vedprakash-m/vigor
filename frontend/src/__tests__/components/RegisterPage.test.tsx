import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import React from 'react'
import { BrowserRouter } from 'react-router-dom'
import { RegisterPage } from '../../pages/RegisterPage'
import { authService } from '../../services/authService'

// Mock services
jest.mock('../../services/authService')
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => jest.fn(),
}))

const TestWrapper = ({ children }: { children: React.ReactNode }) => (
  <BrowserRouter>
    {children}
  </BrowserRouter>
)

describe('RegisterPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders registration form with all required fields', () => {
    render(
      <TestWrapper>
        <RegisterPage />
      </TestWrapper>
    )

    expect(screen.getByLabelText(/username/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/confirm password/i)).toBeInTheDocument()
  })

  it('validates password strength', async () => {
    render(
      <TestWrapper>
        <RegisterPage />
      </TestWrapper>
    )

    const passwordInput = screen.getByLabelText(/password/i)
    fireEvent.change(passwordInput, { target: { value: 'weak' } })

    await waitFor(() => {
      expect(screen.getByText(/password must be at least 8 characters/i)).toBeInTheDocument()
    })
  })

  it('validates password confirmation match', async () => {
    render(
      <TestWrapper>
        <RegisterPage />
      </TestWrapper>
    )

    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password123' }
    })
    fireEvent.change(screen.getByLabelText(/confirm password/i), {
      target: { value: 'differentpassword' }
    })

    await waitFor(() => {
      expect(screen.getByText(/passwords do not match/i)).toBeInTheDocument()
    })
  })

  it('handles successful registration', async () => {
    const mockRegister = jest.fn().mockResolvedValue({ user: { id: 1 } })
    ;(authService.register as jest.Mock).mockImplementation(mockRegister)

    render(
      <TestWrapper>
        <RegisterPage />
      </TestWrapper>
    )

    fireEvent.change(screen.getByLabelText(/username/i), {
      target: { value: 'testuser' }
    })
    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'test@example.com' }
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password123' }
    })
    fireEvent.change(screen.getByLabelText(/confirm password/i), {
      target: { value: 'password123' }
    })

    fireEvent.click(screen.getByRole('button', { name: /register/i }))

    await waitFor(() => {
      expect(mockRegister).toHaveBeenCalledWith({
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123'
      })
    })
  })

  it('displays error message on registration failure', async () => {
    const mockRegister = jest.fn().mockRejectedValue(new Error('Email already exists'))
    ;(authService.register as jest.Mock).mockImplementation(mockRegister)

    render(
      <TestWrapper>
        <RegisterPage />
      </TestWrapper>
    )

    fireEvent.change(screen.getByLabelText(/username/i), {
      target: { value: 'testuser' }
    })
    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'existing@example.com' }
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password123' }
    })
    fireEvent.change(screen.getByLabelText(/confirm password/i), {
      target: { value: 'password123' }
    })

    fireEvent.click(screen.getByRole('button', { name: /register/i }))

    await waitFor(() => {
      expect(screen.getByText(/email already exists/i)).toBeInTheDocument()
    })
  })

  it('validates email format', async () => {
    render(
      <TestWrapper>
        <RegisterPage />
      </TestWrapper>
    )

    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'invalid-email' }
    })

    await waitFor(() => {
      expect(screen.getByText(/invalid email format/i)).toBeInTheDocument()
    })
  })

  it('validates username length', async () => {
    render(
      <TestWrapper>
        <RegisterPage />
      </TestWrapper>
    )

    fireEvent.change(screen.getByLabelText(/username/i), {
      target: { value: 'ab' }
    })

    await waitFor(() => {
      expect(screen.getByText(/username must be at least 3 characters/i)).toBeInTheDocument()
    })
  })

  it('shows loading state during registration', async () => {
    const mockRegister = jest.fn().mockImplementation(
      () => new Promise(() => {}) // Never resolves
    )
    ;(authService.register as jest.Mock).mockImplementation(mockRegister)

    render(
      <TestWrapper>
        <RegisterPage />
      </TestWrapper>
    )

    fireEvent.change(screen.getByLabelText(/username/i), {
      target: { value: 'testuser' }
    })
    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'test@example.com' }
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password123' }
    })
    fireEvent.change(screen.getByLabelText(/confirm password/i), {
      target: { value: 'password123' }
    })

    fireEvent.click(screen.getByRole('button', { name: /register/i }))

    await waitFor(() => {
      expect(screen.getByText(/creating account/i)).toBeInTheDocument()
    })
  })

  it('navigates to login page when login link is clicked', () => {
    render(
      <TestWrapper>
        <RegisterPage />
      </TestWrapper>
    )

    const loginLink = screen.getByText(/already have an account/i)
    expect(loginLink).toBeInTheDocument()
    expect(loginLink.closest('a')).toHaveAttribute('href', '/login')
  })
})
