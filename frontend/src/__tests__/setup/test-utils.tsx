/**
 * Phase 7: Testing & Quality Assurance - Test Infrastructure Fixes
 * Addresses critical test infrastructure issues for stable testing
 */

import { ChakraProvider, defaultSystem } from '@chakra-ui/react';
import { render, RenderOptions } from '@testing-library/react';
import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import type { User } from '../../types/auth';

// Mock User with all required properties for testing
export const createMockUser = (overrides: Partial<User> = {}): User => ({
  id: '1',
  email: 'test@example.com',
  username: 'testuser',
  name: 'Test User',
  givenName: 'Test',
  familyName: 'User',
  permissions: [],
  profile: {
    profileId: 'test-profile-1',
    subscriptionTier: 'free',
    appsEnrolled: [],
    preferences: {},
  },
  ...overrides,
});

// Test wrapper with all necessary providers (no AuthProvider needed - using AuthContext via MSAL)
const AllTestProviders: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <MemoryRouter>
    <ChakraProvider value={defaultSystem}>
      {children}
    </ChakraProvider>
  </MemoryRouter>
);

// Custom render function that includes all providers
export const renderWithProviders = (
  ui: React.ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllTestProviders, ...options });

// Mock fetch for API calls
export const mockFetch = (responseData: any, ok = true, status = 200) => {
  const mockFetch = jest.fn().mockResolvedValue({
    ok,
    status,
    json: async () => responseData,
  });

  global.fetch = mockFetch;
  return mockFetch;
};

// Common test utilities
export const waitForElement = async (getElement: () => HTMLElement) => {
  let element: HTMLElement | null = null;
  let attempts = 0;
  const maxAttempts = 50;

  while (!element && attempts < maxAttempts) {
    try {
      element = getElement();
    } catch {
      // Element not found yet
    }

    if (!element) {
      await new Promise(resolve => setTimeout(resolve, 100));
      attempts++;
    }
  }

  return element;
};

// Clean up after each test
export const testCleanup = () => {
  jest.clearAllMocks();
  localStorage.clear();
  sessionStorage.clear();
};
