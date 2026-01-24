/**
 * OAuth Callback Component
 * Handles OAuth callback redirects for authentication
 */

import { Box, Heading, Spinner, Text, VStack } from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useVedAuth } from '../contexts/useVedAuth'

interface OAuthCallbackProps {
    provider: string
}

export const OAuthCallback = ({ provider }: OAuthCallbackProps) => {
    const navigate = useNavigate()
    const { isAuthenticated, isLoading } = useVedAuth()
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        // With MSAL, the callback is handled automatically
        // This component just shows loading state and redirects
        const handleCallback = async () => {
            try {
                // Wait a moment for MSAL to process the callback
                await new Promise((resolve) => setTimeout(resolve, 1000))

                if (isAuthenticated) {
                    // Successfully authenticated, redirect to dashboard
                    navigate('/app/dashboard', { replace: true })
                } else if (!isLoading) {
                    // Not authenticated and not loading, something went wrong
                    setError('Authentication failed. Please try again.')
                    setTimeout(() => navigate('/login', { replace: true }), 3000)
                }
            } catch (err) {
                console.error('OAuth callback error:', err)
                setError('An error occurred during authentication.')
                setTimeout(() => navigate('/login', { replace: true }), 3000)
            }
        }

        handleCallback()
    }, [isAuthenticated, isLoading, navigate, provider])

    if (error) {
        return (
            <Box
                minH="100vh"
                display="flex"
                alignItems="center"
                justifyContent="center"
                bg="gray.50"
            >
                <VStack gap={4}>
                    <Heading size="lg" color="red.500">
                        Authentication Error
                    </Heading>
                    <Text color="gray.600">{error}</Text>
                    <Text fontSize="sm" color="gray.500">
                        Redirecting to login...
                    </Text>
                </VStack>
            </Box>
        )
    }

    return (
        <Box
            minH="100vh"
            display="flex"
            alignItems="center"
            justifyContent="center"
            bg="gray.50"
        >
            <VStack gap={4}>
                <Spinner size="xl" color="blue.500" />
                <Heading size="lg">Completing Sign In</Heading>
                <Text color="gray.600">
                    Please wait while we complete your authentication...
                </Text>
            </VStack>
        </Box>
    )
}

export default OAuthCallback
