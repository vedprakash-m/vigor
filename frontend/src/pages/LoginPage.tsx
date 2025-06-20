import {
    Box,
    Button,
    Flex,
    Heading,
    Input,
    Text,
} from '@chakra-ui/react'
import React, { useState } from 'react'
import { Link as RouterLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/useAuth'

export const LoginPage = () => {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const { login } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setIsLoading(true)

    try {
      await login(email, password)
      navigate('/')
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { detail?: string } } }
      const detail = axiosErr.response?.data?.detail || ''
      if (detail.toLowerCase().includes('oauth')) {
        console.error('oauth_failed')
        setError('Third-party login failed. Please try again or sign in with email & password.')
      } else {
        setError(detail || 'Login failed')
      }
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Flex minH="100vh" align="center" justify="center" bg="gray.50">
      <Box maxW="md" w="full" bg="white" p={8} rounded="lg" shadow="md">
        <Heading mb={6} textAlign="center" color="blue.500">
          Welcome to Vigor
        </Heading>

        {error && (
          <Box bg="red.100" border="1px" borderColor="red.300" p={3} rounded="md" mb={4}>
            <Text color="red.600">{error}</Text>
          </Box>
        )}

        <form onSubmit={handleSubmit}>
          <Box mb={4}>
            <label htmlFor="email">
              <Text mb={2} fontWeight="bold">
                Email
              </Text>
            </label>
            <Input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter your email"
              required
            />
          </Box>

          <Box mb={6}>
            <label htmlFor="password">
              <Text mb={2} fontWeight="bold">
                Password
              </Text>
            </label>
            <Input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
              required
            />
          </Box>

          <Button
            type="submit"
            bg="blue.500"
            color="white"
            size="lg"
            w="full"
            mb={4}
            disabled={isLoading}
            _hover={{ bg: 'blue.600' }}
            aria-label="Login"
          >
            {isLoading ? 'Signing in...' : 'Sign In'}
          </Button>
        </form>

        <Text textAlign="center">
          Don't have an account?{' '}
          <RouterLink to="/register" style={{ color: '#3182ce', textDecoration: 'underline' }}>
            Sign up
          </RouterLink>
        </Text>
      </Box>
    </Flex>
  )
}
