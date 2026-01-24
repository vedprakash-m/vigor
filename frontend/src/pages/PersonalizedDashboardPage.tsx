/**
 * Personalized Dashboard Page
 * Main dashboard for authenticated users with fitness metrics and AI insights
 */

import {
    Box,
    Button,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    Progress,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { Link as RouterLink } from 'react-router-dom'
import LLMStatus from '../components/LLMStatus'
import { useVedAuth } from '../contexts/useVedAuth'
import { api, type UserStats, type WorkoutLog } from '../services/api'

interface DashboardMetrics {
    totalWorkouts: number
    weeklyWorkouts: number
    currentStreak: number
    longestStreak: number
    weeklyGoal: number
    caloriesBurned: number
}

interface StatCardProps {
    title: string
    value: string | number
    subtitle?: string
    color?: string
}

const StatCard = ({ title, value, subtitle, color = 'blue.500' }: StatCardProps) => (
    <Card.Root bg="white" shadow="sm" borderRadius="lg">
        <Card.Body p={6}>
            <VStack align="start" gap={2}>
                <Text fontSize="sm" color="gray.500" fontWeight="medium">
                    {title}
                </Text>
                <Text fontSize="3xl" fontWeight="bold" color={color}>
                    {value}
                </Text>
                {subtitle && (
                    <Text fontSize="sm" color="gray.400">
                        {subtitle}
                    </Text>
                )}
            </VStack>
        </Card.Body>
    </Card.Root>
)

const PersonalizedDashboardPage = () => {
    const { user } = useVedAuth()
    const [metrics, setMetrics] = useState<DashboardMetrics>({
        totalWorkouts: 0,
        weeklyWorkouts: 0,
        currentStreak: 0,
        longestStreak: 0,
        weeklyGoal: 4,
        caloriesBurned: 0,
    })
    const [recentWorkouts, setRecentWorkouts] = useState<WorkoutLog[]>([])
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        const fetchDashboardData = async () => {
            try {
                setIsLoading(true)

                // Fetch user profile with stats
                const profileResponse = await api.users.getProfile()
                const userStats: UserStats = profileResponse.data?.stats || {
                    totalWorkouts: 0,
                    currentStreak: 0,
                    longestStreak: 0,
                }

                // Fetch recent workout logs
                const logsResponse = await api.workouts.history(10)
                const logs: WorkoutLog[] = logsResponse.data || []
                setRecentWorkouts(logs)

                // Calculate weekly workouts
                const weekAgo = new Date()
                weekAgo.setDate(weekAgo.getDate() - 7)
                const weeklyWorkouts = logs.filter(
                    (log) => new Date(log.completedAt) >= weekAgo
                ).length

                // Estimate calories (rough calculation)
                const estimatedCalories = logs.slice(0, 7).reduce(
                    (acc, log) => acc + (log.actualDuration || 30) * 8,
                    0
                )

                setMetrics({
                    totalWorkouts: userStats.totalWorkouts,
                    weeklyWorkouts,
                    currentStreak: userStats.currentStreak,
                    longestStreak: userStats.longestStreak,
                    weeklyGoal: 4,
                    caloriesBurned: estimatedCalories,
                })
            } catch (error) {
                console.error('Failed to fetch dashboard data:', error)
            } finally {
                setIsLoading(false)
            }
        }

        fetchDashboardData()
    }, [])

    const weeklyProgress = Math.min(
        (metrics.weeklyWorkouts / metrics.weeklyGoal) * 100,
        100
    )

    return (
        <Box p={6}>
            {/* Welcome Header */}
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">
                    Welcome back{user?.name ? `, ${user.name.split(' ')[0]}` : ''}! 👋
                </Heading>
                <Text color="gray.600" fontSize="lg">
                    {user?.tier === 'premium' || user?.tier === 'enterprise'
                        ? "Let's crush your fitness goals with AI-powered insights"
                        : "Let's keep building healthy habits together"}
                </Text>
            </VStack>

            {/* AI Status */}
            <Box mb={6}>
                <LLMStatus />
            </Box>

            {/* Stats Grid */}
            <Grid
                templateColumns={{
                    base: 'repeat(2, 1fr)',
                    md: 'repeat(4, 1fr)',
                }}
                gap={4}
                mb={8}
            >
                <GridItem>
                    <StatCard
                        title="Total Workouts"
                        value={metrics.totalWorkouts}
                        subtitle="All time"
                    />
                </GridItem>
                <GridItem>
                    <StatCard
                        title="This Week"
                        value={metrics.weeklyWorkouts}
                        subtitle={`Goal: ${metrics.weeklyGoal}`}
                        color="green.500"
                    />
                </GridItem>
                <GridItem>
                    <StatCard
                        title="Current Streak"
                        value={`${metrics.currentStreak} 🔥`}
                        subtitle={`Best: ${metrics.longestStreak}`}
                        color="orange.500"
                    />
                </GridItem>
                <GridItem>
                    <StatCard
                        title="Calories Burned"
                        value={metrics.caloriesBurned}
                        subtitle="This week (est.)"
                        color="red.500"
                    />
                </GridItem>
            </Grid>

            {/* Weekly Progress */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={8}>
                <Card.Body p={6}>
                    <HStack justify="space-between" mb={4}>
                        <Heading size="md">Weekly Goal Progress</Heading>
                        <Text fontWeight="bold" color="blue.500">
                            {metrics.weeklyWorkouts}/{metrics.weeklyGoal} workouts
                        </Text>
                    </HStack>
                    <Progress.Root value={weeklyProgress} size="lg" colorPalette="blue">
                        <Progress.Track borderRadius="full">
                            <Progress.Range />
                        </Progress.Track>
                    </Progress.Root>
                    {weeklyProgress >= 100 && (
                        <Text mt={2} color="green.500" fontWeight="medium">
                            🎉 Weekly goal achieved! Keep going!
                        </Text>
                    )}
                </Card.Body>
            </Card.Root>

            {/* Quick Actions */}
            <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)' }} gap={6} mb={8}>
                <Card.Root bg="gradient-to-r" bgGradient="linear(to-r, blue.500, blue.600)" color="white" shadow="md" borderRadius="lg">
                    <Card.Body p={6}>
                        <Heading size="md" mb={2}>
                            Generate AI Workout
                        </Heading>
                        <Text mb={4} opacity={0.9}>
                            Get a personalized workout plan powered by OpenAI
                        </Text>
                        <RouterLink to="/workouts">
                            <Button
                                variant="solid"
                                bg="white"
                                color="blue.500"
                                _hover={{ bg: 'gray.100' }}
                            >
                                Start Workout →
                            </Button>
                        </RouterLink>
                    </Card.Body>
                </Card.Root>

                <Card.Root bg="gradient-to-r" bgGradient="linear(to-r, purple.500, purple.600)" color="white" shadow="md" borderRadius="lg">
                    <Card.Body p={6}>
                        <Heading size="md" mb={2}>
                            AI Fitness Coach
                        </Heading>
                        <Text mb={4} opacity={0.9}>
                            Chat with your personal AI coach for advice
                        </Text>
                        <RouterLink to="/coach">
                            <Button
                                variant="solid"
                                bg="white"
                                color="purple.500"
                                _hover={{ bg: 'gray.100' }}
                            >
                                Chat with Coach →
                            </Button>
                        </RouterLink>
                    </Card.Body>
                </Card.Root>
            </Grid>

            {/* Recent Workouts */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={6}>
                    <HStack justify="space-between" mb={4}>
                        <Heading size="md">Recent Workouts</Heading>
                        <RouterLink to="/app/progress">
                            <Button variant="ghost" size="sm">
                                View All →
                            </Button>
                        </RouterLink>
                    </HStack>
                    {isLoading ? (
                        <Text color="gray.500">Loading...</Text>
                    ) : recentWorkouts.length > 0 ? (
                        <VStack align="stretch" gap={3}>
                            {recentWorkouts.slice(0, 5).map((workout) => (
                                <HStack
                                    key={workout.id}
                                    p={3}
                                    bg="gray.50"
                                    borderRadius="md"
                                    justify="space-between"
                                >
                                    <VStack align="start" gap={0}>
                                        <Text fontWeight="medium">Workout</Text>
                                        <Text fontSize="sm" color="gray.500">
                                            {new Date(workout.completedAt).toLocaleDateString()}
                                        </Text>
                                    </VStack>
                                    <Text color="gray.600">
                                        {workout.actualDuration || 30} min
                                    </Text>
                                </HStack>
                            ))}
                        </VStack>
                    ) : (
                        <VStack py={8}>
                            <Text color="gray.500">No workouts yet</Text>
                            <RouterLink to="/workouts">
                                <Button colorScheme="blue" size="sm">
                                    Start Your First Workout
                                </Button>
                            </RouterLink>
                        </VStack>
                    )}
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default PersonalizedDashboardPage
