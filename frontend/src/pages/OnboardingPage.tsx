import {
  Box,
  Button,
  Heading,
  HStack,
  VStack,
  Text,
  Progress,
  Checkbox,
  SimpleGrid,
  Card,
  CardBody,
  Badge,
  Slider,
  SliderTrack,
  SliderFilledTrack,
  SliderThumb,
  SliderMark,
  useToast,
  Flex,
} from '@chakra-ui/react'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { authService } from '../services/authService'

// Onboarding step definitions according to UX docs
const ONBOARDING_STEPS = [
  'welcome',
  'goals',
  'experience',
  'equipment',
  'injuries',
  'schedule',
  'complete'
] as const

type OnboardingStep = typeof ONBOARDING_STEPS[number]

interface OnboardingData {
  goals: string[]
  experienceLevel: string
  equipment: string[]
  injuries: string[]
  workoutDays: number
  sessionDuration: number
  skipInjuries: boolean
}

// PRD-specified options
const FITNESS_GOALS = [
  { id: 'weight_loss', label: 'Weight Loss', description: 'Burn fat and lose weight' },
  { id: 'muscle_gain', label: 'Muscle Gain', description: 'Build lean muscle mass' },
  { id: 'strength', label: 'Strength', description: 'Increase overall strength' },
  { id: 'endurance', label: 'Endurance', description: 'Improve cardiovascular health' },
  { id: 'general_fitness', label: 'General Fitness', description: 'Overall health and wellbeing' },
]

const EXPERIENCE_LEVELS = [
  { id: 'beginner', label: 'Beginner', description: 'New to regular exercise' },
  { id: 'intermediate', label: 'Intermediate', description: '1-3 years of experience' },
  { id: 'advanced', label: 'Advanced', description: '3+ years of consistent training' },
]

const EQUIPMENT_OPTIONS = [
  { id: 'none', label: 'None', description: 'Bodyweight only' },
  { id: 'basic', label: 'Basic', description: 'Dumbbells, resistance bands' },
  { id: 'moderate', label: 'Moderate', description: 'Home gym setup' },
  { id: 'full_gym', label: 'Full Gym', description: 'Complete gym access' },
]

const COMMON_INJURIES = [
  'Lower back pain',
  'Knee issues',
  'Shoulder problems',
  'Wrist/hand issues',
  'Ankle problems',
  'Neck pain',
]

