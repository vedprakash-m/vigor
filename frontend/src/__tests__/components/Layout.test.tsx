import { render, screen } from '@testing-library/react';
import React from 'react';
import { MemoryRouter } from 'react-router-dom';

// Mock the auth config to avoid import.meta issues in Jest
jest.mock('../../config/authConfig', () => ({
  msalConfig: {
    auth: { clientId: 'test-client-id', authority: 'https://login.microsoftonline.com/test' },
  },
  loginRequest: { scopes: ['openid'] },
}));

// Mock Auth context
jest.mock('../../contexts/useAuth', () => ({
  useAuth: () => ({
    user: { name: 'Test User', email: 'test@example.com' },
    isAuthenticated: true,
    isLoading: false,
    logout: jest.fn(),
  }),
}));

// Mock Chakra UI
jest.mock('@chakra-ui/react', () => ({
  Box: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  Badge: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <span {...props}>{children}</span>,
  Button: ({ children, onClick, ...props }: React.PropsWithChildren<{ onClick?: () => void }>) => (
    <button onClick={onClick} {...props}>{children}</button>
  ),
  Flex: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  Heading: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <h1 {...props}>{children}</h1>,
  Text: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <span {...props}>{children}</span>,
  VStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  HStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  IconButton: ({ children, onClick, ...props }: React.PropsWithChildren<{ onClick?: () => void }>) => (
    <button onClick={onClick} {...props}>{children}</button>
  ),
  Spacer: () => <div />,
  Link: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <a {...props}>{children}</a>,
  ChakraProvider: ({ children }: React.PropsWithChildren<unknown>) => <>{children}</>,
  defaultSystem: {},
  Portal: ({ children }: React.PropsWithChildren<unknown>) => <>{children}</>,
  Drawer: {
    Root: ({ children }: React.PropsWithChildren<Record<string, unknown>>) => <div data-testid="drawer">{children}</div>,
    Backdrop: () => <div data-testid="drawer-backdrop" />,
    Positioner: ({ children }: React.PropsWithChildren<unknown>) => <div>{children}</div>,
    Content: ({ children }: React.PropsWithChildren<unknown>) => <div>{children}</div>,
    Header: ({ children }: React.PropsWithChildren<unknown>) => <div>{children}</div>,
    Body: ({ children }: React.PropsWithChildren<unknown>) => <div>{children}</div>,
    CloseTrigger: ({ children }: React.PropsWithChildren<unknown>) => <button>{children}</button>,
  },
}));

// Mock adminApi to avoid import.meta.env in Jest
jest.mock('../../services/adminApi', () => ({
  __esModule: true,
  setAdminAccessToken: jest.fn(),
}));

// Mock adminConfig
jest.mock('../../config/adminConfig', () => ({
  __esModule: true,
  isAdmin: jest.fn().mockReturnValue(true),
}));

import { Layout } from '../../components/Layout';

describe('Layout', () => {
  it('renders basic layout elements', () => {
    render(
      <MemoryRouter>
        <Layout />
      </MemoryRouter>
    );

    // Check that the admin dashboard name is displayed
    expect(screen.getAllByText(/Vigor Ghost/i).length).toBeGreaterThan(0);
  });

  it('displays welcome message when user is logged in', () => {
    render(
      <MemoryRouter>
        <Layout />
      </MemoryRouter>
    );

    // We should see some welcome text based on mocked user
    expect(screen.getByText(/Test User|Welcome/)).toBeInTheDocument();
  });
});
