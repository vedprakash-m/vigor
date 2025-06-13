import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import React from 'react'
import { BrowserRouter } from 'react-router-dom'
import { AuthContext, AuthProvider } from '../../contexts/AuthContext'
import { authService } from '../../services/authService'
import type { AuthResponse, User } from '../../types/auth'

// Mock services
jest.mock('../../services/authService')
const mockedAuthService = authService as jest.Mocked<typeof authService>

// Mock react-router-dom
const mockNavigate = jest.fn()
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}))

// Mock localStorage
const localStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
  length: 0,
  key: jest.fn(),
}
Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
  writable: true,
})

// Test component to access context
const TestComponent = () => {
  const { user, isAuthenticated, isLoading, login, logout, register } = React.useContext(AuthContext)!

  return (
    <div>
      <div data-testid="user">{user ? user.username : 'no-user'}</div>
      <div data-testid="authenticated">{isAuthenticated ? 'true' : 'false'}</div>
      <div data-testid="loading">{isLoading ? 'true' : 'false'}</div>
      <button onClick={() => login('test@example.com', 'password')} data-testid="login-btn">
        Login
      </button>
      <button onClick={() => logout()} data-testid="logout-btn">
        Logout
      </button>
      <button onClick={() => register('test@example.com', 'testuser', 'password')} data-testid="register-btn">
        Register
      </button>
    </div>
  )
}

const TestWrapper = ({ children }: { children: React.ReactNode }) => (
  <BrowserRouter>
    <AuthProvider>
      {children}
    </AuthProvider>
  </BrowserRouter>
)

// Helper function to create mock user
const createMockUser = (overrides: Partial<User> = {}): User => ({
  id: '1',
  username: 'testuser',
  email: 'test@example.com',
  name: 'Test User',
  is_active: true,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
  ...overrides,
})

// Helper function to create mock auth response
const createMockAuthResponse = (user: User): AuthResponse => ({
  user,
  access_token: 'access-token',
  refresh_token: 'refresh-token',
  token_type: 'bearer',
})

