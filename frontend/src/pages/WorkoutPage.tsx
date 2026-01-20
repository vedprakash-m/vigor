import {
    Box,
    Button,
    Grid,
    GridItem,
    Heading,
    HStack,
    Text,
    VStack
} from '@chakra-ui/react'
import { useState } from 'react'
import { api, type Workout } from '../services/api'

type EquipmentType = 'bodyweight' | 'dumbbells' | 'full_gym' | 'resistance_bands' | 'kettlebells'

export const WorkoutPage = () => {
  const [isGenerating, setIsGenerating] = useState(false)
  const [workoutPlan, setWorkoutPlan] = useState<Workout | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [duration, setDuration] = useState(45)
  const [equipment, setEquipment] = useState<EquipmentType>('bodyweight')

  const generateWorkout = async () => {
    setIsGenerating(true)
    setError(null)

    try {
      const response = await api.workouts.generate({
        durationMinutes: duration,
        equipment: equipment === 'bodyweight' ? [] : [equipment],
        focusAreas: [],
      })
      setWorkoutPlan(response.data)
    } catch (err) {
      console.error('Error generating workout:', err)
      setError('Failed to generate workout. Please try again.')
    } finally {
      setIsGenerating(false)
    }
  }

  return (
    <Box>
      <Heading mb={6}>Workouts</Heading>

      {/* Workout Generator */}
      <Box bg="white" p={6} rounded="lg" shadow="sm" border="1px" borderColor="gray.200" mb={6}>
        <Heading size="md" mb={4}>Generate AI Workout Plan</Heading>

        {error && (
          <Box mb={4} p={3} bg="red.50" border="1px" borderColor="red.200" rounded="md">
            <Text color="red.600">{error}</Text>
          </Box>
        )}

        <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={4} mb={4}>
          <GridItem>
            <Text mb={2} fontWeight="bold">Duration (minutes)</Text>
            <NativeSelectRoot>
              <NativeSelectField
                value={duration.toString()}
                onChange={(e) => setDuration(parseInt(e.target.value))}
              >
                <option value="15">15 min</option>
                <option value="30">30 min</option>
                <option value="45">45 min</option>
                <option value="60">60 min</option>
                <option value="90">90 min</option>
              </NativeSelectField>
            </NativeSelectRoot>
          </GridItem>

          <GridItem>
            <Text mb={2} fontWeight="bold">Equipment</Text>
            <NativeSelectRoot>
              <NativeSelectField
                value={equipment}
                onChange={(e) => setEquipment(e.target.value as EquipmentType)}
              >
                <option value="bodyweight">Bodyweight Only</option>
                <option value="dumbbells">Dumbbells</option>
                <option value="full_gym">Full Gym</option>
                <option value="resistance_bands">Resistance Bands</option>
                <option value="kettlebells">Kettlebells</option>
              </NativeSelectField>
            </NativeSelectRoot>
          </GridItem>

          <GridItem display="flex" alignItems="end">
            <Button
              onClick={generateWorkout}
              colorScheme="blue"
              size="lg"
              w="full"
              disabled={isGenerating}
            >
              {isGenerating ? <><Spinner size="sm" mr={2} /> Generating...</> : 'Generate Workout'}
            </Button>
          </GridItem>
        </Grid>
      </Box>

      {/* Generated Workout Display */}
      {workoutPlan && (
        <Box bg="white" p={6} rounded="lg" shadow="sm" border="1px" borderColor="gray.200">
          <HStack justify="space-between" mb={4}>
            <Heading size="lg">{workoutPlan.name}</Heading>
            <Box textAlign="right">
              <Text fontSize="sm" color="gray.600">Duration: {workoutPlan.durationMinutes} min</Text>
              <Text fontSize="sm" color="gray.600">Difficulty: {workoutPlan.difficulty}</Text>
            </Box>
          </HStack>

          <Text mb={4} color="gray.700">{workoutPlan.description}</Text>

          <Heading size="md" mb={4}>Exercises</Heading>

          <VStack align="stretch">
            {workoutPlan.exercises.map((exercise, index) => (
              <Box
                key={index}
                p={4}
                border="1px"
                borderColor="gray.200"
                rounded="md"
                bg="gray.50"
              >
                <HStack justify="space-between" mb={2}>
                  <Heading size="sm">{exercise.name}</Heading>
                  <Text fontSize="sm" color="gray.600">
                    {exercise.sets} sets × {exercise.reps}
                  </Text>
                </HStack>
                <Text fontSize="sm" color="gray.600" mb={1}>
                  Rest: {exercise.rest}
                </Text>
                {exercise.notes && (
                  <Text fontSize="sm" color="gray.700">{exercise.notes}</Text>
                )}
              </Box>
            ))}
          </VStack>

          {workoutPlan.tips && workoutPlan.tips.length > 0 && (
            <Box mt={4} p={4} bg="blue.50" border="1px" borderColor="blue.200" rounded="md">
              <Text fontWeight="bold" mb={2}>Coach Tips:</Text>
              <VStack align="start" gap={1}>
                {workoutPlan.tips.map((tip, index) => (
                  <Text key={index} fontSize="sm">• {tip}</Text>
                ))}
              </VStack>
            </Box>
          )}

          {workoutPlan.equipment && workoutPlan.equipment.length > 0 && (
            <Box mt={4}>
              <Text fontSize="sm" color="gray.600">
                Equipment needed: {workoutPlan.equipment.join(', ')}
              </Text>
            </Box>
          )}
        </Box>
      )}
    </Box>
  )
}
