import { useMsal } from '@azure/msal-react'
import { Box, Button, Center, Text, VStack } from '@chakra-ui/react'
import { useNavigate } from 'react-router-dom'
import { loginRequest } from '../config/authConfig'

export const RegisterPage = () => {
  const navigate = useNavigate()
  const { instance } = useMsal()

  const handleRegister = async () => {
    try {
      await instance.loginPopup(loginRequest)
      navigate('/app/onboarding')
    } catch (error) {
      console.error('Registration failed:', error)
    }
  }

  return (
    <Center minH="100vh" bg="gray.50">
      <Box
        maxW="md"
        w="full"
        bg="white"
        rounded="lg"
        boxShadow="lg"
        p={6}
        textAlign="center"
      >
        <VStack gap={6}>
          <Text fontSize="2xl" fontWeight="bold">
            Join Vigor
          </Text>
          <Text color="gray.600">
            Get started with your fitness journey using Microsoft Entra ID
          </Text>
          <Button
            colorScheme="blue"
            size="lg"
            onClick={handleRegister}
            w="full"
          >
            Sign Up with Microsoft
          </Button>
          <Text fontSize="sm" color="gray.500">
            Already have an account?{' '}
            <Button
              variant="ghost"
              color="blue.500"
              onClick={() => navigate('/login')}
              size="sm"
              p={0}
              minW="auto"
              h="auto"
            >
              Sign In
            </Button>
          </Text>
        </VStack>
      </Box>
    </Center>
  )
}
