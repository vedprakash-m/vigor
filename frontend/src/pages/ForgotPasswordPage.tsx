import { Box, Button, Heading, Input, Text, VStack } from '@chakra-ui/react'
import { useState } from 'react'
import { authService } from '../services/authService'

export const ForgotPasswordPage = () => {
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)
  const [err, setErr] = useState('')

  const submit = async () => {
    try {
      const res = await authService.forgotPassword(email)
      if (res.message) setSent(true)
    } catch {
      setErr('Failed to send reset link')
    }
  }

  if (sent) {
    return (
      <Box p={8} maxW="md" mx="auto">
        <Heading size="md" mb={4}>Check Your Email</Heading>
        <Text>If an account exists we have emailed a link that lasts 30 minutes.</Text>
      </Box>
    )
  }

  return (
    <Box p={8} maxW="md" mx="auto">
      <Heading size="lg" mb={6}>Forgot Password</Heading>
      <VStack gap={4}>
        <Input placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} />
        {err && <Text color="red.500">{err}</Text>}
        <Button colorScheme="blue" w="full" onClick={submit}>Send Reset Link</Button>
      </VStack>
    </Box>
  )
}
