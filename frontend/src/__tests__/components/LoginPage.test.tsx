import { fireEvent, screen, waitFor } from '@testing-library/react'
import { LoginPage } from '../../pages/LoginPage'
import { authService } from '../../services/authService'
import { render } from '../../test-utils'

// Mock services
jest.mock('../../services/authService')

// Mock router
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => jest.fn(),
}))

describe('LoginPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders email & password fields and submit button', () => {
    render(<LoginPage />)

    expect(screen.getByPlaceholderText('Enter your email')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Enter your password')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument()
  })

  it('calls authService.login with provided credentials', async () => {
    const mockLogin = jest.fn().mockResolvedValue({})
    // @ts-expect-error - overriding mocked login type for test
    authService.login.mockImplementation(mockLogin)

    render(<LoginPage />)

    fireEvent.change(screen.getByPlaceholderText('Enter your email'), {
      target: { value: 'test@example.com' },
    })
    fireEvent.change(screen.getByPlaceholderText('Enter your password'), {
      target: { value: 'password123' },
    })

    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith('test@example.com', 'password123')
    })
  })

  it('shows error returned from authService.login', async () => {
    const mockLogin = jest.fn().mockRejectedValue({ response: { data: { detail: 'Invalid credentials' } } })
    // @ts-expect-error - overriding mocked login type for test
    authService.login.mockImplementation(mockLogin)

    render(<LoginPage />)

    fireEvent.change(screen.getByPlaceholderText('Enter your email'), {
      target: { value: 'test@example.com' },
    })
    fireEvent.change(screen.getByPlaceholderText('Enter your password'), {
      target: { value: 'password123' },
    })

    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(screen.getByText(/invalid credentials/i)).toBeInTheDocument()
    })
  })

  it('validates email format', async () => {
    render(<LoginPage />)

    fireEvent.change(screen.getByPlaceholderText('Enter your email'), {
      target: { value: 'invalid-email' }
    })
    fireEvent.change(screen.getByPlaceholderText('Enter your password'), {
      target: { value: 'password123' }
    })

    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(screen.getByText(/invalid email format/i)).toBeInTheDocument()
    })
  })

  it('shows loading state during login', async () => {
    const mockLogin = jest.fn().mockImplementation(
      () => new Promise(() => {}) // Never resolves
    )
    ;(authService.login as jest.Mock).mockImplementation(mockLogin)

    render(<LoginPage />)

    fireEvent.change(screen.getByPlaceholderText('Enter your email'), {
      target: { value: 'test@example.com' }
    })
    fireEvent.change(screen.getByPlaceholderText('Enter your password'), {
      target: { value: 'password123' }
    })
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(screen.getByText(/logging in/i)).toBeInTheDocument()
    })
  })

  it('navigates to register page when register link is clicked', () => {
    render(<LoginPage />)

    const registerLink = screen.getByText(/don't have an account/i)
    expect(registerLink).toBeInTheDocument()
    expect(registerLink.closest('a')).toHaveAttribute('href', '/register')
  })
})
