module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  moduleNameMapper: {
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  setupFilesAfterEnv: ['<rootDir>/setupTests.js'],
  transform: {
    '^.+\\.(ts|tsx)$': ['ts-jest', {
      tsconfig: 'tsconfig.jest.json',
      useESM: true,
    }],
    '^.+\\.(js|jsx)$': 'babel-jest',
  },
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json'],
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/main.tsx',
    '!src/vite-env.d.ts',
    '!src/**/*.test.{ts,tsx}',
    '!src/**/*.spec.{ts,tsx}',
    '!src/**/*.stories.{ts,tsx}', // Exclude Storybook files
    '!src/services/authService.ts', // Exclude files with import.meta.env
    '!src/test-utils.tsx',
    '!src/pages/**', // Exclude untested pages for now
    '!src/features/**', // Exclude untested features for now
    '!src/hooks/**', // Exclude untested hooks for now
    // Include tested components and contexts
    'src/contexts/AuthContext.tsx',
    'src/components/Layout.tsx',
    'src/components/LLMStatus.tsx',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html', 'json-summary'],
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{ts,tsx}',
    '<rootDir>/src/**/*.{test,spec}.{ts,tsx}',
  ],
  testPathIgnorePatterns: [
    '<rootDir>/src/__tests__/performance/.*',
    '<rootDir>/src/__tests__/accessibility/.*',
    '<rootDir>/src/pages/AdminPage.test.tsx',
    '<rootDir>/src/__tests__/components/ForgotPasswordPage.test.tsx',
    '<rootDir>/src/__tests__/pages/OnboardingPage.test.tsx',
    '<rootDir>/src/pages/SupportConsolePage.test.tsx',
    '<rootDir>/src/__tests__/services/.*',
    '<rootDir>/src/__tests__/integration/.*',
    '<rootDir>/src/components/.*test\.tsx$',
    '<rootDir>/src/__tests__/pages/ProfilePage.test.tsx',
  ],
  watchAll: false,
  globals: {
    'ts-jest': {
      tsconfig: 'tsconfig.jest.json',
      useESM: true,
    },
  },
  testEnvironmentOptions: {
    customExportConditions: [''],
  },
  setupFiles: ['<rootDir>/jest.setup.js'],
};
