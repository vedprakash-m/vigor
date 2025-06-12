import { Box, Container, Grid, Heading, Text } from '@chakra-ui/react'
import React, { useEffect, useState } from 'react'
import LLMStatus from '../components/LLMStatus'
import { useAuth } from '../contexts/useAuth'
import { workoutService } from '../services/workoutService'
import { computeStreakUtc } from '../utils/streak'

const DashboardPage: React.FC = () => {
  const { user } = useAuth()
  const [streak, setStreak] = useState<number>(0)

  useEffect(() => {
    const fetchStreak = async () => {
      try {
        const dates: string[] = await workoutService.getWorkoutDays()
        setStreak(computeStreakUtc(dates))
      } catch (err) {
        console.error('Failed to fetch streak', err)
      }
    }
    fetchStreak()
  }, [])

  return (
    <Container maxW="container.xl" py={6}>
      <Box>
        <Box mb={6}>
          <Heading size="lg" mb={2}>
            Welcome back, {user?.username}!
          </Heading>
          <Text color="gray.600">
            Here's your fitness dashboard overview.
          </Text>
        </Box>

        <Box mb={6}>
          <LLMStatus />
        </Box>

        <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(4, 1fr)' }} gap={4} mb={6}>
          <Box p={4} borderWidth={1} borderRadius="md">
            <Text fontSize="sm" color="gray.500">Workouts This Week</Text>
            <Heading size="lg">0</Heading>
            <Text fontSize="sm" color="gray.400">Start your first workout!</Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md">
            <Text fontSize="sm" color="gray.500">Total Workouts</Text>
            <Heading size="lg">0</Heading>
            <Text fontSize="sm" color="gray.400">Logged workouts</Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md">
            <Text fontSize="sm" color="gray.500">Current Streak</Text>
            <Heading size="lg">{streak} days</Heading>
            <Text fontSize="sm" color="gray.400">Keep it up!</Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md">
            <Text fontSize="sm" color="gray.500">Fitness Level</Text>
            <Heading size="lg">{user?.fitness_level || 'Not set'}</Heading>
            <Text fontSize="sm" color="gray.400">Your current level</Text>
          </Box>
        </Grid>

        <Box p={6} borderWidth={1} borderRadius="md" bg="blue.50" mb={6}>
          <Heading size="md" mb={2}>Quick Actions</Heading>
          <Text>
            Ready to start your fitness journey? Generate a new workout plan or chat with your AI coach!
          </Text>
        </Box>

        {/* AI Coach Teaser (Gap 4) */}
        <Box p={6} borderWidth={1} borderRadius="md" bg="purple.50" cursor="pointer" onClick={() => window.location.href='/coach'}>
          <Heading size="md" mb={1}>💬 Ask Your Coach</Heading>
          <Text fontSize="sm" color="purple.800">Tap here to chat with Vigor Coach for tips, motivation, and more.</Text>
        </Box>
      </Box>
    </Container>
  )
}

export default DashboardPage
