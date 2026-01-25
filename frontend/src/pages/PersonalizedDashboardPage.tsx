/**
 * Home Page (formerly Personalized Dashboard)
 * Today's mission control - motivates immediate action
 *
 * Design Principle: This is a LAUNCHPAD, not a data dashboard.
 * Shows only: greeting, streak, primary CTA, coach teaser
 * All detailed stats live on the Progress page.
 */

import {
    Box,
    Button,
    Card,
    Heading,
    HStack,
    Spinner,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { Link as RouterLink } from 'react-router-dom'
import { useVedAuth } from '../contexts/useVedAuth'
import { api, type UserStats, type WorkoutLog } from '../services/api'

// Get time-of-day greeting
const getGreeting = (): { text: string; emoji: string } => {
    const hour = new Date().getHours()
    if (hour < 12) return { text: 'Good morning', emoji: '☀️' }
    if (hour < 17) return { text: 'Good afternoon', emoji: '🌤️' }
    if (hour < 21) return { text: 'Good evening', emoji: '🌅' }
    return { text: 'Good night', emoji: '🌙' }
}

// Determine user state for adaptive CTA
type UserState = 'new' | 'returning' | 'streak-at-risk' | 'completed-today'

const PersonalizedDashboardPage = () => {
    const { user } = useVedAuth()
    const [currentStreak, setCurrentStreak] = useState(0)
    const [hasWorkoutToday, setHasWorkoutToday] = useState(false)
    const [totalWorkouts, setTotalWorkouts] = useState(0)
    const [isLoading, setIsLoading] = useState(true)
    const [userState, setUserState] = useState<UserState>('new')

    const greeting = getGreeting()

    useEffect(() => {
        const fetchHomeData = async () => {
            try {
                setIsLoading(true)

                // Fetch user profile with stats
                const profileResponse = await api.users.getProfile()
                const userStats: UserStats = profileResponse.data?.stats || {
                    totalWorkouts: 0,
                    currentStreak: 0,
                    longestStreak: 0,
                }

                setCurrentStreak(userStats.currentStreak)
                setTotalWorkouts(userStats.totalWorkouts)

                // Fetch recent workout logs to check if worked out today
                const logsResponse = await api.workouts.history(5)
                const logs: WorkoutLog[] = logsResponse.data || []

                const today = new Date().toDateString()
                const workedOutToday = logs.some(
                    (log) => new Date(log.completedAt).toDateString() === today
                )
                setHasWorkoutToday(workedOutToday)

                // Determine user state
                if (userStats.totalWorkouts === 0) {
                    setUserState('new')
                } else if (workedOutToday) {
                    setUserState('completed-today')
                } else if (userStats.currentStreak > 0) {
                    setUserState('streak-at-risk')
                } else {
                    setUserState('returning')
                }
            } catch (error) {
                console.error('Failed to fetch home data:', error)
            } finally {
                setIsLoading(false)
            }
        }

        fetchHomeData()
    }, [])

    // Get adaptive content based on user state
    const getAdaptiveContent = () => {
        switch (userState) {
            case 'new':
                return {
                    title: 'Ready to begin your fitness journey?',
                    subtitle: 'Your AI coach will create the perfect first workout for you',
                    cta: 'Generate My First Workout',
                    ctaLink: '/app/workouts',
                    color: 'blue',
                    emoji: '🚀',
                }
            case 'completed-today':
                return {
                    title: 'Great job today! 🎉',
                    subtitle: 'You crushed it! Take some time to recover or chat with your coach',
                    cta: 'Chat with Coach',
                    ctaLink: '/app/coach',
                    color: 'green',
                    emoji: '✅',
                }
            case 'streak-at-risk':
                return {
                    title: `Don't break your ${currentStreak}-day streak! 🔥`,
                    subtitle: 'A quick workout keeps your momentum going',
                    cta: 'Quick 15-min Workout',
                    ctaLink: '/app/workouts',
                    color: 'orange',
                    emoji: '⚡',
                }
            default: // returning
                return {
                    title: 'Ready for today\'s workout?',
                    subtitle: 'Let\'s keep building those healthy habits',
                    cta: 'Start Today\'s Workout',
                    ctaLink: '/app/workouts',
                    color: 'blue',
                    emoji: '💪',
                }
        }
    }

    const adaptiveContent = getAdaptiveContent()

    if (isLoading) {
        return (
            <Box p={6}>
                <VStack gap={6} align="center" justify="center" minH="400px">
                    <Spinner size="xl" color="blue.500" />
                    <Text color="gray.500">Loading your dashboard...</Text>
                </VStack>
            </Box>
        )
    }

    return (
        <Box p={{ base: 4, md: 6 }} maxW="800px" mx="auto">
            {/* Greeting Section */}
            <VStack align="start" mb={6} gap={1}>
                <Heading size={{ base: 'lg', md: 'xl' }}>
                    {greeting.text}{user?.name ? `, ${user.name.split(' ')[0]}` : ''}! {greeting.emoji}
                </Heading>
                {currentStreak > 0 ? (
                    <HStack gap={2}>
                        <Text fontSize="lg" color="orange.500" fontWeight="bold">
                            🔥 {currentStreak}-day streak
                        </Text>
                        <Text color="gray.500">— Keep it up!</Text>
                    </HStack>
                ) : totalWorkouts > 0 ? (
                    <Text color="gray.600" fontSize="lg">
                        Ready to start a new streak?
                    </Text>
                ) : (
                    <Text color="gray.600" fontSize="lg">
                        Let's build healthy habits together
                    </Text>
                )}
            </VStack>

            {/* Primary Action Card - Adaptive based on user state */}
            <Card.Root
                bg={`${adaptiveContent.color}.50`}
                borderColor={`${adaptiveContent.color}.200`}
                borderWidth="1px"
                shadow="md"
                borderRadius="xl"
                mb={6}
                overflow="hidden"
            >
                <Card.Body p={{ base: 5, md: 8 }}>
                    <VStack align="start" gap={4}>
                        <Box>
                            <Text fontSize="2xl" mb={2}>{adaptiveContent.emoji}</Text>
                            <Heading size="lg" color={`${adaptiveContent.color}.700`} mb={2}>
                                {adaptiveContent.title}
                            </Heading>
                            <Text color={`${adaptiveContent.color}.600`} fontSize="md">
                                {adaptiveContent.subtitle}
                            </Text>
                        </Box>
                        <HStack gap={4} flexWrap="wrap">
                            <RouterLink to={adaptiveContent.ctaLink}>
                                <Button
                                    size="lg"
                                    colorScheme={adaptiveContent.color}
                                    px={8}
                                >
                                    {adaptiveContent.cta}
                                </Button>
                            </RouterLink>
                            {userState !== 'new' && userState !== 'completed-today' && (
                                <RouterLink to="/app/workouts">
                                    <Button variant="ghost" size="lg">
                                        Customize workout →
                                    </Button>
                                </RouterLink>
                            )}
                        </HStack>
                    </VStack>
                </Card.Body>
            </Card.Root>

            {/* Coach Teaser */}
            <Card.Root
                bg="purple.50"
                borderColor="purple.200"
                borderWidth="1px"
                borderRadius="lg"
                mb={6}
                cursor="pointer"
                _hover={{ bg: 'purple.100', transform: 'translateY(-2px)' }}
                transition="all 0.2s"
            >
                <RouterLink to="/app/coach" style={{ textDecoration: 'none' }}>
                    <Card.Body p={5}>
                        <HStack gap={4}>
                            <Text fontSize="2xl">🤖</Text>
                            <Box flex={1}>
                                <Text fontWeight="bold" color="purple.700" mb={1}>
                                    Coach Vigor says:
                                </Text>
                                <Text color="purple.600" fontSize="sm">
                                    {userState === 'new'
                                        ? "Welcome! I'm here to guide you on your fitness journey. Ask me anything!"
                                        : currentStreak > 3
                                        ? `Amazing ${currentStreak}-day streak! Consider adding variety to your routine.`
                                        : hasWorkoutToday
                                        ? "Great workout today! Remember to stretch and hydrate."
                                        : "Ready when you are! Let's make today count."
                                    }
                                </Text>
                            </Box>
                            <Text color="purple.400">→</Text>
                        </HStack>
                    </Card.Body>
                </RouterLink>
            </Card.Root>

            {/* Quick Check-in (only if not completed today) */}
            {!hasWorkoutToday && totalWorkouts > 0 && (
                <Card.Root bg="gray.50" borderRadius="lg" mb={6}>
                    <Card.Body p={5}>
                        <HStack justify="space-between" flexWrap="wrap" gap={4}>
                            <Text color="gray.600" fontWeight="medium">
                                Did you work out today?
                            </Text>
                            <HStack gap={3}>
                                <RouterLink to="/app/workouts">
                                    <Button size="sm" colorScheme="green" variant="outline">
                                        Start now →
                                    </Button>
                                </RouterLink>
                            </HStack>
                        </HStack>
                    </Card.Body>
                </Card.Root>
            )}

            {/* View Progress Link */}
            <Box textAlign="center">
                <RouterLink to="/app/progress">
                    <Button variant="ghost" color="gray.500" size="sm">
                        📊 View detailed progress & stats →
                    </Button>
                </RouterLink>
            </Box>
        </Box>
    )
}

export default PersonalizedDashboardPage
