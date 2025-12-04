import { render, screen, waitFor } from '@testing-library/react'
import React from 'react'

// Mock Chakra UI components
jest.mock('@chakra-ui/react', () => ({
  Box: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="box" {...props}>{children}</div>
  ),
  Button: ({ children, onClick, ...props }: React.PropsWithChildren<{ onClick?: () => void } & Record<string, unknown>>) => (
    <button onClick={onClick} {...props}>{children}</button>
  ),
  Container: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="container" {...props}>{children}</div>
  ),
  Grid: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="grid" {...props}>{children}</div>
  ),
  Heading: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <h1 {...props}>{children}</h1>
  ),
  HStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="hstack" {...props}>{children}</div>
  ),
  Text: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <span {...props}>{children}</span>
  ),
  VStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="vstack" {...props}>{children}</div>
  ),
  SimpleGrid: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="simple-grid" {...props}>{children}</div>
  ),
  Flex: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="flex" {...props}>{children}</div>
  ),
  Center: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="center" {...props}>{children}</div>
  ),
  Spinner: (props: Record<string, unknown>) => <div data-testid="spinner" {...props}>Loading...</div>,
}))

// Mock auth context
const mockUser = {
  username: 'testuser',
  email: 'test@example.com',
  id: 'test-id-123',
}

jest.mock('../../contexts/useVedAuth', () => ({
  useVedAuth: () => ({
    user: mockUser,
    isAuthenticated: true,
    isLoading: false,
  }),
}))

// Mock gamification components
jest.mock('../../components/GamificationComponentsV2', () => ({
  BadgeGrid: () => <div data-testid="badge-grid">Badge Grid</div>,
  QuickStats: ({ level, totalPoints }: { level: number; totalPoints: number }) => (
    <div data-testid="quick-stats">
      Level: {level}, Points: {totalPoints}
    </div>
  ),
  StreakDisplay: ({ streak, title }: { streak: { current: number; longest: number }; title: string }) => (
    <div data-testid="streak-display">
      {title}: {streak.current} (Best: {streak.longest})
    </div>
  ),
}))

// Mock LLM Status
jest.mock('../../components/LLMStatus', () => () => (
  <div data-testid="llm-status">LLM Status Component</div>
))

// Mock services
const mockGamificationStats = {
  level: 5,
  totalPoints: 450,
  streaks: { daily: { current: 3, longest: 5 }, weekly: { current: 2, longest: 4 }, monthly: { current: 1, longest: 2 } },
  achievements: [],
  aiInteractions: 10,
  badges: [],
  weeklyConsistency: 75,
  workoutCount: 25,
  equipmentTypesUsed: ['dumbbells', 'bodyweight'],
}

jest.mock('../../services/gamificationService', () => ({
  gamificationService: {
    getUserStats: jest.fn().mockResolvedValue(mockGamificationStats),
    getMotivationalMessage: jest.fn().mockReturnValue("Keep up the great work!"),
  },
}))

jest.mock('../../services/workoutService', () => ({
  workoutService: {
    getWorkoutDays: jest.fn().mockResolvedValue(['2024-01-01', '2024-01-02', '2024-01-03']),
  },
}))

jest.mock('../../utils/streak', () => ({
  computeStreakUtc: jest.fn().mockReturnValue(3),
}))

// Import after mocks
import DashboardPage from '../../pages/DashboardPage'

describe('DashboardPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders dashboard with welcome message', async () => {
    render(<DashboardPage />)

    await waitFor(() => {
      expect(screen.getByText(/Welcome back/)).toBeInTheDocument()
    })
  })

  it('displays user username in welcome message', async () => {
    render(<DashboardPage />)

    await waitFor(() => {
      expect(screen.getByText(/testuser/)).toBeInTheDocument()
    })
  })

  it('renders LLM status component', async () => {
    render(<DashboardPage />)

    await waitFor(() => {
      expect(screen.getByTestId('llm-status')).toBeInTheDocument()
    })
  })

  it('displays gamification stats when loaded', async () => {
    render(<DashboardPage />)

    await waitFor(() => {
      expect(screen.getByTestId('quick-stats')).toBeInTheDocument()
    })
  })

  it('displays streak display components', async () => {
    render(<DashboardPage />)

    await waitFor(() => {
      const streakDisplays = screen.getAllByTestId('streak-display')
      expect(streakDisplays.length).toBeGreaterThan(0)
    })
  })

  it('shows workout statistics', async () => {
    render(<DashboardPage />)

    await waitFor(() => {
      expect(screen.getByText(/Workouts This Week/)).toBeInTheDocument()
      expect(screen.getByText(/Total Workouts/)).toBeInTheDocument()
    })
  })

  it('displays current streak section', async () => {
    render(<DashboardPage />)

    await waitFor(() => {
      expect(screen.getByText(/Current Streak/)).toBeInTheDocument()
    })
  })

  it('handles empty workout data gracefully', async () => {
    const { workoutService } = require('../../services/workoutService')
    workoutService.getWorkoutDays.mockResolvedValueOnce([])

    render(<DashboardPage />)

    await waitFor(() => {
      expect(screen.getByText(/Welcome back/)).toBeInTheDocument()
    })
  })
})

describe('DashboardPage - Error Handling', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    jest.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('handles service errors gracefully', async () => {
    const { workoutService } = require('../../services/workoutService')
    workoutService.getWorkoutDays.mockRejectedValueOnce(new Error('Network error'))

    render(<DashboardPage />)

    await waitFor(() => {
      expect(screen.getByText(/Welcome back/)).toBeInTheDocument()
    })

    expect(console.error).toHaveBeenCalled()
  })

  it('handles gamification service error', async () => {
    const { gamificationService } = require('../../services/gamificationService')
    gamificationService.getUserStats.mockRejectedValueOnce(new Error('Service unavailable'))

    render(<DashboardPage />)

    await waitFor(() => {
      expect(screen.getByText(/Welcome back/)).toBeInTheDocument()
    })
  })
})
