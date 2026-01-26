/**
 * Enhanced Progress Visualization Component
 * Advanced charts and progress tracking for fitness goals
 * Uses real data from the backend API
 */

import {
    Box,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    Progress,
    Spinner,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import api, { WorkoutLog } from '../services/api'

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

// Helper function to estimate calories burned based on duration and intensity
const estimateCalories = (durationMinutes: number, rating?: number): number => {
    // Average calories per minute ranges from 5-10 depending on intensity
    const caloriesPerMinute = rating ? 5 + (rating / 5) * 5 : 7
    return Math.round(durationMinutes * caloriesPerMinute)
}

// Helper function to calculate streak from progress data
const calculateStreak = (progressData: ProgressData[]): number => {
    let streak = 0
    // Start from today and go backwards
    for (let i = progressData.length - 1; i >= 0; i--) {
        if (progressData[i].workouts > 0) {
            streak++
        } else {
            break
        }
    }
    return streak
}

// Helper function to calculate milestones from workout data
const calculateMilestones = (
    totalWorkouts: number,
    currentStreak: number,
    monthlyWorkouts: number
): Milestone[] => {
    return [
        {
            id: '1',
            title: 'First Workout',
            description: 'Complete your first AI-generated workout',
            target: 1,
            current: Math.min(totalWorkouts, 1),
            unit: 'workout',
            completed: totalWorkouts >= 1,
        },
        {
            id: '2',
            title: 'Week Warrior',
            description: 'Complete 7 workouts',
            target: 7,
            current: Math.min(totalWorkouts, 7),
            unit: 'workouts',
            completed: totalWorkouts >= 7,
        },
        {
            id: '3',
            title: 'Consistency King',
            description: 'Maintain a 7-day streak',
            target: 7,
            current: Math.min(currentStreak, 7),
            unit: 'days',
            completed: currentStreak >= 7,
        },
        {
            id: '4',
            title: 'Marathon Month',
            description: 'Complete 20 workouts in a month',
            target: 20,
            current: Math.min(monthlyWorkouts, 20),
            unit: 'workouts',
            completed: monthlyWorkouts >= 20,
        },
    ]
}

const EnhancedProgressVisualization = () => {
    const [progressData, setProgressData] = useState<ProgressData[]>([])
    const [milestones, setMilestones] = useState<Milestone[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        const fetchProgressData = async () => {
            try {
                setLoading(true)
                setError(null)

                // Fetch workout history from the backend
                const response = await api.workouts.history(100)
                const logs: WorkoutLog[] = response.data || []

                // Create a map of dates to workout data for the last 30 days
                const dateMap = new Map<string, ProgressData>()

                // Initialize all 30 days with zero values
                for (let i = 0; i < 30; i++) {
                    const date = new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000)
                    const dateStr = date.toISOString().split('T')[0]
                    dateMap.set(dateStr, {
                        date: dateStr,
                        workouts: 0,
                        minutes: 0,
                        calories: 0,
                    })
                }

                // Populate with actual workout data
                logs.forEach((log) => {
                    const dateStr = new Date(log.completedAt).toISOString().split('T')[0]
                    const existing = dateMap.get(dateStr)
                    if (existing) {
                        existing.workouts += 1
                        existing.minutes += log.actualDuration || 0
                        existing.calories += estimateCalories(log.actualDuration || 0, log.rating)
                    }
                })

                // Convert map to sorted array
                const progressArray = Array.from(dateMap.values()).sort(
                    (a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()
                )

                setProgressData(progressArray)

                // Calculate totals and milestones
                const totalWorkouts = logs.length
                const currentStreak = calculateStreak(progressArray)

                // Calculate monthly workouts (workouts in the last 30 days)
                const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
                const monthlyWorkouts = logs.filter(
                    (log) => new Date(log.completedAt) >= thirtyDaysAgo
                ).length

                setMilestones(calculateMilestones(totalWorkouts, currentStreak, monthlyWorkouts))
            } catch (err) {
                console.error('Error fetching progress data:', err)
                setError('Failed to load progress data')
            } finally {
                setLoading(false)
            }
        }

        fetchProgressData()
    }, [])

    // Calculate stats from progress data
    const totalWorkouts = progressData.reduce((sum, d) => sum + d.workouts, 0)
    const totalMinutes = progressData.reduce((sum, d) => sum + d.minutes, 0)
    const totalCalories = progressData.reduce((sum, d) => sum + d.calories, 0)
    const avgMinutesPerWorkout = totalWorkouts > 0 ? Math.round(totalMinutes / totalWorkouts) : 0
    const currentStreak = calculateStreak(progressData)

    // Get max for chart scaling
    const maxCalories = Math.max(...progressData.map((d) => d.calories), 1)

    if (loading) {
        return (
            <Box p={6} display="flex" justifyContent="center" alignItems="center" minH="400px">
                <VStack gap={4}>
                    <Spinner size="xl" color="blue.500" />
                    <Text color="gray.500">Loading your progress...</Text>
                </VStack>
            </Box>
        )
    }

    if (error) {
        return (
            <Box p={6}>
                <VStack align="center" gap={4}>
                    <Text color="red.500">{error}</Text>
                    <Text color="gray.500">Please try refreshing the page.</Text>
                </VStack>
            </Box>
        )
    }

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
