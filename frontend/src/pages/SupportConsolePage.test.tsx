import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { supportService } from '../services/supportService'
import { SupportConsolePage } from './SupportConsolePage'

// Mock the support service
jest.mock('../services/supportService')
const mockSupportService = supportService as jest.Mocked<typeof supportService>

describe('SupportConsolePage', () => {
  const mockUser = {
    id: 'user123',
    username: 'testuser',
    email: 'test@example.com',
    user_tier: 'premium'
  }

  const mockLogs = [
    {
      id: 'log1',
      completed_at: '2024-12-15T10:00:00Z',
      duration_minutes: 45,
      exercises: [
        { name: 'Push-ups', sets: 3, reps: 10 },
        { name: 'Squats', sets: 3, reps: 15 }
      ]
    },
    {
      id: 'log2',
      completed_at: '2024-12-14T09:30:00Z',
      duration_minutes: 30,
      exercises: [
        { name: 'Pull-ups', sets: 3, reps: 8 }
      ]
    }
  ]

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders support console page', () => {
    render(<SupportConsolePage />)

    expect(screen.getByText('Support Console')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Search user email')).toBeInTheDocument()
    expect(screen.getByText('Search')).toBeInTheDocument()
  })

  it('searches for user successfully', async () => {
    mockSupportService.searchUser.mockResolvedValue(mockUser)
    mockSupportService.getUserLogs.mockResolvedValue(mockLogs)

    render(<SupportConsolePage />)

    const emailInput = screen.getByPlaceholderText('Search user email')
    const searchButton = screen.getByText('Search')

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } })
    fireEvent.click(searchButton)

    await waitFor(() => {
      expect(screen.getByText('testuser (test@example.com)')).toBeInTheDocument()
      expect(screen.getByText('Tier: premium')).toBeInTheDocument()
    })

    expect(mockSupportService.searchUser).toHaveBeenCalledWith('test@example.com')
    expect(mockSupportService.getUserLogs).toHaveBeenCalledWith('user123')
  })

  it('shows error when user not found', async () => {
    mockSupportService.searchUser.mockRejectedValue(new Error('User not found'))

    render(<SupportConsolePage />)

    const emailInput = screen.getByPlaceholderText('Search user email')
    const searchButton = screen.getByText('Search')

    fireEvent.change(emailInput, { target: { value: 'nonexistent@example.com' } })
    fireEvent.click(searchButton)

    await waitFor(() => {
      expect(screen.getByText('User not found')).toBeInTheDocument()
    })
  })

  it('displays user workout logs', async () => {
    mockSupportService.searchUser.mockResolvedValue(mockUser)
    mockSupportService.getUserLogs.mockResolvedValue(mockLogs)

    render(<SupportConsolePage />)

    const emailInput = screen.getByPlaceholderText('Search user email')
    const searchButton = screen.getByText('Search')

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } })
    fireEvent.click(searchButton)

    await waitFor(() => {
      expect(screen.getByText('User Workout Logs')).toBeInTheDocument()
      expect(screen.getByText('Date')).toBeInTheDocument()
      expect(screen.getByText('Duration')).toBeInTheDocument()
      expect(screen.getByText('Exercises')).toBeInTheDocument()
    })

    // Check log entries
    expect(screen.getByText('12/15/2024')).toBeInTheDocument()
    expect(screen.getByText('45m')).toBeInTheDocument()
    expect(screen.getByText('2')).toBeInTheDocument() // 2 exercises in first log
    expect(screen.getByText('12/14/2024')).toBeInTheDocument()
    expect(screen.getByText('30m')).toBeInTheDocument()
    expect(screen.getByText('1')).toBeInTheDocument() // 1 exercise in second log
  })

  it('shows export CSV button when user is found', async () => {
    mockSupportService.searchUser.mockResolvedValue(mockUser)
    mockSupportService.getUserLogs.mockResolvedValue(mockLogs)

    render(<SupportConsolePage />)

    const emailInput = screen.getByPlaceholderText('Search user email')
    const searchButton = screen.getByText('Search')

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } })
    fireEvent.click(searchButton)

    await waitFor(() => {
      expect(screen.getByText('Export CSV')).toBeInTheDocument()
    })
  })

  it('shows quick replies section when user is found', async () => {
    mockSupportService.searchUser.mockResolvedValue(mockUser)
    mockSupportService.getUserLogs.mockResolvedValue(mockLogs)

    render(<SupportConsolePage />)

    const emailInput = screen.getByPlaceholderText('Search user email')
    const searchButton = screen.getByText('Search')

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } })
    fireEvent.click(searchButton)

    await waitFor(() => {
      expect(screen.getByText('Send Reply to User')).toBeInTheDocument()
      expect(screen.getByText('Quick Reply Templates')).toBeInTheDocument()
      expect(screen.getByPlaceholderText('Type your reply or select a template above...')).toBeInTheDocument()
    })
  })

  it('handles quick reply selection', async () => {
    mockSupportService.searchUser.mockResolvedValue(mockUser)
    mockSupportService.getUserLogs.mockResolvedValue(mockLogs)

    render(<SupportConsolePage />)

    const emailInput = screen.getByPlaceholderText('Search user email')
    const searchButton = screen.getByText('Search')

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } })
    fireEvent.click(searchButton)

    await waitFor(() => {
      const welcomeButton = screen.getByText('Welcome Message')
      fireEvent.click(welcomeButton)
    })

    const textarea = screen.getByPlaceholderText('Type your reply or select a template above...')
    expect(textarea).toHaveValue('Welcome to Vigor! I\'m here to help you with your fitness journey. How can I assist you today?')
  })

  it('handles send reply functionality', async () => {
    const mockAlert = jest.spyOn(window, 'alert').mockImplementation(() => {})

    mockSupportService.searchUser.mockResolvedValue(mockUser)
    mockSupportService.getUserLogs.mockResolvedValue(mockLogs)

    render(<SupportConsolePage />)

    const emailInput = screen.getByPlaceholderText('Search user email')
    const searchButton = screen.getByText('Search')

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } })
    fireEvent.click(searchButton)

    await waitFor(() => {
      const textarea = screen.getByPlaceholderText('Type your reply or select a template above...')
      const sendButton = screen.getByText('Send Reply')

      fireEvent.change(textarea, { target: { value: 'Test reply message' } })
      fireEvent.click(sendButton)
    })

    expect(mockAlert).toHaveBeenCalledWith('Reply sent to test@example.com: Test reply message')
    mockAlert.mockRestore()
  })

  it('clears reply text when clear button is clicked', async () => {
    mockSupportService.searchUser.mockResolvedValue(mockUser)
    mockSupportService.getUserLogs.mockResolvedValue(mockLogs)

    render(<SupportConsolePage />)

    const emailInput = screen.getByPlaceholderText('Search user email')
    const searchButton = screen.getByText('Search')

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } })
    fireEvent.click(searchButton)

    await waitFor(() => {
      const textarea = screen.getByPlaceholderText('Type your reply or select a template above...')
      const clearButton = screen.getByText('Clear')

      fireEvent.change(textarea, { target: { value: 'Test message' } })
      expect(textarea).toHaveValue('Test message')

      fireEvent.click(clearButton)
      expect(textarea).toHaveValue('')
    })
  })
})
