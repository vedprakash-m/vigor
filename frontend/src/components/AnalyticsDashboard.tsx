/**
 * Analytics Dashboard Component
 * Displays user fitness analytics and progress charts
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
    VStack
} from '@chakra-ui/react'
import { useState } from 'react'

interface WeeklyStats {
    day: string
    workouts: number
    minutes: number
    calories: number
}

const mockWeeklyData: WeeklyStats[] = [
    { day: 'Mon', workouts: 1, minutes: 45, calories: 320 },
    { day: 'Tue', workouts: 0, minutes: 0, calories: 0 },
    { day: 'Wed', workouts: 1, minutes: 30, calories: 240 },
    { day: 'Thu', workouts: 1, minutes: 60, calories: 450 },
    { day: 'Fri', workouts: 0, minutes: 0, calories: 0 },
    { day: 'Sat', workouts: 1, minutes: 45, calories: 380 },
    { day: 'Sun', workouts: 1, minutes: 30, calories: 280 },
]

interface GoalProgress {
    name: string
    current: number
    target: number
    unit: string
}

const goals: GoalProgress[] = [
    { name: 'Weekly Workouts', current: 4, target: 5, unit: 'workouts' },
    { name: 'Exercise Minutes', current: 210, target: 300, unit: 'minutes' },
    { name: 'Calories Burned', current: 1670, target: 2000, unit: 'calories' },
    { name: 'Active Days', current: 5, target: 6, unit: 'days' },
]

const AnalyticsDashboard = () => {
    const [timeRange, setTimeRange] = useState('week')

    const totalWorkouts = mockWeeklyData.reduce((sum, d) => sum + d.workouts, 0)
    const totalMinutes = mockWeeklyData.reduce((sum, d) => sum + d.minutes, 0)
    const totalCalories = mockWeeklyData.reduce((sum, d) => sum + d.calories, 0)
    const activeDays = mockWeeklyData.filter((d) => d.workouts > 0).length

    return (
        <Box p={6}>
            <HStack justify="space-between" mb={8}>
                <VStack align="start" gap={1}>
                    <Heading size="xl">Analytics</Heading>
                    <Text color="gray.600">Track your fitness journey</Text>
                </VStack>
                <Box w="150px">
                    <select
                        value={timeRange}
                        onChange={(e) => setTimeRange(e.target.value)}
                        style={{
                            width: '100%',
                            padding: '8px 12px',
                            borderRadius: '8px',
                            border: '1px solid #E2E8F0',
                            backgroundColor: 'white',
                        }}
                    >
                        <option value="week">This Week</option>
                        <option value="month">This Month</option>
                        <option value="year">This Year</option>
                    </select>
                </Box>
            </HStack>

            {/* Summary Stats */}
            <Grid templateColumns={{ base: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }} gap={4} mb={8}>
                <GridItem>
                    <Card.Root bg="blue.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={6}>
                            <Text fontSize="sm" opacity={0.9}>
                                Total Workouts
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold">
                                {totalWorkouts}
                            </Text>
                            <Text fontSize="sm" opacity={0.8}>
                                this {timeRange}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="green.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={6}>
                            <Text fontSize="sm" opacity={0.9}>
                                Active Minutes
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold">
                                {totalMinutes}
                            </Text>
                            <Text fontSize="sm" opacity={0.8}>
                                this {timeRange}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="orange.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={6}>
                            <Text fontSize="sm" opacity={0.9}>
                                Calories Burned
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold">
                                {totalCalories}
                            </Text>
                            <Text fontSize="sm" opacity={0.8}>
                                this {timeRange}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="purple.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={6}>
                            <Text fontSize="sm" opacity={0.9}>
                                Active Days
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold">
                                {activeDays}
                            </Text>
                            <Text fontSize="sm" opacity={0.8}>
                                out of 7
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>

            {/* Weekly Activity Chart (simplified) */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={8}>
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Weekly Activity
                    </Heading>
                    <HStack justify="space-between" align="flex-end" h="200px" px={4}>
                        {mockWeeklyData.map((day) => (
                            <VStack key={day.day} gap={2}>
                                <Box
                                    w="40px"
                                    h={`${Math.max(day.minutes * 2, 10)}px`}
                                    bg={day.workouts > 0 ? 'blue.400' : 'gray.200'}
                                    borderRadius="md"
                                    transition="height 0.3s"
                                />
                                <Text fontSize="sm" fontWeight="medium">
                                    {day.day}
                                </Text>
                            </VStack>
                        ))}
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Goals Progress */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Goal Progress
                    </Heading>
                    <VStack align="stretch" gap={6}>
                        {goals.map((goal) => {
                            const progress = Math.min((goal.current / goal.target) * 100, 100)
                            return (
                                <Box key={goal.name}>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">{goal.name}</Text>
                                        <Text color="gray.600" fontSize="sm">
                                            {goal.current} / {goal.target} {goal.unit}
                                        </Text>
                                    </HStack>
                                    <Progress.Root value={progress} size="lg" colorPalette={progress >= 100 ? 'green' : 'blue'}>
                                        <Progress.Track borderRadius="full">
                                            <Progress.Range />
                                        </Progress.Track>
                                    </Progress.Root>
                                </Box>
                            )
                        })}
                    </VStack>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default AnalyticsDashboard
