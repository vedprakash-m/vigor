import { ChakraProvider, defaultSystem } from '@chakra-ui/react'
import type { RenderOptions } from '@testing-library/react'
import { render } from '@testing-library/react'
import React from 'react'
import { AuthProvider } from './contexts/AuthContext'

// Simple wrapper that provides basic context for tests
const AllTheProviders = ({ children }: { children: React.ReactNode }) => (
  <ChakraProvider value={defaultSystem}>
    <AuthProvider>
      <div data-testid="test-wrapper">{children}</div>
    </AuthProvider>
  </ChakraProvider>
)

const customRender = (
  ui: React.ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllTheProviders, ...options })

// Re-export everything
export * from '@testing-library/react'

// Override render method
export { customRender as render }
