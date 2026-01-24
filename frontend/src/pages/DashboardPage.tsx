import { Box, Button, Container, Grid, Heading, HStack, Spinner, Text, VStack } from '@chakra-ui/react'
import React, { useEffect, useState } from 'react'
import LLMStatus from '../components/LLMStatus'
import { useVedAuth } from '../contexts/useVedAuth'
import { api, type UserStats, type WorkoutLog } from '../services/api'

interface DashboardStats {
  totalWorkouts: number
  weeklyWorkouts: number
  currentStreak: number
  longestStreak: number
}

const DashboardPage: React.FC = () => {
  const { user } = useVedAuth()
  const [stats, setStats] = useState<DashboardStats>({
    totalWorkouts: 0,
    weeklyWorkouts: 0,
    currentStreak: 0,
    longestStreak: 0
  })
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
          longestStreak: 0
        }

        // Fetch recent workout logs to calculate weekly stats
        const logsResponse = await api.workouts.history(50)
        const logs: WorkoutLog[] = logsResponse.data || []

        // Calculate weekly workouts (last 7 days)
        const weekAgo = new Date()
        weekAgo.setDate(weekAgo.getDate() - 7)
        const weeklyWorkouts = logs.filter(log =>
          new Date(log.completedAt) >= weekAgo
        ).length

        setStats({
          totalWorkouts: userStats.totalWorkouts,
          weeklyWorkouts,
          currentStreak: userStats.currentStreak,
          longestStreak: userStats.longestStreak
        })
      } catch (err) {
        console.error('Failed to fetch dashboard data', err)
      } finally {
        setIsLoading(false)
      }
    }

    fetchDashboardData()
  }, [])

  if (isLoading) {
    return (
      <Container maxW="container.xl" py={6}>
        <VStack gap={6} align="center" justify="center" minH="400px">
          <Spinner size="xl" color="blue.500" />
          <Text color="gray.500">Loading your dashboard...</Text>
        </VStack>
      </Container>
    )
  }

  return (
    <Container maxW="container.xl" py={6}>
      <VStack gap={6} align="stretch">
        {/* Welcome Section */}
        <Box>
          <Heading size="lg" mb={2}>
            Welcome back{user?.name ? `, ${user.name.split(' ')[0]}` : ''}!
          </Heading>
          <Text color="gray.600">
            Here's your fitness dashboard overview.
          </Text>
        </Box>

        {/* LLM Status */}
        <LLMStatus />

        {/* Quick Stats Grid */}
        <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(4, 1fr)' }} gap={4}>
          <Box p={4} borderWidth={1} borderRadius="md" bg="white">
            <Text fontSize="sm" color="gray.500">Workouts This Week</Text>
            <Heading size="lg" color="blue.600">{stats.weeklyWorkouts}</Heading>
            <Text fontSize="sm" color="gray.400">
              {stats.weeklyWorkouts === 0 ? "Start your first workout!" : `${Math.max(0, 3 - stats.weeklyWorkouts)} more to goal`}
            </Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md" bg="white">
            <Text fontSize="sm" color="gray.500">Total Workouts</Text>
            <Heading size="lg" color="green.600">{stats.totalWorkouts}</Heading>
            <Text fontSize="sm" color="gray.400">Completed workouts</Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md" bg="white">
            <Text fontSize="sm" color="gray.500">Current Streak</Text>
            <Heading size="lg" color="orange.600">{stats.currentStreak} days</Heading>
            <Text fontSize="sm" color="gray.400">
              {stats.currentStreak === 0 ? "Start your streak!" : "Keep it up!"}
            </Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md" bg="white">
            <Text fontSize="sm" color="gray.500">Longest Streak</Text>
            <Heading size="lg" color="purple.600">{stats.longestStreak} days</Heading>
            <Text fontSize="sm" color="gray.400">Personal best</Text>
          </Box>
        </Grid>

        {/* Today's Focus Section */}
        <Box bg="blue.50" borderColor="blue.200" p={6} borderRadius="lg" borderWidth={1}>
          <VStack align="start" gap={4}>
            <Heading size="md" color="blue.700">Today's Focus</Heading>
            <Text color="blue.600">
              Ready to continue your fitness journey? Generate a personalized workout or get guidance from your AI coach.
            </Text>
            <HStack gap={4}>
              <Button
                colorScheme="blue"
                onClick={() => window.location.href = '/workouts'}
                size="lg"
              >
                Generate Workout
              </Button>
              <Button
                variant="outline"
                colorScheme="blue"
                onClick={() => window.location.href = '/coach'}
              >
                Chat with Coach
              </Button>
            </HStack>
          </VStack>
        </Box>

        {/* AI Coach Preview */}
        <Box
          bg="purple.50"
          borderColor="purple.200"
          cursor="pointer"
          onClick={() => window.location.href = '/coach'}
          p={6}
          borderRadius="lg"
          borderWidth={1}
          _hover={{ bg: 'purple.100' }}
          transition="background 0.2s"
        >
          <VStack align="start" gap={2}>
            <HStack>
              <Text fontSize="2xl">💬</Text>
              <Heading size="md" color="purple.700">AI Coach</Heading>
            </HStack>
            <Text color="purple.600" fontSize="sm">
              Get personalized fitness advice, form tips, and motivation from your AI coach powered by OpenAI.
            </Text>
            <Text fontSize="xs" color="purple.500">Tap to start a conversation →</Text>
          </VStack>
        </Box>

        {/* Streak Encouragement */}
        {stats.currentStreak > 0 && (
          <Box bg="orange.50" borderColor="orange.200" p={4} borderRadius="lg" borderWidth={1}>
            <HStack gap={3}>
              <Text fontSize="2xl">🔥</Text>
              <VStack align="start" gap={0}>
                <Text fontWeight="bold" color="orange.700">
                  {stats.currentStreak} Day Streak!
                </Text>
                <Text fontSize="sm" color="orange.600">
                  {stats.currentStreak >= stats.longestStreak
                    ? "You're at your personal best!"
                    : `${stats.longestStreak - stats.currentStreak} more days to beat your record!`
                  }
                </Text>
              </VStack>
            </HStack>
          </Box>
        )}
      </VStack>
    </Container>
  )
}

export default DashboardPage
