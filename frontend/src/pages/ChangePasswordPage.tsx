import {
    Box,
    Button,
    Heading,
    Input,
    Text,
    VStack
} from '@chakra-ui/react'
import { useState } from 'react'

export const ChangePasswordPage = () => {
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setSuccess(false)

    // Validation
    if (!currentPassword || !newPassword || !confirmPassword) {
      setError('All fields are required')
      return
    }

    if (newPassword !== confirmPassword) {
      setError('New passwords do not match')
      return
    }

    if (newPassword.length < 8) {
      setError('New password must be at least 8 characters long')
      return
    }

    setLoading(true)

    try {
      // In a real implementation, this would call the backend API
      // await authService.changePassword(currentPassword, newPassword)

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))

      setSuccess(true)
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')

      alert('Password changed successfully!')
    } catch {
      setError('Failed to change password. Please check your current password and try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Box p={8} maxW="400px" mx="auto">
      <Heading size="lg" mb={6}>Change Password</Heading>

      <form onSubmit={handleSubmit}>
        <VStack gap={4} align="stretch">
          {error && (
            <Box p={3} bg="red.100" color="red.700" borderRadius="md" border="1px solid" borderColor="red.300">
              {error}
            </Box>
          )}

          {success && (
            <Box p={3} bg="green.100" color="green.700" borderRadius="md" border="1px solid" borderColor="green.300">
              Password changed successfully!
            </Box>
          )}

          <Box>
            <Text mb={2} fontWeight="medium">Current Password</Text>
            <Input
              type="password"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              placeholder="Enter your current password"
              required
            />
          </Box>

          <Box>
            <Text mb={2} fontWeight="medium">New Password</Text>
            <Input
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="Enter your new password"
              required
            />
            <Text fontSize="sm" color="gray.600" mt={1}>
              Must be at least 8 characters long
            </Text>
          </Box>

          <Box>
            <Text mb={2} fontWeight="medium">Confirm New Password</Text>
            <Input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Confirm your new password"
              required
            />
          </Box>

          <Button
            type="submit"
            colorScheme="blue"
            loading={loading}
            loadingText="Changing Password..."
            mt={4}
          >
            Change Password
          </Button>
        </VStack>
      </form>
    </Box>
  )
}
