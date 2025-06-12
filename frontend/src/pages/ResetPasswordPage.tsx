import { Box, Button, Heading, Input, Text, VStack } from '@chakra-ui/react'
import { useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { authService } from '../services/authService'

export const ResetPasswordPage = () => {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const token = params.get('token') || ''
  const [password, setPassword] = useState('')
  const [done, setDone] = useState(false)
  const [err, setErr] = useState('')

  const submit = async () => {
    try {
      const res = await authService.resetPassword(token, password)
      if (res.message) {
        setDone(true)
        setTimeout(() => navigate('/login'), 2000)
      }
    } catch {
      setErr('Failed reset')
    }
  }

  if (!token) return <Text>Invalid or missing token.</Text>

  if (done) {
    return (
      <Box p={8} maxW="md" mx="auto">
        <Heading size="md" mb={4}>Password Reset!</Heading>
        <Text>Redirecting to login...</Text>
      </Box>
    )
  }

  return (
    <Box p={8} maxW="md" mx="auto">
      <Heading size="lg" mb={6}>Set New Password</Heading>
      <VStack gap={4}>
        <Input type="password" placeholder="New Password" value={password} onChange={e=>setPassword(e.target.value)} />
        {err && <Text color="red.500">{err}</Text>}
        <Button colorScheme="blue" w="full" onClick={submit}>Reset Password</Button>
      </VStack>
    </Box>
  )
}