export const OnboardingPage = () => {
  const [currentStep, setCurrentStep] = useState<OnboardingStep>('welcome')
  const [data, setData] = useState<OnboardingData>({
    goals: [],
    experienceLevel: '',
    equipment: [],
    injuries: [],
    workoutDays: 3,
    sessionDuration: 30,
    skipInjuries: false,
  })
  const [isLoading, setIsLoading] = useState(false)
  const navigate = useNavigate()
  const toast = useToast()

  const currentStepIndex = ONBOARDING_STEPS.indexOf(currentStep)
  const progress = ((currentStepIndex + 1) / ONBOARDING_STEPS.length) * 100

  const handleNext = () => {
    const nextIndex = currentStepIndex + 1
    if (nextIndex < ONBOARDING_STEPS.length) {
      setCurrentStep(ONBOARDING_STEPS[nextIndex])
    }
  }

  const handleBack = () => {
    const prevIndex = currentStepIndex - 1
    if (prevIndex >= 0) {
      setCurrentStep(ONBOARDING_STEPS[prevIndex])
    }
  }

  const handleComplete = async () => {
    setIsLoading(true)
    try {
      // TODO: Send onboarding data to backend
      await authService.updateProfile({
        fitness_goals: data.goals,
        experience_level: data.experienceLevel,
        available_equipment: data.equipment,
        injury_considerations: data.skipInjuries ? [] : data.injuries,
        workout_days_per_week: data.workoutDays,
        preferred_session_duration: data.sessionDuration,
        onboarding_completed: true,
      })

      toast({
        title: 'Welcome to Vigor!',
        description: 'Your profile has been set up. Let\'s get started!',
        status: 'success',
        duration: 3000,
      })

      navigate('/dashboard')
    } catch (error) {
      toast({
        title: 'Setup Error',
        description: 'Failed to save your preferences. Please try again.',
        status: 'error',
        duration: 5000,
      })
    } finally {
      setIsLoading(false)
    }
  }

  const canProceed = () => {
    switch (currentStep) {
      case 'goals':
        return data.goals.length > 0
      case 'experience':
        return data.experienceLevel !== ''
      case 'equipment':
        return data.equipment.length > 0
      case 'injuries':
        return data.skipInjuries || data.injuries.length > 0
      default:
        return true
    }
  }

  const renderStepContent = () => {
    switch (currentStep) {
      case 'welcome':
        return (
          <VStack spacing={6} textAlign="center">
            <Heading size="xl" color="blue.500">Welcome to Vigor!</Heading>
            <Text fontSize="lg" color="gray.600" maxW="md">
              Your AI-powered fitness coach with multi-provider intelligence for personalized,
              reliable workout guidance.
            </Text>
            <VStack spacing={4} align="start" maxW="md">
              <HStack>
                <Badge colorScheme="blue">OpenAI</Badge>
                <Badge colorScheme="green">Gemini</Badge>
                <Badge colorScheme="purple">Perplexity</Badge>
                <Text fontSize="sm">Multi-provider AI for 99.9% uptime</Text>
              </HStack>
              <Text fontSize="sm" color="gray.500">
                Let's set up your personalized fitness profile in just 2 minutes.
              </Text>
            </VStack>
          </VStack>
        )

      case 'goals':
        return (
          <VStack spacing={6}>
            <VStack spacing={2} textAlign="center">
              <Heading size="lg">What are your fitness goals?</Heading>
              <Text color="gray.600">Select all that apply</Text>
            </VStack>
            <SimpleGrid columns={{ base: 1, md: 2 }} spacing={4} w="full" maxW="2xl">
              {FITNESS_GOALS.map((goal) => (
                <Card
                  key={goal.id}
                  cursor="pointer"
                  border={data.goals.includes(goal.id) ? "2px solid" : "1px solid"}
                  borderColor={data.goals.includes(goal.id) ? "blue.500" : "gray.200"}
                  bg={data.goals.includes(goal.id) ? "blue.50" : "white"}
                  onClick={() => {
                    const newGoals = data.goals.includes(goal.id)
                      ? data.goals.filter(g => g !== goal.id)
                      : [...data.goals, goal.id]
                    setData({ ...data, goals: newGoals })
                  }}
                  _hover={{ borderColor: "blue.300" }}
                >
                  <CardBody>
                    <VStack align="start" spacing={2}>
                      <Text fontWeight="bold">{goal.label}</Text>
                      <Text fontSize="sm" color="gray.600">{goal.description}</Text>
                    </VStack>
                  </CardBody>
                </Card>
              ))}
            </SimpleGrid>
          </VStack>
        )

      case 'experience':
        return (
          <VStack spacing={6}>
            <VStack spacing={2} textAlign="center">
              <Heading size="lg">What's your experience level?</Heading>
              <Text color="gray.600">This helps us customize your workouts</Text>
            </VStack>
            <VStack spacing={4} w="full" maxW="lg">
              {EXPERIENCE_LEVELS.map((level) => (
                <Card
                  key={level.id}
                  cursor="pointer"
                  border={data.experienceLevel === level.id ? "2px solid" : "1px solid"}
                  borderColor={data.experienceLevel === level.id ? "blue.500" : "gray.200"}
                  bg={data.experienceLevel === level.id ? "blue.50" : "white"}
                  onClick={() => setData({ ...data, experienceLevel: level.id })}
                  _hover={{ borderColor: "blue.300" }}
                  w="full"
                >
                  <CardBody>
                    <HStack justify="space-between">
                      <VStack align="start" spacing={1}>
                        <Text fontWeight="bold">{level.label}</Text>
                        <Text fontSize="sm" color="gray.600">{level.description}</Text>
                      </VStack>
                    </HStack>
                  </CardBody>
                </Card>
              ))}
            </VStack>
          </VStack>
        )

      case 'equipment':
        return (
          <VStack spacing={6}>
            <VStack spacing={2} textAlign="center">
              <Heading size="lg">What equipment do you have access to?</Heading>
              <Text color="gray.600">Select all that apply</Text>
            </VStack>
            <SimpleGrid columns={{ base: 1, md: 2 }} spacing={4} w="full" maxW="2xl">
              {EQUIPMENT_OPTIONS.map((equipment) => (
                <Card
                  key={equipment.id}
                  cursor="pointer"
                  border={data.equipment.includes(equipment.id) ? "2px solid" : "1px solid"}
                  borderColor={data.equipment.includes(equipment.id) ? "blue.500" : "gray.200"}
                  bg={data.equipment.includes(equipment.id) ? "blue.50" : "white"}
                  onClick={() => {
                    const newEquipment = data.equipment.includes(equipment.id)
                      ? data.equipment.filter(e => e !== equipment.id)
                      : [...data.equipment, equipment.id]
                    setData({ ...data, equipment: newEquipment })
                  }}
                  _hover={{ borderColor: "blue.300" }}
                >
                  <CardBody>
                    <VStack align="start" spacing={2}>
                      <Text fontWeight="bold">{equipment.label}</Text>
                      <Text fontSize="sm" color="gray.600">{equipment.description}</Text>
                    </VStack>
                  </CardBody>
                </Card>
              ))}
            </SimpleGrid>
          </VStack>
        )

      case 'injuries':
        return (
          <VStack spacing={6}>
            <VStack spacing={2} textAlign="center">
              <Heading size="lg">Any injuries or limitations?</Heading>
              <Text color="gray.600">We'll modify exercises accordingly</Text>
            </VStack>
            <VStack spacing={4} w="full" maxW="lg">
              <Checkbox
                isChecked={data.skipInjuries}
                onChange={(e) => setData({ ...data, skipInjuries: e.target.checked, injuries: [] })}
                colorScheme="blue"
              >
                No injuries or limitations
              </Checkbox>
              {!data.skipInjuries && (
                <SimpleGrid columns={{ base: 1, md: 2 }} spacing={3} w="full">
                  {COMMON_INJURIES.map((injury) => (
                    <Checkbox
                      key={injury}
                      isChecked={data.injuries.includes(injury)}
                      onChange={(e) => {
                        const newInjuries = e.target.checked
                          ? [...data.injuries, injury]
                          : data.injuries.filter(i => i !== injury)
                        setData({ ...data, injuries: newInjuries })
                      }}
                      colorScheme="blue"
                    >
                      {injury}
                    </Checkbox>
                  ))}
                </SimpleGrid>
              )}
            </VStack>
          </VStack>
        )

      case 'schedule':
        return (
          <VStack spacing={8}>
            <VStack spacing={2} textAlign="center">
              <Heading size="lg">Your workout schedule</Heading>
              <Text color="gray.600">How often and how long do you want to work out?</Text>
            </VStack>
            <VStack spacing={8} w="full" maxW="lg">
              <Box w="full">
                <Text fontWeight="bold" mb={4}>Workouts per week: {data.workoutDays}</Text>
                <Slider
                  value={data.workoutDays}
                  onChange={(value) => setData({ ...data, workoutDays: value })}
                  min={1}
                  max={7}
                  step={1}
                  colorScheme="blue"
                >
                  <SliderMark value={1} mt={2} fontSize="sm">1</SliderMark>
                  <SliderMark value={3} mt={2} fontSize="sm">3</SliderMark>
                  <SliderMark value={5} mt={2} fontSize="sm">5</SliderMark>
                  <SliderMark value={7} mt={2} fontSize="sm">7</SliderMark>
                  <SliderTrack>
                    <SliderFilledTrack />
                  </SliderTrack>
                  <SliderThumb />
                </Slider>
              </Box>
              <Box w="full">
                <Text fontWeight="bold" mb={4}>Session duration: {data.sessionDuration} minutes</Text>
                <Slider
                  value={data.sessionDuration}
                  onChange={(value) => setData({ ...data, sessionDuration: value })}
                  min={15}
                  max={90}
                  step={15}
                  colorScheme="blue"
                >
                  <SliderMark value={15} mt={2} fontSize="sm">15m</SliderMark>
                  <SliderMark value={30} mt={2} fontSize="sm">30m</SliderMark>
                  <SliderMark value={60} mt={2} fontSize="sm">60m</SliderMark>
                  <SliderMark value={90} mt={2} fontSize="sm">90m</SliderMark>
                  <SliderTrack>
                    <SliderFilledTrack />
                  </SliderTrack>
                  <SliderThumb />
                </Slider>
              </Box>
            </VStack>
          </VStack>
        )

      case 'complete':
        return (
          <VStack spacing={6} textAlign="center">
            <Heading size="xl" color="green.500">All Set!</Heading>
            <Text fontSize="lg" color="gray.600" maxW="md">
              Your personalized AI coach is ready to help you achieve your fitness goals.
            </Text>
            <VStack spacing={3} align="start" maxW="md">
              <Text><strong>Goals:</strong> {data.goals.join(', ')}</Text>
              <Text><strong>Level:</strong> {data.experienceLevel}</Text>
              <Text><strong>Equipment:</strong> {data.equipment.join(', ')}</Text>
              <Text><strong>Schedule:</strong> {data.workoutDays} days/week, {data.sessionDuration}min sessions</Text>
            </VStack>
            <Text fontSize="sm" color="gray.500">
              You can always update these preferences in your profile.
            </Text>
          </VStack>
        )

      default:
        return null
    }
  }

  return (
    <Box minH="100vh" bg="gray.50" py={8}>
      <VStack spacing={8} maxW="4xl" mx="auto" px={6}>
        {/* Progress Bar */}
        <Box w="full" maxW="md">
          <Progress value={progress} colorScheme="blue" size="lg" borderRadius="full" />
          <Flex justify="space-between" mt={2} fontSize="sm" color="gray.500">
            <Text>Step {currentStepIndex + 1} of {ONBOARDING_STEPS.length}</Text>
            <Text>{Math.round(progress)}% complete</Text>
          </Flex>
        </Box>

        {/* Step Content */}
        <Box w="full" minH="60vh" py={8}>
          {renderStepContent()}
        </Box>

        {/* Navigation */}
        <HStack spacing={4} w="full" maxW="md" justify="space-between">
          <Button
            variant="ghost"
            onClick={handleBack}
            isDisabled={currentStep === 'welcome'}
          >
            Back
          </Button>

          {currentStep === 'complete' ? (
            <Button
              colorScheme="blue"
              onClick={handleComplete}
              isLoading={isLoading}
              loadingText="Setting up..."
              size="lg"
            >
              Complete Setup
            </Button>
          ) : (
            <Button
              colorScheme="blue"
              onClick={handleNext}
              isDisabled={!canProceed()}
              size="lg"
            >
              {currentStep === 'schedule' ? 'Review' : 'Next'}
            </Button>
          )}
        </HStack>
      </VStack>
    </Box>
  )
}

  return (
    <Box p={8} maxW="lg" mx="auto">
      <Heading mb={4}>Step 1: Select Your Primary Goal</Heading>
      <Text mb={4}>Choose one or more fitness goals. Start typing to search.</Text>
      <Input placeholder="e.g., Weight Loss" value={query} onChange={e=>onChange(e.target.value)} mb={4} />

      <VStack align="start" mb={4}>
        {suggestions.slice(0,5).map(s => (
          <Button key={s} size="sm" variant="ghost" onClick={() => addGoal(s)}>{s}</Button>
        ))}
      </VStack>

      <VStack align="start" mb={6}>
        {selected.map(goal => (
          <HStack key={goal} bg="blue.100" borderRadius="md" px={2} py={1}>
            <Text fontSize="sm">{goal}</Text>
            <CloseButton size="sm" onClick={() => removeGoal(goal)} />
          </HStack>
        ))}
      </VStack>

      <Button colorScheme="blue" disabled={selected.length===0} onClick={()=>setShowConsent(true)}>Continue</Button>

      {showConsent && (
        <Box position="fixed" top={0} left={0} right={0} bottom={0} bg="blackAlpha.600" zIndex={1000} display="flex" alignItems="center" justifyContent="center">
          <Box bg="white" p={6} borderRadius="md" maxW="sm" w="90%">
            <Heading size="md" mb={4}>Data Consent</Heading>
            <Text fontSize="sm" mb={6}>We use your data to personalise your workout plans in accordance with GDPR Article 13. Do you consent?</Text>
            <HStack justifyContent="flex-end">
              <Button variant="ghost" onClick={()=>setShowConsent(false)}>Decline</Button>
              <Button colorScheme="blue" onClick={handleAcceptConsent}>Accept & Continue</Button>
            </HStack>
          </Box>
        </Box>
      )}
    </Box>
  )
}
