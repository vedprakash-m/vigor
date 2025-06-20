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

export const RegisterPage = () => {
  const [email, setEmail] = useState('')
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const { register } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setIsLoading(true)

    if (password !== confirmPassword) {
      setError('Passwords do not match')
      setIsLoading(false)
      return
    }

    try {
      await register(email, username, password)
      navigate('/onboarding')
    } catch (err: unknown) {
      const error = err as { response?: { data?: { detail?: string } } };
      setError(error.response?.data?.detail || 'Registration failed')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Flex minH="100vh" align="center" justify="center" bg="gray.50">
      <Box maxW="md" w="full" bg="white" p={8} rounded="lg" shadow="md">
        <Heading mb={6} textAlign="center" color="blue.500">
          Join Vigor
        </Heading>

        {error && (
          <Box bg="red.100" border="1px" borderColor="red.300" p={3} rounded="md" mb={4}>
            <Text color="red.600">{error}</Text>
          </Box>
        )}

        <form onSubmit={handleSubmit}>
          <Box mb={4}>
            <label htmlFor="email">
              <Text mb={2} fontWeight="bold">Email</Text>
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

          <Box mb={4}>
            <label htmlFor="username">
              <Text mb={2} fontWeight="bold">Username</Text>
            </label>
            <Input
              id="username"
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Choose a username"
              required
            />
          </Box>

          <Box mb={4}>
            <label htmlFor="password">
              <Text mb={2} fontWeight="bold">Password</Text>
            </label>
            <Input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Choose a password"
              required
            />
          </Box>

          <Box mb={6}>
            <label htmlFor="confirmPassword">
              <Text mb={2} fontWeight="bold">Confirm Password</Text>
            </label>
            <Input
              id="confirmPassword"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Confirm your password"
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
            aria-label="Register"
          >
            {isLoading ? 'Creating account...' : 'Sign Up'}
          </Button>
        </form>

        <Text textAlign="center">
          Already have an account?{' '}
          <RouterLink to="/login" style={{ color: '#3182ce', textDecoration: 'underline' }}>
            Sign in
          </RouterLink>
        </Text>
      </Box>
    </Flex>
  )
}
