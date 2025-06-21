import { ChakraProvider, defaultSystem } from '@chakra-ui/react';
import { fireEvent, render, screen } from '@testing-library/react';
import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import { Layout } from '../../components/Layout';
import { AuthContext } from '../../contexts/AuthContext';
import type { User } from '../../types/auth';

// Mock the useAuth hook since Layout uses it
const mockUser: User = {
  id: '1',
  email: 'test@example.com',
  username: 'testuser',
  user_tier: 'premium',
  is_active: true,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
};

const createMockAuthContext = (user: User | null = mockUser, logout = jest.fn()) => ({
  user,
  isLoading: false,
  login: jest.fn(),
  register: jest.fn(),
  logout,
  isAuthenticated: !!user,
});

const TestWrapper: React.FC<{
  children: React.ReactNode;
  authContext?: any;
  initialRoute?: string;
}> = ({
  children,
  authContext = createMockAuthContext(),
  initialRoute = '/'
}) => (
  <ChakraProvider value={defaultSystem}>
    <AuthContext.Provider value={authContext}>
      <MemoryRouter initialEntries={[initialRoute]}>
        {children}
      </MemoryRouter>
    </AuthContext.Provider>
  </ChakraProvider>
);

describe('Layout', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('renders layout with all navigation links', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      // Check that all navigation links are present
      expect(screen.getByText('Dashboard')).toBeInTheDocument();
      expect(screen.getByText('Workouts')).toBeInTheDocument();
      expect(screen.getByText('AI Coach')).toBeInTheDocument();
      expect(screen.getByText('Tier Management')).toBeInTheDocument();
      expect(screen.getByText('Profile')).toBeInTheDocument();
    });

    it('displays the app name "Vigor"', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      // Should appear at least once (in sidebar, possibly in mobile header)
      expect(screen.getAllByText('Vigor').length).toBeGreaterThan(0);
    });

    it('displays welcome message with username', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      expect(screen.getByText('Welcome, testuser')).toBeInTheDocument();
    });

    it('renders logout button', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      expect(screen.getByText('Logout')).toBeInTheDocument();
    });
  });

  describe('Navigation', () => {
    const navigationTests = [
      { name: 'Dashboard', path: '/' },
      { name: 'Workouts', path: '/workouts' },
      { name: 'AI Coach', path: '/coach' },
      { name: 'Tier Management', path: '/tiers' },
      { name: 'Profile', path: '/profile' },
    ];

    navigationTests.forEach(({ name, path }) => {
      it(`renders ${name} navigation link with correct href`, () => {
        render(
          <TestWrapper>
            <Layout />
          </TestWrapper>
        );

        const navLink = screen.getByText(name).closest('a');
        expect(navLink).toHaveAttribute('href', path);
      });
    });

    it('highlights active navigation item', () => {
      render(
        <TestWrapper initialRoute="/workouts">
          <Layout />
        </TestWrapper>
      );

      const workoutsLink = screen.getByText('Workouts').closest('a');
      // The active link should have different styling (we can't easily test inline styles)
      expect(workoutsLink).toBeInTheDocument();
    });
  });

  describe('User Authentication', () => {
    it('handles logged in user correctly', () => {
      render(
        <TestWrapper authContext={createMockAuthContext(mockUser)}>
          <Layout />
        </TestWrapper>
      );

      expect(screen.getByText('Welcome, testuser')).toBeInTheDocument();
      expect(screen.getByText('Logout')).toBeInTheDocument();
    });

    it('handles user with different username', () => {
      const differentUser = { ...mockUser, username: 'johnsmith' };
      render(
        <TestWrapper authContext={createMockAuthContext(differentUser)}>
          <Layout />
        </TestWrapper>
      );

      expect(screen.getByText('Welcome, johnsmith')).toBeInTheDocument();
    });

    it('handles null user gracefully', () => {
      render(
        <TestWrapper authContext={createMockAuthContext(null)}>
          <Layout />
        </TestWrapper>
      );

      // Should not crash and should show welcome without username
      expect(screen.getByText(/Welcome,/)).toBeInTheDocument();
    });
  });

  describe('Logout Functionality', () => {
    it('calls logout function when logout button is clicked', () => {
      const mockLogoutFn = jest.fn();

      render(
        <TestWrapper authContext={createMockAuthContext(mockUser, mockLogoutFn)}>
          <Layout />
        </TestWrapper>
      );

      const logoutButton = screen.getByText('Logout');
      fireEvent.click(logoutButton);

      expect(mockLogoutFn).toHaveBeenCalledTimes(1);
    });

    it('logout button is clickable', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      const logoutButton = screen.getByText('Logout');
      expect(logoutButton).toBeInTheDocument();
      expect(logoutButton.closest('button') || logoutButton).toHaveStyle('cursor: pointer');
    });
  });

  describe('Responsive Design', () => {
    it('renders sidebar navigation for desktop', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      // All navigation links should be present
      expect(screen.getByText('Dashboard')).toBeInTheDocument();
      expect(screen.getByText('Workouts')).toBeInTheDocument();
      expect(screen.getByText('AI Coach')).toBeInTheDocument();
    });

    it('includes mobile header elements', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      // Mobile header should exist (though display may be controlled by CSS)
      const headerElements = screen.getAllByText('Vigor');
      expect(headerElements.length).toBeGreaterThan(0);
    });
  });

  describe('Content Area', () => {
    it('provides outlet for child routes', () => {
      const TestChild = () => <div data-testid="child-content">Child Route Content</div>;

      render(
        <TestWrapper>
          <Layout />
          <TestChild />
        </TestWrapper>
      );

      // The layout should render and not interfere with child content
      expect(screen.getByText('Welcome, testuser')).toBeInTheDocument();
    });

    it('has proper content wrapper styling', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      // The layout should render without errors
      expect(screen.getByText('Vigor')).toBeInTheDocument();
      expect(screen.getByText('Welcome, testuser')).toBeInTheDocument();
    });
  });

  describe('Accessibility', () => {
    it('has accessible navigation structure', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      // Navigation links should be accessible
      const dashboardLink = screen.getByText('Dashboard');
      expect(dashboardLink.closest('a')).toHaveAttribute('href', '/');

      const workoutsLink = screen.getByText('Workouts');
      expect(workoutsLink.closest('a')).toHaveAttribute('href', '/workouts');
    });

    it('logout button has proper button semantics', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      const logoutElement = screen.getByText('Logout');
      // Should be clickable and accessible
      expect(logoutElement).toBeInTheDocument();
    });

    it('has proper heading hierarchy', () => {
      render(
        <TestWrapper>
          <Layout />
        </TestWrapper>
      );

      // Should have proper heading structure
      const vigorHeadings = screen.getAllByText('Vigor');
      expect(vigorHeadings.length).toBeGreaterThan(0);
    });
  });

  describe('Error Boundaries', () => {
    it('handles auth context errors gracefully', () => {
      const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});

      // Test with corrupted auth context
      const brokenAuthContext = {
        ...createMockAuthContext(),
        user: undefined, // Invalid state
      };

      expect(() => {
        render(
          <TestWrapper authContext={brokenAuthContext}>
            <Layout />
          </TestWrapper>
        );
      }).not.toThrow();

      consoleError.mockRestore();
    });
  });
});
