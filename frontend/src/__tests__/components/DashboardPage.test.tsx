import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import React from 'react'
import { BrowserRouter } from 'react-router-dom'
import { useAuth } from '../../contexts/useAuth'
import DashboardPage from '../../pages/DashboardPage'
import { workoutService } from '../../services/workoutService'

// Mock services and contexts
jest.mock('../../contexts/useAuth')
jest.mock('../../services/workoutService')
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => jest.fn(),
}))

const TestWrapper = ({ children }: { children: React.ReactNode }) => (
  <BrowserRouter>
    {children}
  </BrowserRouter>
)

describe('DashboardPage', () => {
  const mockUser = {
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    tier: 'premium',
    fitness_level: 'intermediate',
    goals: ['strength', 'endurance']
  }

  const mockWorkoutDays = ['2024-12-01', '2024-12-02', '2024-12-03']

  beforeEach(() => {
    jest.clearAllMocks()
    ;(useAuth as jest.Mock).mockReturnValue({
      user: mockUser,
      isAuthenticated: true,
      logout: jest.fn()
    })
    ;(workoutService.getWorkoutDays as jest.Mock).mockResolvedValue(mockWorkoutDays)
  })

  it('renders user welcome message', () => {
    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )
    expect(screen.getByText(/welcome back, testuser/i)).toBeInTheDocument()
  })

  it('displays user fitness level', () => {
    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )
    expect(screen.getByText(/intermediate/i)).toBeInTheDocument()
  })

  it('loads and displays streak information', async () => {
    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )

    await waitFor(() => {
      expect(screen.getByText(/3 days/i)).toBeInTheDocument()
    })
  })

  it('shows AI coach section', () => {
    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )
    expect(screen.getByText(/ask your coach/i)).toBeInTheDocument()
  })

  it('handles loading state', () => {
    ;(workoutService.getWorkoutDays as jest.Mock).mockImplementation(
      () => new Promise(() => {}) // Never resolves
    )

    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )
    // Component should render without crashing during loading
    expect(screen.getByText(/welcome back, testuser/i)).toBeInTheDocument()
  })

  it('handles error state gracefully', async () => {
    ;(workoutService.getWorkoutDays as jest.Mock).mockRejectedValue(
      new Error('Failed to fetch workout days')
    )

    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )

    // Should still render the component even if streak fetch fails
    expect(screen.getByText(/welcome back, testuser/i)).toBeInTheDocument()
  })

  it('displays workout statistics', () => {
    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )
    expect(screen.getByText(/workouts this week/i)).toBeInTheDocument()
    expect(screen.getByText(/total workouts/i)).toBeInTheDocument()
    expect(screen.getByText(/current streak/i)).toBeInTheDocument()
  })

  it('shows quick actions section', () => {
    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )
    expect(screen.getByText(/quick actions/i)).toBeInTheDocument()
    expect(screen.getByText(/ready to start your fitness journey/i)).toBeInTheDocument()
  })

  it('navigates to coach page when AI coach section is clicked', () => {
    const mockLocation = { href: '' }
    Object.defineProperty(window, 'location', {
      value: mockLocation,
      writable: true
    })

    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )

    const coachSection = screen.getByText(/ask your coach/i)
    fireEvent.click(coachSection)

    expect(mockLocation.href).toBe('/coach')
  })

  it('shows default values when user data is missing', () => {
    ;(useAuth as jest.Mock).mockReturnValue({
      user: { ...mockUser, fitness_level: undefined },
      isAuthenticated: true,
      logout: jest.fn()
    })

    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )

    expect(screen.getByText(/not set/i)).toBeInTheDocument()
  })

  it('displays dashboard overview text', () => {
    render(
      <TestWrapper>
        <DashboardPage />
      </TestWrapper>
    )
    expect(screen.getByText(/here's your fitness dashboard overview/i)).toBeInTheDocument()
  })
})
