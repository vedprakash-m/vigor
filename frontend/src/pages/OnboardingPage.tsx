import {
    Box,
    Button,
    Heading,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useToast } from '../components/compat'
import { useVedAuth } from '../contexts/useVedAuth'

export const OnboardingPage = () => {
  const { user, isAuthenticated } = useVedAuth()
  const navigate = useNavigate()
  const toast = useToast()

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login')
    }
  }, [isAuthenticated, navigate])

  const handleSkipOnboarding = () => {
    toast({
      title: 'Onboarding skipped',
      description: 'You can complete your profile later in settings.',
      status: 'info',
      duration: 3000,
    })
    navigate('/')
  }

  return (
    <Box minH="100vh" bg="gray.50" p={8}>
      <VStack gap={8} maxW="md" mx="auto" pt={20}>
        <Heading color="blue.500" textAlign="center">
          Welcome to Vigor, {user?.name || user?.email}!
        </Heading>

        <Text textAlign="center" color="gray.600">
          Let's set up your fitness profile to personalize your experience.
        </Text>

        <Text textAlign="center" color="gray.500" fontSize="sm">
          Onboarding functionality will be restored after Microsoft Entra ID migration is complete.
        </Text>

        <VStack gap={4} w="full">
          <Button
            colorScheme="blue"
            size="lg"
            w="full"
            onClick={handleSkipOnboarding}
          >
            Continue to Dashboard
          </Button>
        </VStack>
      </VStack>
    </Box>
  )
}
