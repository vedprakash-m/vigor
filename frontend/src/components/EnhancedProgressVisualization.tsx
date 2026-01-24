/**
 * Enhanced Progress Visualization Component
 * Advanced charts and progress tracking for fitness goals
 */

import {
    Box,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    Progress,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useState } from 'react'

interface ProgressData {
    date: string
    workouts: number
    minutes: number
    calories: number
}

interface Milestone {
    id: string
    title: string
    description: string
    target: number
    current: number
    unit: string
    completed: boolean
}

const mockProgressData: ProgressData[] = Array.from({ length: 30 }, (_, i) => ({
    date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    workouts: Math.floor(Math.random() * 2),
    minutes: Math.floor(Math.random() * 60) + 15,
    calories: Math.floor(Math.random() * 400) + 100,
}))

const mockMilestones: Milestone[] = [
    {
        id: '1',
        title: 'First Workout',
        description: 'Complete your first AI-generated workout',
        target: 1,
        current: 1,
        unit: 'workout',
        completed: true,
    },
    {
        id: '2',
        title: 'Week Warrior',
        description: 'Complete 7 workouts',
        target: 7,
        current: 7,
        unit: 'workouts',
        completed: true,
    },
    {
        id: '3',
        title: 'Consistency King',
        description: 'Maintain a 7-day streak',
        target: 7,
        current: 5,
        unit: 'days',
        completed: false,
    },
    {
        id: '4',
        title: 'Marathon Month',
        description: 'Complete 20 workouts in a month',
        target: 20,
        current: 12,
        unit: 'workouts',
        completed: false,
    },
]

const EnhancedProgressVisualization = () => {
    const [progressData] = useState<ProgressData[]>(mockProgressData)
    const [milestones] = useState<Milestone[]>(mockMilestones)

    // Calculate stats
    const totalWorkouts = progressData.reduce((sum, d) => sum + d.workouts, 0)
    const totalMinutes = progressData.reduce((sum, d) => sum + (d.workouts > 0 ? d.minutes : 0), 0)
    const totalCalories = progressData.reduce((sum, d) => sum + (d.workouts > 0 ? d.calories : 0), 0)
    const avgMinutesPerWorkout = totalWorkouts > 0 ? Math.round(totalMinutes / totalWorkouts) : 0

    // Calculate streak
    let currentStreak = 0
    for (let i = progressData.length - 1; i >= 0; i--) {
        if (progressData[i].workouts > 0) {
            currentStreak++
        } else {
            break
        }
    }

    // Get max for chart scaling
    const maxCalories = Math.max(...progressData.map((d) => d.calories))

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">Progress</Heading>
                <Text color="gray.600">
                    Track your fitness journey over time
                </Text>
            </VStack>

            {/* Summary Stats */}
            <Grid templateColumns={{ base: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }} gap={4} mb={8}>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" color="gray.500">
                                30-Day Workouts
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold" color="blue.500">
                                {totalWorkouts}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" color="gray.500">
                                Total Minutes
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold" color="green.500">
                                {totalMinutes}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" color="gray.500">
                                Calories Burned
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold" color="orange.500">
                                {totalCalories.toLocaleString()}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" color="gray.500">
                                Current Streak
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold" color="purple.500">
                                {currentStreak} 🔥
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>

            {/* Activity Calendar (simplified) */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={8}>
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        30-Day Activity
                    </Heading>
                    <Box overflowX="auto">
                        <HStack gap={1} minW="600px">
                            {progressData.map((day) => (
                                <Box
                                    key={day.date}
                                    w="18px"
                                    h="18px"
                                    borderRadius="sm"
                                    bg={
                                        day.workouts === 0
                                            ? 'gray.100'
                                            : day.calories > maxCalories * 0.7
                                            ? 'green.500'
                                            : day.calories > maxCalories * 0.4
                                            ? 'green.300'
                                            : 'green.200'
                                    }
                                    title={`${day.date}: ${day.workouts} workout(s), ${day.calories} cal`}
                                    cursor="pointer"
                                />
                            ))}
                        </HStack>
                        <HStack justify="space-between" mt={2}>
                            <Text fontSize="xs" color="gray.500">
                                30 days ago
                            </Text>
                            <Text fontSize="xs" color="gray.500">
                                Today
                            </Text>
                        </HStack>
                    </Box>
                </Card.Body>
            </Card.Root>

            {/* Milestones */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={8}>
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Milestones
                    </Heading>
                    <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)' }} gap={4}>
                        {milestones.map((milestone) => (
                            <Box
                                key={milestone.id}
                                p={4}
                                bg={milestone.completed ? 'green.50' : 'gray.50'}
                                borderRadius="lg"
                                border="1px"
                                borderColor={milestone.completed ? 'green.200' : 'gray.200'}
                            >
                                <HStack justify="space-between" mb={2}>
                                    <Text fontWeight="bold">
                                        {milestone.completed && '✅ '}
                                        {milestone.title}
                                    </Text>
                                    <Text fontSize="sm" color="gray.500">
                                        {milestone.current}/{milestone.target} {milestone.unit}
                                    </Text>
                                </HStack>
                                <Text fontSize="sm" color="gray.600" mb={3}>
                                    {milestone.description}
                                </Text>
                                <Progress.Root
                                    value={(milestone.current / milestone.target) * 100}
                                    size="sm"
                                    colorPalette={milestone.completed ? 'green' : 'blue'}
                                >
                                    <Progress.Track borderRadius="full">
                                        <Progress.Range />
                                    </Progress.Track>
                                </Progress.Root>
                            </Box>
                        ))}
                    </Grid>
                </Card.Body>
            </Card.Root>

            {/* Weekly Trend */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Weekly Summary
                    </Heading>
                    <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={6}>
                        <Box>
                            <Text fontWeight="medium" mb={2}>
                                Average Workout Duration
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold" color="blue.500">
                                {avgMinutesPerWorkout} min
                            </Text>
                            <Text fontSize="sm" color="gray.500">
                                per session
                            </Text>
                        </Box>
                        <Box>
                            <Text fontWeight="medium" mb={2}>
                                Weekly Consistency
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold" color="green.500">
                                {Math.round((totalWorkouts / 30) * 100)}%
                            </Text>
                            <Text fontSize="sm" color="gray.500">
                                workout days
                            </Text>
                        </Box>
                        <Box>
                            <Text fontWeight="medium" mb={2}>
                                Calories per Workout
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold" color="orange.500">
                                {totalWorkouts > 0 ? Math.round(totalCalories / totalWorkouts) : 0}
                            </Text>
                            <Text fontSize="sm" color="gray.500">
                                average burned
                            </Text>
                        </Box>
                    </Grid>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default EnhancedProgressVisualization
