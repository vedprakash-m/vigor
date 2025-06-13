import { fireEvent, render, screen } from '@testing-library/react'
import React from 'react'
import { ProfilePage } from '../../pages/ProfilePage'

// Mock Chakra UI components
jest.mock('@chakra-ui/react', () => ({
  Box: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  Button: ({ children, onClick, ...props }: React.PropsWithChildren<{ onClick?: () => void } & Record<string, unknown>>) => (
    <button onClick={onClick} {...props}>
      {children}
    </button>
  ),
  Heading: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <h1 {...props}>{children}</h1>,
  Text: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <span {...props}>{children}</span>,
  VStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
}))

// Mock console.log to verify it's called
const mockConsoleLog = jest.spyOn(console, 'log').mockImplementation(() => {})

describe('ProfilePage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  afterAll(() => {
    mockConsoleLog.mockRestore()
  })

  it('renders profile page with heading', () => {
    render(<ProfilePage />)

    expect(screen.getByText('Profile')).toBeInTheDocument()
    expect(screen.getByText('Your profile settings and preferences will appear here.')).toBeInTheDocument()
  })

  it('renders danger zone section', () => {
    render(<ProfilePage />)

    expect(screen.getByText('Danger Zone')).toBeInTheDocument()
    expect(screen.getByText(/Deleting your account will permanently remove your data/)).toBeInTheDocument()
  })

  it('renders delete account button', () => {
    render(<ProfilePage />)

    const deleteButton = screen.getByRole('button', { name: /delete account/i })
    expect(deleteButton).toBeInTheDocument()
  })

  it('handles delete account button click', () => {
    render(<ProfilePage />)

    const deleteButton = screen.getByRole('button', { name: /delete account/i })
    fireEvent.click(deleteButton)

    expect(mockConsoleLog).toHaveBeenCalledWith('Account scheduled for deletion - You have 14 days to undo via link in email.')
  })

  it('has proper heading hierarchy', () => {
    render(<ProfilePage />)

    const headings = screen.getAllByRole('heading')
    expect(headings[0]).toHaveTextContent('Profile')
    expect(headings[1]).toHaveTextContent('Danger Zone')
  })

  it('displays warning text about account deletion', () => {
    render(<ProfilePage />)

    const warningText = screen.getByText(/Deleting your account will permanently remove your data after a 14-day grace period/)
    expect(warningText).toBeInTheDocument()
  })
})
