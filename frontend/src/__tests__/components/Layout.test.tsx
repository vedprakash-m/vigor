import { render, screen } from '@testing-library/react';
import { Layout } from '../../components/Layout';

describe('Layout', () => {
  it('renders basic layout elements', () => {
    render(<Layout />);

    // Check that the app name is displayed
    expect(screen.getAllByText('Vigor').length).toBeGreaterThan(0);

    // Check that main navigation links are present
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Workouts')).toBeInTheDocument();
    expect(screen.getByText('AI Coach')).toBeInTheDocument();
    expect(screen.getByText('Profile')).toBeInTheDocument();

    // Check that logout button is present
    expect(screen.getByText('Logout')).toBeInTheDocument();
  });

  it('displays welcome message when user is logged in', () => {
    render(<Layout />);

    // This will depend on the AuthProvider's default state
    // We should see some welcome text
    expect(screen.getByText(/Welcome/)).toBeInTheDocument();
  });
});
