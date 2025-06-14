import { Box, Button, Heading, Input, Text, VStack } from '@chakra-ui/react'
import { useState } from 'react'
import { Link as RouterLink, useNavigate } from 'react-router-dom'
import { authService } from '../services/authService'

export const ForgotPasswordPage = () => {
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const navigate = useNavigate()

  const handleSubmit = async (e?: React.FormEvent) => {
    e?.preventDefault()

    if (!email) {
      setError('Email is required')
      return
    }

    // Basic email pattern for client-side validation
    const emailPattern = /.+@.+\..+/i
    if (!emailPattern.test(email)) {
      setError('Please enter a valid email address')
      return
    }

    setError('')
    setLoading(true)

    try {
      const res = await authService.forgotPassword(email)
      if (res.message) {
        setSent(true)
        setEmail('')
      }
    } catch {
      setError('Failed to send reset email')
    } finally {
      setLoading(false)
    }
  }

  if (sent) {
    return (
      <Box p={8} maxW="md" mx="auto">
        <Heading size="md" mb={4}>Check Your Email</Heading>
        <Text mb={6}>Check your email for reset instructions.</Text>
        <Button onClick={() => navigate('/login')} aria-label="Back to Login">Back to Login</Button>
      </Box>
    )
  }

  return (
    <Box p={8} maxW="md" mx="auto">
      <Heading size="lg" mb={6}>Forgot Password</Heading>
      <form onSubmit={handleSubmit}>
        <VStack gap={4} align="stretch">
          <label htmlFor="email">
            <Text fontWeight="bold" mb={1}>Email</Text>
          </label>
          <Input
            id="email"
            type="email"
            placeholder="Enter your email"
            value={email}
            required
            onChange={(e) => setEmail(e.target.value)}
          />

          {error && (
            <Text color="red.500" role="alert">
              {error}
            </Text>
          )}

          <Button
            colorScheme="blue"
            type="submit"
            disabled={loading}
            aria-label="Send Reset Link"
            w="full"
          >
            {loading ? 'Sending...' : 'Send Reset Link'}
          </Button>

          <RouterLink to="/login" style={{ color: '#3182ce', textDecoration: 'underline' }}>
            Back to Login
          </RouterLink>
        </VStack>
      </form>
    </Box>
  )
}
