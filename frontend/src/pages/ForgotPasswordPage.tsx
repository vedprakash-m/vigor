import { Box, Button, Heading, Text, VStack } from '@chakra-ui/react'
import { useNavigate } from 'react-router-dom'

export const ForgotPasswordPage = () => {
  const navigate = useNavigate()

  // With Microsoft Entra ID, password reset is handled by Microsoft
  const handleNavigateToLogin = () => {
    navigate('/login')
  }

  return (
    <Box
      minH="100vh"
      display="flex"
      alignItems="center"
      justifyContent="center"
      bg="gray.50"
    >
      <Box
        maxW="md"
        w="full"
        bg="white"
        rounded="lg"
        boxShadow="lg"
        p={8}
        textAlign="center"
      >
        <VStack gap={6}>
          <Heading size="lg">Password Reset</Heading>
          <Text color="gray.600">
            Password reset is handled by Microsoft Entra ID.
            Please return to the login page and use the "Forgot Password"
            link on the Microsoft login screen.
          </Text>
          <Button
            colorScheme="blue"
            size="lg"
            onClick={handleNavigateToLogin}
            w="full"
          >
            Go to Login
          </Button>
        </VStack>
      </Box>
    </Box>
  )
}
