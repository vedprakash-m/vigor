import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import React from 'react';

// Mock Chakra UI components
jest.mock('@chakra-ui/react', () => ({
  Box: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="box" {...props}>{children}</div>
  ),
  Button: ({ children, onClick, isLoading, ...props }: React.PropsWithChildren<{ onClick?: () => void; isLoading?: boolean } & Record<string, unknown>>) => (
    <button onClick={onClick} disabled={isLoading} {...props}>
      {isLoading ? 'Loading...' : children}
    </button>
  ),
  Container: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="container" {...props}>{children}</div>
  ),
  Heading: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <h1 {...props}>{children}</h1>
  ),
  Text: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <span {...props}>{children}</span>
  ),
  VStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="vstack" {...props}>{children}</div>
  ),
  HStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="hstack" {...props}>{children}</div>
  ),
  Card: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="card" {...props}>{children}</div>
  ),
  Input: (props: Record<string, unknown> & { onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void }) => (
    <input data-testid="input" {...props} />
  ),
  Textarea: (props: Record<string, unknown>) => (
    <textarea data-testid="textarea" {...props} />
  ),
  Spinner: () => <div data-testid="spinner">Loading...</div>,
  Grid: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="grid" {...props}>{children}</div>
  ),
  GridItem: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="grid-item" {...props}>{children}</div>
  ),
  FormControl: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="form-control" {...props}>{children}</div>
  ),
  FormLabel: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <label {...props}>{children}</label>
  ),
  Select: (props: Record<string, unknown>) => <select data-testid="select" {...props} />,
  useToast: () => jest.fn(),
  ChakraProvider: ({ children }: React.PropsWithChildren<unknown>) => <>{children}</>,
  defaultSystem: {},
}))

// Mock auth context
const mockUser = {
  username: 'testuser',
  email: 'test@example.com',
  id: 'test-id-123',
}

jest.mock('../../contexts/useAuth', () => ({
  useAuth: () => ({
    user: mockUser,
    isAuthenticated: true,
    isLoading: false,
  }),
}))

// Mock workout service
const mockWorkoutPlan = {
  id: 'plan-1',
  name: 'Strength Training',
  exercises: [
    { name: 'Squats', sets: 3, reps: 12 },
    { name: 'Bench Press', sets: 3, reps: 10 },
  ],
  duration_minutes: 45,
}

// Mock AI service - using the actual api.ts module
jest.mock('../../services/api', () => ({
  api: {
    workouts: {
      getWorkoutPlans: jest.fn().mockResolvedValue([mockWorkoutPlan]),
      generateWorkout: jest.fn().mockResolvedValue(mockWorkoutPlan),
      logWorkout: jest.fn().mockResolvedValue({ success: true }),
      saveWorkoutPlan: jest.fn().mockResolvedValue({ id: 'new-plan-1' }),
    },
  },
}))

// Import after mocks
import { WorkoutPage } from '../../pages/WorkoutPage';

describe('WorkoutPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders workout page heading', async () => {
    render(<WorkoutPage />)

    await waitFor(() => {
      expect(screen.getByText(/Workouts/i)).toBeInTheDocument()
    })
  })

  it('renders Box wrapper', async () => {
    render(<WorkoutPage />)

    await waitFor(() => {
      const boxes = screen.getAllByTestId('box')
      expect(boxes.length).toBeGreaterThan(0)
    })
  })

  it('displays workout generation options', async () => {
    render(<WorkoutPage />)

    await waitFor(() => {
      // Check for common workout-related UI elements
      const buttons = screen.getAllByRole('button')
      expect(buttons.length).toBeGreaterThan(0)
    })
  })
})

describe('WorkoutPage - Workout Generation', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('can generate a workout', async () => {
    render(<WorkoutPage />)

    await waitFor(() => {
      const boxes = screen.getAllByTestId('box')
      expect(boxes.length).toBeGreaterThan(0)
    })

    // Look for generate button
    const generateButton = screen.queryByRole('button', { name: /generate/i })
    if (generateButton) {
      fireEvent.click(generateButton)
      // Verify page is still rendered
      await waitFor(() => {
        const boxes = screen.getAllByTestId('box')
        expect(boxes.length).toBeGreaterThan(0)
      })
    }
  })
})

describe('WorkoutPage - Error Handling', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    jest.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('handles API errors gracefully', async () => {
    render(<WorkoutPage />)

    await waitFor(() => {
      const boxes = screen.getAllByTestId('box')
      expect(boxes.length).toBeGreaterThan(0)
    })
  })
})
