import {
    Box,
    Button,
    Flex,
    Heading,
    Icon,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useEffect } from 'react'
import { FaMicrosoft } from 'react-icons/fa'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/useAuth'

export const LoginPage = () => {
  const { login, isAuthenticated, isLoading, error } = useAuth()
  const navigate = useNavigate()

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/')
    }
  }, [isAuthenticated, navigate])

  const handleLogin = async () => {
    try {
      await login()
      // Navigation happens automatically via the auth context
    } catch (err) {
      console.error('Login failed:', err)
      // Error is handled by the auth context
    }
  }

  return (
    <Flex minH="100vh" align="center" justify="center" bg="gray.50">
      <Box maxW="md" w="full" bg="white" p={8} rounded="lg" shadow="lg">
        <VStack gap={6}>
          <Heading textAlign="center" color="blue.500" size="lg">
            Welcome to Vigor
          </Heading>

          <Text textAlign="center" color="gray.600" fontSize="sm">
            Sign in with your Microsoft account to access the Vedprakash fitness platform
          </Text>

          {error && (
            <Box bg="red.100" border="1px" borderColor="red.300" p={3} rounded="md" w="full">
              <Text color="red.600" fontSize="sm">{error}</Text>
            </Box>
          )}

          <Button
            onClick={handleLogin}
            bg="blue.500"
            color="white"
            size="lg"
            w="full"
            loading={isLoading}
            disabled={isLoading}
            _hover={{ bg: 'blue.600' }}
          >
            <Icon marginEnd={2}>
              <FaMicrosoft />
            </Icon>
            {isLoading ? 'Signing in...' : 'Sign in with Microsoft'}
          </Button>

          <VStack gap={2} fontSize="xs" color="gray.500" textAlign="center">
            <Text>Secure authentication powered by Microsoft Entra ID</Text>
            <Text>Single sign-on across all Vedprakash applications</Text>
          </VStack>
        </VStack>
      </Box>
    </Flex>
  )
}
