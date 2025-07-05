import { Box, Button, Container, Grid, Heading, HStack, Text, VStack } from '@chakra-ui/react'
import React, { useEffect, useState } from 'react'
import { BadgeGrid, QuickStats, StreakDisplay } from '../components/GamificationComponentsV2'
import LLMStatus from '../components/LLMStatus'
import { useVedAuth } from '../contexts/useVedAuth'
import { gamificationService, type UserGamificationStats } from '../services/gamificationService'
import { workoutService } from '../services/workoutService'
import { computeStreakUtc } from '../utils/streak'

const DashboardPage: React.FC = () => {
  const { user } = useVedAuth()
  const [streak, setStreak] = useState<number>(0)
  const [gamificationStats, setGamificationStats] = useState<UserGamificationStats | null>(null)
  const [weeklyWorkouts, setWeeklyWorkouts] = useState(0)
  const [totalWorkouts, setTotalWorkouts] = useState(0)
  const [aiInteractions, setAiInteractions] = useState(0)

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        // Fetch streak and workout data
        const dates: string[] = await workoutService.getWorkoutDays()
        const calculatedStreak = computeStreakUtc(dates)
        setStreak(calculatedStreak)
        setTotalWorkouts(dates.length)

        // Calculate weekly workouts (last 7 days)
        const weekAgo = new Date()
        weekAgo.setDate(weekAgo.getDate() - 7)
        const recentWorkouts = dates.filter(date => new Date(date) >= weekAgo)
        setWeeklyWorkouts(recentWorkouts.length)

        // Fetch gamification stats
        const stats = await gamificationService.getUserStats()
        setGamificationStats(stats)
        setAiInteractions(stats.aiInteractions)
      } catch (err) {
        console.error('Failed to fetch dashboard data', err)
      }
    }
    fetchDashboardData()
  }, [])

  const nextLevelPoints = gamificationStats ? (gamificationStats.level * 100) : 100

  return (
    <Container maxW="container.xl" py={6}>
      <VStack gap={6} align="stretch">
        {/* Welcome Section */}
        <Box>
          <Heading size="lg" mb={2}>
            Welcome back, {user?.username}!
          </Heading>
          <Text color="gray.600">
            {gamificationStats ? gamificationService.getMotivationalMessage(gamificationStats) : "Here's your fitness dashboard overview."}
          </Text>
        </Box>

        {/* LLM Status */}
        <LLMStatus />

        {/* Gamification Stats Row */}
        {gamificationStats && (
          <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={6}>
            <QuickStats
              level={gamificationStats.level}
              totalPoints={gamificationStats.totalPoints}
              nextLevelPoints={nextLevelPoints}
            />
            <StreakDisplay
              streak={gamificationStats.streaks.daily}
              title="Daily Streak"
              color="orange"
            />
            <StreakDisplay
              streak={gamificationStats.streaks.weekly}
              title="Weekly Consistency"
              color="blue"
            />
          </Grid>
        )}

        {/* Quick Stats Grid - PRD Dashboard Requirements */}
        <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(4, 1fr)' }} gap={4}>
          <Box p={4} borderWidth={1} borderRadius="md" bg="white">
            <Text fontSize="sm" color="gray.500">Workouts This Week</Text>
            <Heading size="lg" color="blue.600">{weeklyWorkouts}</Heading>
            <Text fontSize="sm" color="gray.400">
              {weeklyWorkouts === 0 ? "Start your first workout!" : `${Math.max(0, 3 - weeklyWorkouts)} more to goal`}
            </Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md" bg="white">
            <Text fontSize="sm" color="gray.500">Total Workouts</Text>
            <Heading size="lg" color="green.600">{totalWorkouts}</Heading>
            <Text fontSize="sm" color="gray.400">Logged workouts</Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md" bg="white">
            <Text fontSize="sm" color="gray.500">Current Streak</Text>
            <Heading size="lg" color="orange.600">{streak} days</Heading>
            <Text fontSize="sm" color="gray.400">
              {streak === 0 ? "Start your streak!" : "Keep it up!"}
            </Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md" bg="white">
            <Text fontSize="sm" color="gray.500">AI Interactions</Text>
            <Heading size="lg" color="purple.600">{aiInteractions}</Heading>
            <Text fontSize="sm" color="gray.400">Coach conversations</Text>
          </Box>
        </Grid>

        {/* Today's Focus Section - PRD Navigation */}
        <Box bg="blue.50" borderColor="blue.200" p={6} borderRadius="lg" borderWidth={1}>
          <VStack align="start" gap={4}>
            <Heading size="md" color="blue.700">Today's Focus</Heading>
            <Text color="blue.600">
              Ready to continue your fitness journey? Generate a personalized workout or get guidance from your AI coach.
              </Text>
              <HStack gap={4}>
                <Button
                  colorScheme="blue"
                  onClick={() => window.location.href='/workouts'}
                  size="lg"
                >
                  Generate Workout
                </Button>
                <Button
                  variant="outline"
                  colorScheme="blue"
                  onClick={() => window.location.href='/coach'}
                >
                  Chat with Coach
                </Button>
              </HStack>
              {user?.tier === 'free' && (
                <Text fontSize="sm" color="blue.500">
                  Free tier: {5 - (weeklyWorkouts || 0)} workout generations remaining this month
                </Text>
              )}
            </VStack>
          </Box>

        {/* Badges Section */}
        {gamificationStats && gamificationStats.badges.length > 0 && (
          <Box>
            <HStack justify="space-between" mb={4}>
              <Heading size="md">Recent Achievements</Heading>
              <Button variant="ghost" size="sm" onClick={() => window.location.href='/profile#badges'}>
                View All
              </Button>
            </HStack>
            <BadgeGrid badges={gamificationStats.badges} maxDisplay={6} />
          </Box>
        )}

        {/* AI Coach Preview - PRD Navigation */}
        <Box bg="purple.50" borderColor="purple.200" cursor="pointer" onClick={() => window.location.href='/coach'} p={6} borderRadius="lg" borderWidth={1}>
          <VStack align="start" gap={2}>
            <HStack>
              <Text fontSize="2xl">💬</Text>
              <Heading size="md" color="purple.700">AI Coach Preview</Heading>
            </HStack>
            <Text color="purple.600" fontSize="sm">
              "Great job on your consistency! Ready for today's workout? I can help you target specific muscle groups or adjust intensity based on how you're feeling."
            </Text>
            <HStack justify="space-between" w="full">
              <Text fontSize="xs" color="purple.500">
                  {user?.tier === 'free'
                    ? `${Math.max(0, 10 - aiInteractions)} AI chats remaining this month`
                    : 'Unlimited AI coaching'
                  }
                </Text>
                <Text fontSize="xs" color="purple.500">Tap to chat →</Text>
              </HStack>
            </VStack>
          </Box>

        {/* Tier Upgrade Prompt for Free Users */}
        {user?.tier === 'free' && (weeklyWorkouts >= 3 || aiInteractions >= 8) && (
          <Box bg="gradient-to-r from-yellow.50 to-orange.50" borderColor="orange.200" p={6} borderRadius="lg" borderWidth={1}>
            <VStack align="start" gap={3}>
              <HStack>
                <Text fontSize="2xl">⭐</Text>
                <Heading size="md" color="orange.700">Upgrade to Premium</Heading>
              </HStack>
              <Text color="orange.600">
                You're making great progress! Upgrade to Premium for unlimited workouts,
                unlimited AI coaching, and advanced analytics.
              </Text>
              <Button colorScheme="orange" onClick={() => window.location.href='/tiers'}>
                View Premium Features
              </Button>
            </VStack>
          </Box>
        )}
      </VStack>
    </Container>
  )
}

export default DashboardPage
