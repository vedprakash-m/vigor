import { Box, Button, HStack, Text, VStack } from '@chakra-ui/react'
import React, { useEffect, useState } from 'react'
import { authService } from '../services/authService'
import type { OAuthProvidersResponse } from '../types/auth'

interface OAuthLoginButtonsProps {
  onError?: (error: string) => void
  isLoading?: boolean
}

export const OAuthLoginButtons: React.FC<OAuthLoginButtonsProps> = ({
  onError,
  isLoading = false
}) => {
  const [availableProviders, setAvailableProviders] = useState<string[]>([])
  const [loadingProvider, setLoadingProvider] = useState<string | null>(null)

  useEffect(() => {
    const fetchProviders = async () => {
      try {
        const response: OAuthProvidersResponse = await authService.getOAuthProviders()
        setAvailableProviders(response.providers)
      } catch (error) {
        console.error('Failed to fetch OAuth providers:', error)
        if (onError) {
          onError('Failed to load social login options')
        }
      }
    }

    fetchProviders()
  }, [onError])

  const handleOAuthLogin = async (provider: string) => {
    try {
      setLoadingProvider(provider)
      authService.initiateOAuthLogin(provider)
    } catch (error) {
      console.error(`OAuth login failed for ${provider}:`, error)
      setLoadingProvider(null)
      if (onError) {
        onError(`Failed to sign in with ${getProviderDisplayName(provider)}`)
      }
    }
  }

  const getProviderDisplayName = (provider: string): string => {
    const displayNames: Record<string, string> = {
      microsoft: 'Microsoft',
      google: 'Google',
      github: 'GitHub'
    }
    return displayNames[provider] || provider
  }

  const getProviderIcon = (provider: string): string => {
    const icons: Record<string, string> = {
      microsoft: '🏢',
      google: '🔍',
      github: '🐙'
    }
    return icons[provider] || '🔐'
  }

  const getProviderColor = (provider: string): string => {
    const colors: Record<string, string> = {
      microsoft: 'blue',
      google: 'red',
      github: 'gray'
    }
    return colors[provider] || 'gray'
  }

  if (availableProviders.length === 0) {
    return null
  }

  return (
    <VStack gap={4} w="100%">
      <HStack w="100%">
        <Box h="1px" bg="gray.300" flex={1} />
        <Text fontSize="sm" color="gray.500" px={3} whiteSpace="nowrap">
          Or continue with
        </Text>
        <Box h="1px" bg="gray.300" flex={1} />
      </HStack>

      <VStack gap={3} w="100%">
        {availableProviders.map((provider) => (
          <Button
            key={provider}
            variant="outline"
            w="100%"
            h="12"
            borderColor="gray.300"
            loading={loadingProvider === provider || isLoading}
            loadingText={`Connecting to ${getProviderDisplayName(provider)}...`}
            onClick={() => handleOAuthLogin(provider)}
            _hover={{
              borderColor: `${getProviderColor(provider)}.400`,
              bg: `${getProviderColor(provider)}.50`
            }}
            _focus={{
              boxShadow: `0 0 0 3px ${getProviderColor(provider)}.100`
            }}
          >
            <HStack>
              <Box fontSize="lg">
                {getProviderIcon(provider)}
              </Box>
              <Text>Continue with {getProviderDisplayName(provider)}</Text>
            </HStack>
          </Button>
        ))}
      </VStack>

      <Text fontSize="xs" color="gray.500" textAlign="center" maxW="300px">
        By continuing, you agree to our Terms of Service and Privacy Policy.
        Your data is secured with enterprise-grade encryption.
      </Text>
    </VStack>
  )
}

export default OAuthLoginButtons
