import { fireEvent, render, screen } from '@testing-library/react'
import React from 'react'
import { MemoryRouter } from 'react-router-dom'

// Mock MSAL
jest.mock('@azure/msal-react', () => ({
  useMsal: () => ({
    instance: { loginRedirect: jest.fn() },
    accounts: [],
  }),
  MsalProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

// Mock navigate
const mockNavigate = jest.fn()
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}))

// Mock Auth context
const mockLogin = jest.fn()
jest.mock('../../contexts/useAuth', () => ({
  useAuth: () => ({
    login: mockLogin,
    isAuthenticated: false,
    isLoading: false,
    error: null,
  }),
}))

// Mock Chakra UI
jest.mock('@chakra-ui/react', () => ({
  Box: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  Button: ({ children, onClick, ...props }: React.PropsWithChildren<{ onClick?: () => void }>) => (
    <button onClick={onClick} {...props}>{children}</button>
  ),
  Flex: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  Heading: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <h1 {...props}>{children}</h1>,
  Icon: () => <span data-testid="icon" />,
  Text: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <span {...props}>{children}</span>,
  VStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
}))

import { LoginPage } from '../../pages/LoginPage'

describe('LoginPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders welcome heading and sign in button', () => {
    render(
      <MemoryRouter>
        <LoginPage />
      </MemoryRouter>
    )
    expect(screen.getByText('Welcome to Vigor')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sign in with microsoft/i })).toBeInTheDocument()
  })

  it('calls login when sign in button is clicked', async () => {
    render(
      <MemoryRouter>
        <LoginPage />
      </MemoryRouter>
    )

    const signInButton = screen.getByRole('button', { name: /sign in with microsoft/i })
    fireEvent.click(signInButton)

    expect(mockLogin).toHaveBeenCalled()
  })

  it('shows description text', () => {
    render(
      <MemoryRouter>
        <LoginPage />
      </MemoryRouter>
    )
    expect(screen.getByText(/sign in with your microsoft account/i)).toBeInTheDocument()
  })
})