describe('AuthContext', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    localStorageMock.getItem.mockReturnValue(null)
    mockNavigate.mockClear()
  })

  describe('Initial State', () => {
    it('starts with loading state and no authenticated user', async () => {
      // Mock getCurrentUser to throw when no token
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('No token'))

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      // Initially loading
      expect(screen.getByTestId('loading')).toHaveTextContent('true')
      expect(screen.getByTestId('user')).toHaveTextContent('no-user')
      expect(screen.getByTestId('authenticated')).toHaveTextContent('false')

      // After loading completes
      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })
    })

    it('loads user from token on mount', async () => {
      const mockUser = createMockUser()
      localStorageMock.getItem.mockReturnValue('valid-token')
      mockedAuthService.getCurrentUser.mockResolvedValue(mockUser)

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })

      expect(screen.getByTestId('user')).toHaveTextContent('testuser')
      expect(screen.getByTestId('authenticated')).toHaveTextContent('true')
      expect(mockedAuthService.getCurrentUser).toHaveBeenCalled()
    })

    it('handles getCurrentUser failure gracefully', async () => {
      localStorageMock.getItem.mockReturnValue('invalid-token')
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('Invalid token'))

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })

      expect(screen.getByTestId('user')).toHaveTextContent('no-user')
      expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
      expect(localStorageMock.removeItem).toHaveBeenCalledWith('accessToken')
      expect(localStorageMock.removeItem).toHaveBeenCalledWith('refreshToken')
    })
  })

  describe('Login Functionality', () => {
    it('successfully logs in user', async () => {
      const mockUser = createMockUser()
      const mockResponse = createMockAuthResponse(mockUser)
      mockedAuthService.login.mockResolvedValue(mockResponse)

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })

      fireEvent.click(screen.getByTestId('login-btn'))

      await waitFor(() => {
        expect(mockedAuthService.login).toHaveBeenCalledWith('test@example.com', 'password')
      })

      await waitFor(() => {
        expect(screen.getByTestId('user')).toHaveTextContent('testuser')
        expect(screen.getByTestId('authenticated')).toHaveTextContent('true')
      })

      expect(localStorageMock.setItem).toHaveBeenCalledWith('accessToken', 'access-token')
      expect(localStorageMock.setItem).toHaveBeenCalledWith('refreshToken', 'refresh-token')
      expect(mockNavigate).toHaveBeenCalledWith('/')
    })

    it('handles login failure', async () => {
      const error = new Error('Invalid credentials')
      mockedAuthService.login.mockRejectedValue(error)

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })

      fireEvent.click(screen.getByTestId('login-btn'))

      await waitFor(() => {
        expect(mockedAuthService.login).toHaveBeenCalled()
      })

      // Should remain unauthenticated
      expect(screen.getByTestId('user')).toHaveTextContent('no-user')
      expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
    })
  })

  describe('Logout Functionality', () => {
    it('successfully logs out user', async () => {
      // Start with authenticated user
      const mockUser = createMockUser()
      localStorageMock.getItem.mockReturnValue('valid-token')
      mockedAuthService.getCurrentUser.mockResolvedValue(mockUser)

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })

      // Verify user is authenticated
      expect(screen.getByTestId('user')).toHaveTextContent('testuser')
      expect(screen.getByTestId('authenticated')).toHaveTextContent('true')

      // Logout
      fireEvent.click(screen.getByTestId('logout-btn'))

      await waitFor(() => {
        expect(screen.getByTestId('user')).toHaveTextContent('no-user')
        expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
      })

      expect(localStorageMock.removeItem).toHaveBeenCalledWith('accessToken')
      expect(localStorageMock.removeItem).toHaveBeenCalledWith('refreshToken')
      expect(mockNavigate).toHaveBeenCalledWith('/login')
    })
  })

  describe('Register Functionality', () => {
    it('successfully registers user', async () => {
      const mockUser = createMockUser({ username: 'newuser', email: 'new@example.com' })
      const mockResponse = createMockAuthResponse(mockUser)
      mockedAuthService.register.mockResolvedValue(mockResponse)

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })

      fireEvent.click(screen.getByTestId('register-btn'))

      await waitFor(() => {
        expect(mockedAuthService.register).toHaveBeenCalledWith('test@example.com', 'testuser', 'password')
      })

      await waitFor(() => {
        expect(screen.getByTestId('user')).toHaveTextContent('newuser')
        expect(screen.getByTestId('authenticated')).toHaveTextContent('true')
      })

      expect(localStorageMock.setItem).toHaveBeenCalledWith('accessToken', 'access-token')
      expect(localStorageMock.setItem).toHaveBeenCalledWith('refreshToken', 'refresh-token')
      expect(mockNavigate).toHaveBeenCalledWith('/')
    })

    it('handles registration failure', async () => {
      const error = new Error('Email already exists')
      mockedAuthService.register.mockRejectedValue(error)

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })

      fireEvent.click(screen.getByTestId('register-btn'))

      await waitFor(() => {
        expect(mockedAuthService.register).toHaveBeenCalled()
      })

      // Should remain unauthenticated
      expect(screen.getByTestId('user')).toHaveTextContent('no-user')
      expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
    })
  })

  describe('Error Handling', () => {
    it('handles service errors gracefully', async () => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      const error = new Error('Service unavailable')
      mockedAuthService.login.mockRejectedValue(error)

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })

      fireEvent.click(screen.getByTestId('login-btn'))

      await waitFor(() => {
        expect(mockedAuthService.login).toHaveBeenCalled()
      })

      expect(screen.getByTestId('user')).toHaveTextContent('no-user')
      expect(screen.getByTestId('authenticated')).toHaveTextContent('false')

      consoleSpy.mockRestore()
    })

    it('handles localStorage errors', () => {
      localStorageMock.setItem.mockImplementation(() => {
        throw new Error('Storage quota exceeded')
      })

      const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      // Should not crash the application
      expect(screen.getByTestId('user')).toHaveTextContent('no-user')
      expect(screen.getByTestId('authenticated')).toHaveTextContent('false')

      consoleSpy.mockRestore()
    })
  })

  describe('Context Provider', () => {
    it('provides auth context to children', async () => {
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('No token'))

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      expect(screen.getByTestId('user')).toBeInTheDocument()
      expect(screen.getByTestId('authenticated')).toBeInTheDocument()
      expect(screen.getByTestId('loading')).toBeInTheDocument()
      expect(screen.getByTestId('login-btn')).toBeInTheDocument()
      expect(screen.getByTestId('logout-btn')).toBeInTheDocument()
      expect(screen.getByTestId('register-btn')).toBeInTheDocument()

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })
    })
  })

  describe('Loading States', () => {
    it('shows loading state during authentication check', () => {
      // Mock a slow getCurrentUser call
      mockedAuthService.getCurrentUser.mockImplementation(
        () => new Promise((_, reject) => setTimeout(() => reject(new Error('No token')), 100))
      )

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      expect(screen.getByTestId('loading')).toHaveTextContent('true')
    })

    it('hides loading state after authentication check completes', async () => {
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('No token'))

      render(
        <TestWrapper>
          <TestComponent />
        </TestWrapper>
      )

      await waitFor(() => {
        expect(screen.getByTestId('loading')).toHaveTextContent('false')
      })
    })
  })
})
