import { ChakraProvider, defaultSystem } from '@chakra-ui/react'
import type { RenderOptions } from '@testing-library/react'
import { render } from '@testing-library/react'
import React from 'react'
import { BrowserRouter } from 'react-router-dom'
import { VedAuthProvider } from './contexts/VedAuthContext'

// Simple wrapper that provides basic context for tests
const AllTheProviders = ({ children }: { children: React.ReactNode }) => (
  <BrowserRouter>
    <ChakraProvider value={defaultSystem}>
      <VedAuthProvider>
        <div data-testid="test-wrapper">{children}</div>
      </VedAuthProvider>
    </ChakraProvider>
  </BrowserRouter>
)

const customRender = (
  ui: React.ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllTheProviders, ...options })

// Re-export everything
export * from '@testing-library/react'

// Override render method
export { customRender as render }
