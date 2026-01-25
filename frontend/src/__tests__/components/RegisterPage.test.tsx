import { fireEvent, render, screen } from '@testing-library/react'
import React from 'react'
import { MemoryRouter } from 'react-router-dom'

// Mock MSAL
const mockLoginPopup = jest.fn()
jest.mock('@azure/msal-react', () => ({
  useMsal: () => ({
    instance: { loginPopup: mockLoginPopup },
    accounts: [],
  }),
  MsalProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

// Mock auth config
jest.mock('../../config/authConfig', () => ({
  loginRequest: { scopes: ['openid', 'profile', 'email'] },
}))

// Mock navigate
const mockNavigate = jest.fn()
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}))

// Mock Chakra UI
jest.mock('@chakra-ui/react', () => ({
  Box: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  Button: ({ children, onClick, ...props }: React.PropsWithChildren<{ onClick?: () => void }>) => (
    <button onClick={onClick} {...props}>{children}</button>
  ),
  Center: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  Text: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <span {...props}>{children}</span>,
  VStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
}))

import { RegisterPage } from '../../pages/RegisterPage'

describe('RegisterPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders join heading and sign up button', () => {
    render(
      <MemoryRouter>
        <RegisterPage />
      </MemoryRouter>
    )
    expect(screen.getByText('Join Vigor')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sign up with microsoft/i })).toBeInTheDocument()
  })

  it('calls MSAL loginPopup when sign up button is clicked', async () => {
    mockLoginPopup.mockResolvedValue({})

    render(
      <MemoryRouter>
        <RegisterPage />
      </MemoryRouter>
    )

    const signUpButton = screen.getByRole('button', { name: /sign up with microsoft/i })
    fireEvent.click(signUpButton)

    expect(mockLoginPopup).toHaveBeenCalled()
  })

  it('shows description text about Microsoft Entra ID', () => {
    render(
      <MemoryRouter>
        <RegisterPage />
      </MemoryRouter>
    )
    expect(screen.getByText(/microsoft entra id/i)).toBeInTheDocument()
  })
})
