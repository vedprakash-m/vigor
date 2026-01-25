/**
 * Workouts Page - Your Workout Studio
 * Generate, browse, and execute workouts
 *
 * Design Principle: This page OWNS workout creation and library
 * Features: Quick-start options, AI generator, workout display
 */

import {
    Box,
    Button,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    NativeSelect,
    Spinner,
    Text,
    VStack
} from '@chakra-ui/react'
import { useState } from 'react'
import { api, type Workout } from '../services/api'

type EquipmentType = 'bodyweight' | 'dumbbells' | 'full_gym' | 'resistance_bands' | 'kettlebells'

// Quick-start workout presets
const quickStartOptions = [
  {
    id: 'quick-15',
    name: 'Quick 15',
    emoji: '⚡',
    duration: 15,
    equipment: 'bodyweight' as EquipmentType,
    description: 'No equipment needed'
  },
  {
    id: 'full-body',
    name: 'Full Body',
    emoji: '💪',
    duration: 45,
    equipment: 'bodyweight' as EquipmentType,
    description: 'Complete workout'
  },
  {
    id: 'strength',
    name: 'Strength',
    emoji: '🏋️',
    duration: 60,
    equipment: 'dumbbells' as EquipmentType,
    description: 'Build muscle'
  },
]

export const WorkoutPage = () => {
  const [isGenerating, setIsGenerating] = useState(false)
  const [workoutPlan, setWorkoutPlan] = useState<Workout | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [duration, setDuration] = useState(45)
  const [equipment, setEquipment] = useState<EquipmentType>('bodyweight')
  const [showCustomize, setShowCustomize] = useState(false)

  const generateWorkout = async (presetDuration?: number, presetEquipment?: EquipmentType) => {
    setIsGenerating(true)
    setError(null)

    try {
      const response = await api.workouts.generate({
        durationMinutes: presetDuration || duration,
        equipment: (presetEquipment || equipment) === 'bodyweight' ? [] : [presetEquipment || equipment],
        focusAreas: [],
      })
      setWorkoutPlan(response.data)
      setShowCustomize(false)
    } catch (err) {
      console.error('Error generating workout:', err)
      setError('Failed to generate workout. Please try again.')
    } finally {
      setIsGenerating(false)
    }
  }

  const handleQuickStart = (option: typeof quickStartOptions[0]) => {
    generateWorkout(option.duration, option.equipment)
  }

  return (
    <Box maxW="900px" mx="auto">
      <Heading mb={2}>Workouts</Heading>
      <Text color="gray.600" mb={6}>Generate AI-powered workouts tailored to you</Text>

      {/* Quick Start Options */}
      {!workoutPlan && !showCustomize && (
        <Box mb={8}>
          <Text fontWeight="medium" mb={3} color="gray.700">⚡ Quick Start</Text>
          <Grid templateColumns={{ base: '1fr', sm: 'repeat(3, 1fr)' }} gap={4}>
            {quickStartOptions.map((option) => (
              <Card.Root
                key={option.id}
                bg="white"
                shadow="sm"
                borderRadius="lg"
                cursor="pointer"
                _hover={{ shadow: 'md', transform: 'translateY(-2px)' }}
                transition="all 0.2s"
                onClick={() => handleQuickStart(option)}
              >
                <Card.Body p={4} textAlign="center">
                  <Text fontSize="2xl" mb={2}>{option.emoji}</Text>
                  <Text fontWeight="bold" mb={1}>{option.name}</Text>
                  <Text fontSize="sm" color="gray.500">{option.duration} min</Text>
                  <Text fontSize="xs" color="gray.400">{option.description}</Text>
                </Card.Body>
              </Card.Root>
            ))}
          </Grid>
          <Box textAlign="center" mt={4}>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setShowCustomize(true)}
            >
              Or customize your workout →
            </Button>
          </Box>
        </Box>
      )}

      {/* Custom Workout Generator */}
      {(showCustomize || workoutPlan) && !workoutPlan && (
        <Box bg="white" p={6} rounded="lg" shadow="sm" border="1px" borderColor="gray.200" mb={6}>
          <HStack justify="space-between" mb={4}>
            <Heading size="md">Create Custom Workout</Heading>
            <Button size="sm" variant="ghost" onClick={() => setShowCustomize(false)}>
              ← Back to quick start
            </Button>
          </HStack>

          {error && (
            <Box mb={4} p={3} bg="red.50" border="1px" borderColor="red.200" rounded="md">
              <Text color="red.600">{error}</Text>
            </Box>
          )}

          <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={4} mb={4}>
            <GridItem>
              <Text mb={2} fontWeight="bold">Duration</Text>
              <NativeSelect.Root>
                <NativeSelect.Field
                  value={duration.toString()}
                  onChange={(e) => setDuration(parseInt(e.target.value))}
                >
                  <option value="15">15 min - Quick</option>
                  <option value="30">30 min - Short</option>
                  <option value="45">45 min - Standard</option>
                  <option value="60">60 min - Full</option>
                  <option value="90">90 min - Extended</option>
                </NativeSelect.Field>
              </NativeSelect.Root>
            </GridItem>

            <GridItem>
              <Text mb={2} fontWeight="bold">Equipment</Text>
              <NativeSelect.Root>
                <NativeSelect.Field
                  value={equipment}
                  onChange={(e) => setEquipment(e.target.value as EquipmentType)}
                >
                  <option value="bodyweight">Bodyweight Only</option>
                  <option value="dumbbells">Dumbbells</option>
                  <option value="full_gym">Full Gym</option>
                  <option value="resistance_bands">Resistance Bands</option>
                  <option value="kettlebells">Kettlebells</option>
                </NativeSelect.Field>
              </NativeSelect.Root>
            </GridItem>

            <GridItem display="flex" alignItems="end">
              <Button
                onClick={() => generateWorkout()}
                colorScheme="blue"
                size="lg"
                w="full"
                disabled={isGenerating}
              >
                {isGenerating ? <><Spinner size="sm" mr={2} /> Generating...</> : '✨ Generate Workout'}
              </Button>
            </GridItem>
          </Grid>
        </Box>
      )}

      {/* Loading State */}
      {isGenerating && (
        <Card.Root bg="blue.50" borderColor="blue.200" borderWidth="1px" mb={6}>
          <Card.Body p={8} textAlign="center">
            <Spinner size="xl" color="blue.500" mb={4} />
            <Heading size="md" color="blue.700" mb={2}>Creating your perfect workout...</Heading>
            <Text color="blue.600">Our AI is designing exercises just for you</Text>
          </Card.Body>
        </Card.Root>
      )}

      {/* Generated Workout Display */}
      {workoutPlan && !isGenerating && (
        <Box bg="white" p={6} rounded="lg" shadow="sm" border="1px" borderColor="gray.200">
          <HStack justify="space-between" mb={4} flexWrap="wrap" gap={2}>
            <Box>
              <Heading size="lg">{workoutPlan.name}</Heading>
              <HStack gap={4} mt={1}>
                <Text fontSize="sm" color="gray.600">⏱️ {workoutPlan.durationMinutes} min</Text>
                <Text fontSize="sm" color="gray.600">📊 {workoutPlan.difficulty}</Text>
              </HStack>
            </Box>
            <HStack gap={2}>
              <Button
                size="sm"
                variant="outline"
                onClick={() => setWorkoutPlan(null)}
              >
                ← New Workout
              </Button>
            </HStack>
          </HStack>

          <Text mb={6} color="gray.700">{workoutPlan.description}</Text>

          <Heading size="md" mb={4}>Exercises</Heading>

          <VStack align="stretch" gap={3}>
            {workoutPlan.exercises.map((exercise, index) => (
              <Box
                key={index}
                p={4}
                border="1px"
                borderColor="gray.200"
                rounded="lg"
                bg="gray.50"
              >
                <HStack justify="space-between" mb={2}>
                  <HStack gap={2}>
                    <Box
                      w="28px"
                      h="28px"
                      borderRadius="full"
                      bg="blue.100"
                      color="blue.600"
                      display="flex"
                      alignItems="center"
                      justifyContent="center"
                      fontSize="sm"
                      fontWeight="bold"
                    >
                      {index + 1}
                    </Box>
                    <Heading size="sm">{exercise.name}</Heading>
                  </HStack>
                  <Text fontSize="sm" color="gray.600" fontWeight="medium">
                    {exercise.sets} × {exercise.reps}
                  </Text>
                </HStack>
                <Text fontSize="sm" color="gray.500" mb={1} ml={10}>
                  Rest: {exercise.rest}
                </Text>
                {exercise.notes && (
                  <Text fontSize="sm" color="gray.700" ml={10} fontStyle="italic">{exercise.notes}</Text>
                )}
              </Box>
            ))}
          </VStack>

          {workoutPlan.tips && workoutPlan.tips.length > 0 && (
            <Box mt={6} p={4} bg="blue.50" border="1px" borderColor="blue.200" rounded="lg">
              <Text fontWeight="bold" mb={2} color="blue.700">💡 Coach Tips</Text>
              <VStack align="start" gap={1}>
                {workoutPlan.tips.map((tip, index) => (
                  <Text key={index} fontSize="sm" color="blue.600">• {tip}</Text>
                ))}
              </VStack>
            </Box>
          )}

          {workoutPlan.equipment && workoutPlan.equipment.length > 0 && (
            <Box mt={4}>
              <Text fontSize="sm" color="gray.600">
                🏋️ Equipment needed: {workoutPlan.equipment.join(', ')}
              </Text>
            </Box>
          )}
        </Box>
      )}
    </Box>
  )
}
