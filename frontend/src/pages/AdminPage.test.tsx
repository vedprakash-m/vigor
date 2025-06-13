import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { adminService } from '../services/adminService'
import { authService } from '../services/authService'
import AdminPage from './AdminPage'

// Mock the services
jest.mock('../services/authService')
jest.mock('../services/adminService')
const mockAuthService = authService as jest.Mocked<typeof authService>
const mockAdminService = adminService as jest.Mocked<typeof adminService>

describe('AdminPage', () => {
  const mockAdminUser = {
    id: 'admin123',
    username: 'adminuser',
    email: 'admin@example.com',
    name: 'Admin User',
    is_active: true,
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z'
  }

  const mockRegularUser = {
    id: 'user123',
    username: 'regularuser',
    email: 'user@example.com',
    name: 'Regular User',
    is_active: true,
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z'
  }

  const mockPricing = {
    'openai-gpt-4': 0.03,
    'gemini-flash-2.5': 0.01,
    'perplexity-sonar': 0.005
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('shows loading state initially', () => {
    mockAuthService.getCurrentUser.mockImplementation(() => new Promise(() => {}))

    render(<AdminPage />)

    expect(screen.getByText('Checking admin access...')).toBeInTheDocument()
  })

  it('grants access to admin users', async () => {
    mockAuthService.getCurrentUser.mockResolvedValue(mockAdminUser)
    mockAdminService.getProviderPricing.mockResolvedValue(mockPricing)

    render(<AdminPage />)

    await waitFor(() => {
      expect(screen.getByText('Admin Dashboard')).toBeInTheDocument()
    })

    expect(screen.getByText('AI Providers')).toBeInTheDocument()
    expect(screen.getByText('Budget Settings')).toBeInTheDocument()
    expect(screen.getByText('Usage Analytics')).toBeInTheDocument()
  })

  it('denies access to non-admin users', async () => {
    mockAuthService.getCurrentUser.mockResolvedValue(mockRegularUser)

    render(<AdminPage />)

    await waitFor(() => {
      expect(screen.getByText('Access Denied')).toBeInTheDocument()
      expect(screen.getByText(/You need admin privileges to access this page/)).toBeInTheDocument()
    })
  })

  it('shows error when auth service fails', async () => {
    mockAuthService.getCurrentUser.mockRejectedValue(new Error('Auth failed'))

    render(<AdminPage />)

    await waitFor(() => {
      expect(screen.getByText('Access Denied')).toBeInTheDocument()
    })
  })

  it('switches between tabs', async () => {
    mockAuthService.getCurrentUser.mockResolvedValue(mockAdminUser)
    mockAdminService.getProviderPricing.mockResolvedValue(mockPricing)

    render(<AdminPage />)

    await waitFor(() => {
      expect(screen.getByText('Admin Dashboard')).toBeInTheDocument()
    })

    // Initially shows AI Providers tab
    expect(screen.getByText('AI Provider Management')).toBeInTheDocument()

    // Switch to Budget Settings tab
    const budgetTab = screen.getByText('Budget Settings')
    fireEvent.click(budgetTab)

    // Should show budget settings content
    expect(screen.getByText('Budget Management')).toBeInTheDocument()

    // Switch to Usage Analytics tab
    const analyticsTab = screen.getByText('Usage Analytics')
    fireEvent.click(analyticsTab)

    // Should show analytics content
    expect(screen.getByText('Usage Analytics Dashboard')).toBeInTheDocument()
  })

  it('displays provider validation button', async () => {
    mockAuthService.getCurrentUser.mockResolvedValue(mockAdminUser)
    mockAdminService.getProviderPricing.mockResolvedValue(mockPricing)

    render(<AdminPage />)

    await waitFor(() => {
      expect(screen.getByText('Validate Provider Credentials')).toBeInTheDocument()
    })
  })

  it('handles provider validation', async () => {
    const mockAlert = jest.spyOn(window, 'alert').mockImplementation(() => {})

    mockAuthService.getCurrentUser.mockResolvedValue(mockAdminUser)
    mockAdminService.getProviderPricing.mockResolvedValue(mockPricing)
    mockAdminService.validateProvider.mockResolvedValue({ status: 'valid' })

    render(<AdminPage />)

    await waitFor(() => {
      const validateButton = screen.getByText('Validate Provider Credentials')
      fireEvent.click(validateButton)
    })

    expect(mockAdminService.validateProvider).toHaveBeenCalledWith('gemini-flash-2.5', 'demo_key')
    expect(mockAlert).toHaveBeenCalledWith('Validation result: valid')

    mockAlert.mockRestore()
  })

  it('shows provider pricing information', async () => {
    mockAuthService.getCurrentUser.mockResolvedValue(mockAdminUser)
    mockAdminService.getProviderPricing.mockResolvedValue(mockPricing)

    render(<AdminPage />)

    await waitFor(() => {
      expect(screen.getByText('AI Provider Management')).toBeInTheDocument()
    })

    expect(mockAdminService.getProviderPricing).toHaveBeenCalled()
  })

  it('handles provider pricing error gracefully', async () => {
    mockAuthService.getCurrentUser.mockResolvedValue(mockAdminUser)
    mockAdminService.getProviderPricing.mockRejectedValue(new Error('Failed to fetch pricing'))

    render(<AdminPage />)

    await waitFor(() => {
      expect(screen.getByText('Admin Dashboard')).toBeInTheDocument()
    })

    // Should still render without crashing
    expect(screen.getByText('AI Provider Management')).toBeInTheDocument()
  })

  it('shows admin user information in console', async () => {
    const consoleSpy = jest.spyOn(console, 'warn').mockImplementation(() => {})

    mockAuthService.getCurrentUser.mockResolvedValue(mockRegularUser)

    render(<AdminPage />)

    await waitFor(() => {
      expect(consoleSpy).toHaveBeenCalledWith('Admin access denied for user:', 'regularuser')
    })

    consoleSpy.mockRestore()
  })

  it('handles validation error', async () => {
    const mockAlert = jest.spyOn(window, 'alert').mockImplementation(() => {})

    mockAuthService.getCurrentUser.mockResolvedValue(mockAdminUser)
    mockAdminService.getProviderPricing.mockResolvedValue(mockPricing)
    mockAdminService.validateProvider.mockRejectedValue(new Error('Validation failed'))

    render(<AdminPage />)

    await waitFor(() => {
      const validateButton = screen.getByText('Validate Provider Credentials')
      fireEvent.click(validateButton)
    })

    expect(mockAlert).toHaveBeenCalledWith('Validation result: undefined')

    mockAlert.mockRestore()
  })
})
