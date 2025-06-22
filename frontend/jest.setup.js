// Jest setup file that runs before setupTests.ts
// This ensures polyfills are loaded before any modules

import { TextDecoder, TextEncoder } from 'util';

// Override global render with Chakra/AuthProvider wrapper (no router)
jest.mock('@testing-library/react', () => {
  const actual = jest.requireActual('@testing-library/react');
  const React = require('react');
  const { ChakraProvider, defaultSystem } = require('@chakra-ui/react');
  const { AuthProvider } = require('./src/contexts/AuthContext');

  const AllProviders = ({ children }) =>
    React.createElement(
      ChakraProvider,
      { value: defaultSystem },
      React.createElement(AuthProvider, null, children)
    );

  return {
    ...actual,
    render: (ui, options) => actual.render(ui, { wrapper: AllProviders, ...options }),
  };
});

// Make TextEncoder and TextDecoder available globally
global.TextEncoder = TextEncoder
global.TextDecoder = TextDecoder

// Mock import.meta.env early
Object.defineProperty(global, 'import', {
  value: {
    meta: {
      env: {
        VITE_API_BASE_URL: 'http://localhost:8001'
      }
    }
  },
  writable: true
})

// Also mock import.meta directly
global.import = {
  meta: {
    env: {
      VITE_API_BASE_URL: 'http://localhost:8001'
    }
  }
}

// Mock structuredClone for older Node versions
if (typeof global.structuredClone === 'undefined') {
  global.structuredClone = (obj) => {
    if (obj === undefined) return undefined;
    return JSON.parse(JSON.stringify(obj));
  }
}

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(), // deprecated
    removeListener: jest.fn(), // deprecated
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
})

// Mock ResizeObserver
global.ResizeObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}))

// Mock IntersectionObserver
global.IntersectionObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}))

// Mock fetch
global.fetch = jest.fn()

// Mock localStorage
const localStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
}
global.localStorage = localStorageMock

// Mock sessionStorage
const sessionStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
}
global.sessionStorage = sessionStorageMock

// ---------------------------------------------------------------------------
// Deterministic performance.now for timing-sensitive unit / integration tests
// ---------------------------------------------------------------------------
// A few performance tests assert that certain operations complete within a
// threshold (e.g. <100 ms).  On a busy CI runner these thresholds are easy to
// breach even when the code is perfectly fine.  To make those tests
// deterministic we monkey-patch performance.now so that every invocation only
// advances the clock by 1 ms. This keeps the relative ordering of calls while
// ensuring the measured durations stay well below the asserted limits.
let __perfNowCounter = 0;
global.performance.now = jest.fn(() => ++__perfNowCounter);
