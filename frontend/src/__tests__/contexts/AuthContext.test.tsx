import '@testing-library/jest-dom';
import { act, render, screen, waitFor } from '@testing-library/react';
import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import { AuthContext, AuthProvider } from '../../contexts/AuthContext';
import * as authService from '../../services/authService';
import type { User } from '../../types/auth';

// Mock dependencies
jest.mock('../../services/authService');

const mockNavigate = jest.fn();
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}));

const mockedAuthService = authService as jest.Mocked<typeof authService>;

// Test component to access context
const TestComponent: React.FC = () => {
  const context = React.useContext(AuthContext);
  if (!context) {
    return <div>No Auth Context</div>;
  }

  const { user, isLoading, login, register, logout, isAuthenticated } = context;

  return (
    <div>
      <div data-testid="user">{user ? JSON.stringify(user) : 'No user'}</div>
      <div data-testid="isLoading">{isLoading.toString()}</div>
      <div data-testid="isAuthenticated">{isAuthenticated.toString()}</div>
      <button onClick={() => login('test@example.com', 'password')}>Login</button>
      <button onClick={() => register('test@example.com', 'testuser', 'password')}>Register</button>
      <button onClick={logout}>Logout</button>
    </div>
  );
};

const renderWithRouter = (component: React.ReactElement) => {
  return render(
    <MemoryRouter>
      {component}
    </MemoryRouter>
  );
};

