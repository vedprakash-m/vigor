import { Box, Button, Container, Heading, Text, VStack } from '@chakra-ui/react'
import { Component, ErrorInfo, ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
  errorInfo: ErrorInfo | null
}

/**
 * Error Boundary component for graceful error handling
 * Catches JavaScript errors anywhere in child component tree and displays fallback UI
 */
export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null, errorInfo: null }
  }

  static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    // Log error to console in development
    console.error('ErrorBoundary caught an error:', error, errorInfo)

    this.setState({ errorInfo })

    // TODO: In production, log to Application Insights or error tracking service
    // Example: appInsights.trackException({ exception: error, properties: { componentStack: errorInfo.componentStack } })
  }

  handleReset = (): void => {
    this.setState({ hasError: false, error: null, errorInfo: null })
  }

  handleGoHome = (): void => {
    window.location.href = '/'
  }

  render(): ReactNode {
    if (this.state.hasError) {
      // Custom fallback if provided
      if (this.props.fallback) {
        return this.props.fallback
      }

      // Default error UI
      return (
        <Container maxW="container.md" py={20}>
          <VStack gap={6} textAlign="center">
            <Box fontSize="6xl">⚠️</Box>
            <Heading size="xl" color="red.500">
              Something went wrong
            </Heading>
            <Text color="gray.600" fontSize="lg">
              We're sorry, but something unexpected happened. Please try again.
            </Text>

            {process.env.NODE_ENV === 'development' && this.state.error && (
              <Box
                w="full"
                p={4}
                bg="red.50"
                borderRadius="md"
                textAlign="left"
                overflow="auto"
              >
                <Text fontFamily="mono" fontSize="sm" color="red.700">
                  {this.state.error.toString()}
                </Text>
                {this.state.errorInfo?.componentStack && (
                  <Text
                    fontFamily="mono"
                    fontSize="xs"
                    color="red.600"
                    mt={2}
                    whiteSpace="pre-wrap"
                  >
                    {this.state.errorInfo.componentStack}
                  </Text>
                )}
              </Box>
            )}

            <VStack gap={3}>
              <Button colorScheme="blue" onClick={this.handleReset}>
                Try Again
              </Button>
              <Button variant="outline" onClick={this.handleGoHome}>
                Go to Home
              </Button>
            </VStack>
          </VStack>
        </Container>
      )
    }

    return this.props.children
  }
}

/**
 * Smaller error boundary for specific sections
 * Displays inline error message without full-page takeover
 */
export class SectionErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null, errorInfo: null }
  }

  static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('SectionErrorBoundary caught an error:', error, errorInfo)
    this.setState({ errorInfo })
  }

  handleRetry = (): void => {
    this.setState({ hasError: false, error: null, errorInfo: null })
  }

  render(): ReactNode {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback
      }

      return (
        <Box p={4} bg="red.50" borderRadius="md" textAlign="center">
          <Text color="red.600" mb={2}>
            This section couldn't load properly.
          </Text>
          <Button size="sm" colorScheme="red" variant="outline" onClick={this.handleRetry}>
            Retry
          </Button>
        </Box>
      )
    }

    return this.props.children
  }
}

export default ErrorBoundary
