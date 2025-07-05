import { screen } from '@testing-library/react';
import DashboardPage from '../../pages/DashboardPage';
import { render } from '../../test-utils';

// Mock the services that DashboardPage uses
jest.mock('../../services/workoutService', () => ({
  workoutService: {
    getWorkoutDays: jest.fn().mockResolvedValue([]),
  },
}));

jest.mock('../../services/gamificationService', () => ({
  gamificationService: {
    getUserStats: jest.fn().mockResolvedValue({
      level: 1,
      totalPoints: 50,
      aiInteractions: 5,
    }),
  },
}));

describe('DashboardPage', () => {
  it('renders welcome message', () => {
    render(<DashboardPage />);

    // Check that the welcome message is present
    expect(screen.getByText(/Welcome back/i)).toBeInTheDocument();
  });

  it('renders action buttons', () => {
    render(<DashboardPage />);

    expect(screen.getByText('Generate Workout')).toBeInTheDocument();
    expect(screen.getByText('Chat with Coach')).toBeInTheDocument();
  });

  it('renders basic dashboard structure', () => {
    render(<DashboardPage />);

    // This ensures the component renders without crashing
    expect(screen.getByText(/Welcome back/i)).toBeInTheDocument();
  });
});
