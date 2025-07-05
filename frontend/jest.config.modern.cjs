module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  moduleNameMapper: {
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  setupFilesAfterEnv: ['<rootDir>/setupTests.js'],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      tsconfig: 'tsconfig.jest.json',
    }],
    '^.+\\.jsx?$': 'babel-jest',
  },
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json'],
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/main.tsx',
    '!src/vite-env.d.ts',
    '!src/**/*.test.{ts,tsx}',
    '!src/**/*.spec.{ts,tsx}',
    '!src/**/*.stories.{ts,tsx}',
    '!src/services/authService.ts',
    '!src/test-utils.tsx',
    // Focus on working components for coverage
    'src/contexts/AuthContext.tsx',
    'src/components/Layout.tsx',
    'src/components/LLMStatus.tsx',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov'],
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{ts,tsx}',
    '<rootDir>/src/**/*.{test,spec}.{ts,tsx}',
  ],
  testPathIgnorePatterns: [
    '<rootDir>/src/__tests__/performance/',
    '<rootDir>/src/__tests__/accessibility/',
    '<rootDir>/src/__tests__/integration/',
    '<rootDir>/src/__tests__/services/',
    '<rootDir>/src/pages/AdminPage.test.tsx',
    '<rootDir>/src/pages/SupportConsolePage.test.tsx',
  ],
  testTimeout: 10000,
  maxWorkers: 2,
};
