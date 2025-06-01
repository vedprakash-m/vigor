import React from 'react'
import { Box, Container, Heading, Text, Grid } from '@chakra-ui/react'
import { useAuth } from '../contexts/AuthContext'
import LLMStatus from '../components/LLMStatus'

const DashboardPage: React.FC = () => {
  const { user } = useAuth()

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
            <Heading size="lg">0 days</Heading>
            <Text fontSize="sm" color="gray.400">Keep it up!</Text>
          </Box>

          <Box p={4} borderWidth={1} borderRadius="md">
            <Text fontSize="sm" color="gray.500">Fitness Level</Text>
            <Heading size="lg">{user?.fitness_level || 'Not set'}</Heading>
            <Text fontSize="sm" color="gray.400">Your current level</Text>
          </Box>
        </Grid>

        <Box p={6} borderWidth={1} borderRadius="md" bg="blue.50">
          <Heading size="md" mb={2}>Quick Actions</Heading>
          <Text>
            Ready to start your fitness journey? Generate a new workout plan or chat with your AI coach!
          </Text>
        </Box>
      </Box>
    </Container>
  )
}

export default DashboardPage 