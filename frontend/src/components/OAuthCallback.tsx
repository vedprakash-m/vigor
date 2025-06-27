import {
    Box,
    Center,
    Spinner,
    Text,
    VStack
} from '@chakra-ui/react'
import React, { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { authService } from '../services/authService'

interface OAuthCallbackProps {
  provider: string
}

export const OAuthCallback: React.FC<OAuthCallbackProps> = ({ provider }) => {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading')
  const [errorMessage, setErrorMessage] = useState<string>('')

  useEffect(() => {
    const handleCallback = async () => {
      try {
        // Get authorization code and state from URL parameters
        const code = searchParams.get('code')
        const state = searchParams.get('state')
        const error = searchParams.get('error')
        const errorDescription = searchParams.get('error_description')

        // Check for OAuth errors
        if (error) {
          throw new Error(errorDescription || `OAuth error: ${error}`)
        }

        if (!code || !state) {
          throw new Error('Missing authorization code or state parameter')
        }

        // Exchange code for tokens
        const authResponse = await authService.handleOAuthCallback(provider, code, state)

        // Store tokens
        authService.storeTokens(authResponse)

        setStatus('success')

        // Redirect to intended page or dashboard
        const redirectUrl = localStorage.getItem('oauth_redirect_url') || '/dashboard'
        localStorage.removeItem('oauth_redirect_url')

        setTimeout(() => {
          navigate(redirectUrl)
        }, 1000)

      } catch (error) {
        console.error('OAuth callback error:', error)
        setStatus('error')
        setErrorMessage(
          error instanceof Error
            ? error.message
            : 'An unexpected error occurred during authentication'
        )

        // Redirect to login page after error
        setTimeout(() => {
          navigate('/login?error=oauth_failed')
        }, 3000)
      }
    }

    handleCallback()
  }, [searchParams, provider, navigate])

  const getProviderDisplayName = (providerName: string): string => {
    const displayNames: Record<string, string> = {
      microsoft: 'Microsoft',
      google: 'Google',
      github: 'GitHub'
    }
    return displayNames[providerName] || providerName
  }

  return (
    <Center minH="100vh" bg="gray.50">
      <Box maxW="md" mx="auto" p={8}>
        <VStack gap={6}>
          {status === 'loading' && (
            <>
              <Spinner size="xl" color="blue.500" />
              <Text fontSize="lg" color="gray.600">
                Completing {getProviderDisplayName(provider)} sign-in...
              </Text>
              <Text fontSize="sm" color="gray.500">
                Please wait while we verify your account
              </Text>
            </>
          )}

          {status === 'success' && (
            <>
              <Box color="green.500" fontSize="4xl">
                ✓
              </Box>
              <Text fontSize="lg" color="green.600" fontWeight="bold">
                Sign-in successful!
              </Text>
              <Text fontSize="sm" color="gray.600">
                Redirecting you to your dashboard...
              </Text>
            </>
          )}

          {status === 'error' && (
            <>
              <Box color="red.500" fontSize="4xl">
                ✗
              </Box>
              <Text fontSize="lg" color="red.600" fontWeight="bold">
                Authentication Failed
              </Text>
              <Text fontSize="sm" color="gray.600">
                {errorMessage}
              </Text>
              <Text fontSize="xs" color="gray.500">
                Redirecting to login page...
              </Text>
            </>
          )}
        </VStack>
      </Box>
    </Center>
  )
}

export default OAuthCallback
