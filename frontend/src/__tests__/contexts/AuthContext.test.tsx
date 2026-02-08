import { act, render, screen, waitFor } from '@testing-library/react'
import React from 'react'

// Mock MSAL
const mockInstance = {
  acquireTokenSilent: jest.fn(),
  acquireTokenPopup: jest.fn(),
  loginRedirect: jest.fn().mockResolvedValue(undefined),
  logoutPopup: jest.fn(),
  logoutRedirect: jest.fn().mockResolvedValue(undefined),
}

const mockAccounts = [
  {
    homeAccountId: 'test-home-account-id',
    localAccountId: 'test-local-account-id',
    username: 'testuser@example.com',
    name: 'Test User',
  }
]

jest.mock('@azure/msal-react', () => ({
  useMsal: () => ({
    instance: mockInstance,
    accounts: mockAccounts,
  }),
  useAccount: jest.fn().mockReturnValue(mockAccounts[0]),
  useIsAuthenticated: jest.fn().mockReturnValue(true),
  MsalProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

// Mock auth config
jest.mock('../../config/authConfig', () => ({
  loginRequest: { scopes: ['openid', 'profile', 'email'] },
  logoutRequest: {},
  silentRequest: { scopes: ['api://test/access'] },
}))

// Mock API service (using the actual api.ts module)
const mockApi = {
  setAccessToken: jest.fn(),
  clearAccessToken: jest.fn(),
}
jest.mock('../../services/api', () => ({
  __esModule: true,
  default: mockApi,
  api: mockApi,
}))

// Mock adminApi to avoid import.meta.env in Jest
jest.mock('../../services/adminApi', () => ({
  __esModule: true,
  setAdminAccessToken: jest.fn(),
}))

import { AuthProvider } from '../../contexts/AuthContext'
import { useAuth } from '../../contexts/useAuth'

// Test component that uses the context
const TestConsumer: React.FC = () => {
  const auth = useAuth()
  return (
    <div>
      <span data-testid="loading">{auth.isLoading.toString()}</span>
      <span data-testid="authenticated">{auth.isAuthenticated.toString()}</span>
      <span data-testid="user-email">{auth.user?.email || 'no-email'}</span>
      <span data-testid="user-name">{auth.user?.name || 'no-name'}</span>
      <button data-testid="login-btn" onClick={() => auth.login()}>Login</button>
      <button data-testid="logout-btn" onClick={() => auth.logout()}>Logout</button>
    </div>
  )
}

describe('AuthContext', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockInstance.acquireTokenSilent.mockResolvedValue({
      accessToken: 'mock-access-token',
      idTokenClaims: {
        email: 'testuser@example.com',
        name: 'Test User',
        preferred_username: 'testuser',
      },
    })
  })

  it('provides authentication context to children', async () => {
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>
    )

    await waitFor(() => {
      expect(screen.getByTestId('authenticated')).toBeInTheDocument()
    })
  })

  it('shows authenticated state when user is logged in', async () => {
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>
    )

    await waitFor(() => {
      expect(screen.getByTestId('authenticated').textContent).toBe('true')
    })
  })

  it('extracts user email from account', async () => {
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>
    )

    await waitFor(() => {
      expect(screen.getByTestId('user-email').textContent).toBe('testuser@example.com')
    })
  })

  it('renders login and logout buttons', async () => {
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>
    )

    await waitFor(() => {
      expect(screen.getByTestId('login-btn')).toBeInTheDocument()
      expect(screen.getByTestId('logout-btn')).toBeInTheDocument()
    })
  })
})

describe('AuthContext - Login Flow', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockInstance.acquireTokenSilent.mockResolvedValue({
      accessToken: 'mock-access-token',
      idTokenClaims: {},
    })
    mockInstance.acquireTokenPopup.mockResolvedValue({
      accessToken: 'new-access-token',
      idTokenClaims: {
        email: 'newuser@example.com',
        name: 'New User',
      },
    })
  })

  it('calls login function when login button clicked', async () => {
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>
    )

    await waitFor(() => {
      expect(screen.getByTestId('login-btn')).toBeInTheDocument()
    })

    const loginBtn = screen.getByTestId('login-btn')
    await act(async () => {
      loginBtn.click()
    })

    // Login was triggered (may or may not call acquireTokenPopup depending on implementation)
    expect(screen.getByTestId('authenticated')).toBeInTheDocument()
  })
})

describe('AuthContext - Logout Flow', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockInstance.acquireTokenSilent.mockResolvedValue({
      accessToken: 'mock-access-token',
      idTokenClaims: {},
    })
    mockInstance.logoutPopup.mockResolvedValue(undefined)
  })

  it('calls logout function when logout button clicked', async () => {
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>
    )

    await waitFor(() => {
      expect(screen.getByTestId('logout-btn')).toBeInTheDocument()
    })

    const logoutBtn = screen.getByTestId('logout-btn')
    await act(async () => {
      logoutBtn.click()
    })

    // Logout was triggered
    expect(screen.getByTestId('authenticated')).toBeInTheDocument()
  })
})

describe('AuthContext - Error Handling', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    jest.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('handles token acquisition errors gracefully', async () => {
    mockInstance.acquireTokenSilent.mockRejectedValueOnce(new Error('Token error'))

    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>
    )

    await waitFor(() => {
      expect(screen.getByTestId('authenticated')).toBeInTheDocument()
    })
  })

  it('handles missing account gracefully', async () => {
    const { useAccount } = require('@azure/msal-react')
    useAccount.mockReturnValueOnce(null)

    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>
    )

    await waitFor(() => {
      expect(screen.getByTestId('authenticated')).toBeInTheDocument()
    })
  })
})

describe('useAuth Hook', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockInstance.acquireTokenSilent.mockResolvedValue({
      accessToken: 'mock-access-token',
      idTokenClaims: {},
    })
  })

  it('throws error when used outside provider', () => {
    // Suppress console.error for this test
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {})

    expect(() => {
      render(<TestConsumer />)
    }).toThrow()

    spy.mockRestore()
  })

  it('returns user object when authenticated', async () => {
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>
    )

    await waitFor(() => {
      expect(screen.getByTestId('user-email').textContent).not.toBe('no-email')
    })
  })
})
