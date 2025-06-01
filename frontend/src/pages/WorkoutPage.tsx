import React, { useState } from 'react'
import {
  Box,
  Heading,
  Text,
  Button,
  Grid,
  GridItem,
  Select,
  Input,
  VStack,
  HStack,
} from '@chakra-ui/react'

interface Exercise {
  name: string
  sets: number
  reps: string
  rest: string
  notes?: string
}

interface WorkoutPlan {
  name: string
  description: string
  exercises: Exercise[]
  duration_minutes: number
  difficulty: string
  equipment_needed: string[]
  notes?: string
}

export const WorkoutPage = () => {
  const [isGenerating, setIsGenerating] = useState(false)
  const [workoutPlan, setWorkoutPlan] = useState<WorkoutPlan | null>(null)
  const [duration, setDuration] = useState(45)
  const [equipment, setEquipment] = useState('bodyweight')

  const generateWorkout = async () => {
    setIsGenerating(true)
    
    try {
      const response = await fetch('http://localhost:8000/ai/workout-plan', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
        },
        body: JSON.stringify({
          duration_minutes: duration,
          equipment: equipment,
          goals: ['strength', 'fitness'], // Default goals
          focus_areas: []
        })
      })

      if (response.ok) {
        const data = await response.json()
        setWorkoutPlan(data)
      } else {
        throw new Error('Failed to generate workout')
      }
    } catch (error) {
      console.error('Error generating workout:', error)
      alert('Failed to generate workout. Please try again.')
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
        
        <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={4} mb={4}>
          <GridItem>
            <Text mb={2} fontWeight="bold">Duration (minutes)</Text>
            <Input
              type="number"
              value={duration}
              onChange={(e) => setDuration(parseInt(e.target.value))}
              min={15}
              max={120}
            />
          </GridItem>
          
          <GridItem>
            <Text mb={2} fontWeight="bold">Equipment</Text>
            <Select value={equipment} onChange={(e) => setEquipment(e.target.value)}>
              <option value="bodyweight">Bodyweight Only</option>
              <option value="dumbbells">Dumbbells</option>
              <option value="full_gym">Full Gym</option>
              <option value="resistance_bands">Resistance Bands</option>
              <option value="kettlebells">Kettlebells</option>
            </Select>
          </GridItem>
          
          <GridItem display="flex" alignItems="end">
            <Button
              onClick={generateWorkout}
              bg="blue.500"
              color="white"
              size="lg"
              w="full"
              disabled={isGenerating}
              _hover={{ bg: 'blue.600' }}
            >
              {isGenerating ? 'Generating...' : 'Generate Workout'}
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
              <Text fontSize="sm" color="gray.600">Duration: {workoutPlan.duration_minutes} min</Text>
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
          
          {workoutPlan.notes && (
            <Box mt={4} p={4} bg="blue.50" border="1px" borderColor="blue.200" rounded="md">
              <Text fontWeight="bold" mb={2}>Coach Notes:</Text>
              <Text>{workoutPlan.notes}</Text>
            </Box>
          )}
          
          <Box mt={4}>
            <Text fontSize="sm" color="gray.600">
              Equipment needed: {workoutPlan.equipment_needed.join(', ')}
            </Text>
          </Box>
        </Box>
      )}
    </Box>
  )
} 