describe('AuthContext', () => {
     const mockUser: User = {
     id: '1',
     email: 'test@example.com',
     username: 'testuser',
     name: 'Test User',
     is_active: true,
     created_at: '2024-01-01T00:00:00Z',
     updated_at: '2024-01-01T00:00:00Z',
     fitness_level: 'beginner',
   };

  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.clear();
    console.error = jest.fn(); // Suppress console errors in tests
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe('Initial State', () => {
    it('should provide initial state correctly', async () => {
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('Not authenticated'));

      renderWithRouter(
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      );

      // Initially loading
      expect(screen.getByTestId('isLoading')).toHaveTextContent('true');

      // Wait for loading to complete
      await waitFor(() => {
        expect(screen.getByTestId('isLoading')).toHaveTextContent('false');
      });

      expect(screen.getByTestId('user')).toHaveTextContent('No user');
      expect(screen.getByTestId('isAuthenticated')).toHaveTextContent('false');
    });

    it('should restore user from token on mount', async () => {
      localStorage.setItem('accessToken', 'valid-token');
      mockedAuthService.getCurrentUser.mockResolvedValue(mockUser);

      renderWithRouter(
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      );

      await waitFor(() => {
        expect(screen.getByTestId('isLoading')).toHaveTextContent('false');
      });

      expect(screen.getByTestId('user')).toHaveTextContent(JSON.stringify(mockUser));
      expect(screen.getByTestId('isAuthenticated')).toHaveTextContent('true');
      expect(mockedAuthService.getCurrentUser).toHaveBeenCalledTimes(1);
    });

    it('should handle invalid token on mount', async () => {
      localStorage.setItem('accessToken', 'invalid-token');
      localStorage.setItem('refreshToken', 'invalid-refresh');
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('Token invalid'));

      renderWithRouter(
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      );

      await waitFor(() => {
        expect(screen.getByTestId('isLoading')).toHaveTextContent('false');
      });

      expect(screen.getByTestId('user')).toHaveTextContent('No user');
      expect(screen.getByTestId('isAuthenticated')).toHaveTextContent('false');
      expect(localStorage.getItem('accessToken')).toBeNull();
      expect(localStorage.getItem('refreshToken')).toBeNull();
    });
  });

  describe('Login', () => {
         it('should login successfully', async () => {
       const mockLoginResponse = {
         user: mockUser,
         access_token: 'new-access-token',
         refresh_token: 'new-refresh-token',
         token_type: 'bearer',
       };

      mockedAuthService.login.mockResolvedValue(mockLoginResponse);
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('Not authenticated'));

      renderWithRouter(
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      );

      // Wait for initial load
      await waitFor(() => {
        expect(screen.getByTestId('isLoading')).toHaveTextContent('false');
      });

      // Perform login
      await act(async () => {
        screen.getByText('Login').click();
      });

      expect(mockedAuthService.login).toHaveBeenCalledWith('test@example.com', 'password');
      expect(localStorage.getItem('accessToken')).toBe('new-access-token');
      expect(localStorage.getItem('refreshToken')).toBe('new-refresh-token');
      expect(screen.getByTestId('user')).toHaveTextContent(JSON.stringify(mockUser));
      expect(screen.getByTestId('isAuthenticated')).toHaveTextContent('true');
    });

    it('should handle login failure', async () => {
      mockedAuthService.login.mockRejectedValue(new Error('Invalid credentials'));
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('Not authenticated'));

      renderWithRouter(
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      );

      await waitFor(() => {
        expect(screen.getByTestId('isLoading')).toHaveTextContent('false');
      });

      await expect(async () => {
        await act(async () => {
          screen.getByText('Login').click();
        });
      }).rejects.toThrow('Invalid credentials');

      expect(screen.getByTestId('user')).toHaveTextContent('No user');
      expect(screen.getByTestId('isAuthenticated')).toHaveTextContent('false');
      expect(localStorage.getItem('accessToken')).toBeNull();
    });
  });

  describe('Register', () => {
         it('should register successfully', async () => {
       const mockRegisterResponse = {
         user: mockUser,
         access_token: 'new-access-token',
         refresh_token: 'new-refresh-token',
         token_type: 'bearer',
       };

      mockedAuthService.register.mockResolvedValue(mockRegisterResponse);
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('Not authenticated'));

      renderWithRouter(
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      );

      await waitFor(() => {
        expect(screen.getByTestId('isLoading')).toHaveTextContent('false');
      });

      await act(async () => {
        screen.getByText('Register').click();
      });

      expect(mockedAuthService.register).toHaveBeenCalledWith('test@example.com', 'testuser', 'password');
      expect(localStorage.getItem('accessToken')).toBe('new-access-token');
      expect(localStorage.getItem('refreshToken')).toBe('new-refresh-token');
      expect(screen.getByTestId('user')).toHaveTextContent(JSON.stringify(mockUser));
      expect(screen.getByTestId('isAuthenticated')).toHaveTextContent('true');
    });

    it('should handle registration failure', async () => {
      mockedAuthService.register.mockRejectedValue(new Error('Email already exists'));
      mockedAuthService.getCurrentUser.mockRejectedValue(new Error('Not authenticated'));

      renderWithRouter(
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      );

      await waitFor(() => {
        expect(screen.getByTestId('isLoading')).toHaveTextContent('false');
      });

      await expect(async () => {
        await act(async () => {
          screen.getByText('Register').click();
        });
      }).rejects.toThrow('Email already exists');

      expect(screen.getByTestId('user')).toHaveTextContent('No user');
      expect(screen.getByTestId('isAuthenticated')).toHaveTextContent('false');
    });
  });

  describe('Logout', () => {
    it('should logout successfully', async () => {
      localStorage.setItem('accessToken', 'valid-token');
      localStorage.setItem('refreshToken', 'valid-refresh');
      mockedAuthService.getCurrentUser.mockResolvedValue(mockUser);

      renderWithRouter(
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      );

      // Wait for user to be loaded
      await waitFor(() => {
        expect(screen.getByTestId('isAuthenticated')).toHaveTextContent('true');
      });

      await act(async () => {
        screen.getByText('Logout').click();
      });

      expect(screen.getByTestId('user')).toHaveTextContent('No user');
      expect(screen.getByTestId('isAuthenticated')).toHaveTextContent('false');
      expect(localStorage.getItem('accessToken')).toBeNull();
      expect(localStorage.getItem('refreshToken')).toBeNull();
    });
  });

  describe('Context Provider', () => {
    it('should throw error when used outside provider', () => {
      // Suppress console.error for this test
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

      expect(() => {
        render(<TestComponent />);
      }).toThrow();

      consoleSpy.mockRestore();
    });
  });
});
