/**
 * Ghost Analytics Dashboard Component
 * System-level analytics for Ghost operations
 * Per UX Spec Part V §5.11 - Ghost Analytics Dashboard
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
    VStack
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { AdminAPI, GhostAnalytics } from '../services/adminApi'

const GhostAnalyticsDashboard = () => {
    const [analytics, setAnalytics] = useState<GhostAnalytics | null>(null)
    const [loading, setLoading] = useState(true)
    const [timeRange, setTimeRange] = useState('week')

    useEffect(() => {
        const fetchAnalytics = async () => {
            try {
                setLoading(true)
                const data = await AdminAPI.getGhostAnalytics()
                setAnalytics(data)
            } catch (err) {
                console.error('Failed to fetch analytics:', err)
            } finally {
                setLoading(false)
            }
        }
        fetchAnalytics()
    }, [timeRange])

    if (loading) {
        return (
            <Box p={6} display="flex" justifyContent="center" alignItems="center" minH="400px">
                <VStack gap={4}>
                    <Spinner size="xl" color="purple.500" />
                    <Text color="gray.600">Loading Ghost analytics...</Text>
                </VStack>
            </Box>
        )
    }

    if (!analytics) {
        return (
            <Box p={6}>
                <Text color="red.500">Failed to load analytics</Text>
            </Box>
        )
    }

    return (
        <Box p={6}>
            <HStack justify="space-between" mb={8}>
                <VStack align="start" gap={1}>
                    <Heading size="xl">Ghost Analytics</Heading>
                    <Text color="gray.600">System-level Ghost operations metrics</Text>
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
                        <option value="day">Today</option>
                        <option value="week">This Week</option>
                        <option value="month">This Month</option>
                    </select>
                </Box>
            </HStack>

            {/* Summary Stats */}
            <Grid templateColumns={{ base: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }} gap={4} mb={8}>
                <GridItem>
                    <Card.Root bg="blue.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={6}>
                            <Text fontSize="sm" opacity={0.9}>
                                Total Decisions
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold">
                                {analytics.totalDecisions.toLocaleString()}
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
                                Workout Mutations
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold">
                                {analytics.totalMutations.toLocaleString()}
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
                                Accept Rate
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold">
                                {analytics.acceptRate}%
                            </Text>
                            <Text fontSize="sm" opacity={0.8}>
                                decisions accepted
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="orange.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={6}>
                            <Text fontSize="sm" opacity={0.9}>
                                Safety Breakers
                            </Text>
                            <Text fontSize="3xl" fontWeight="bold">
                                {analytics.safetyBreakers}
                            </Text>
                            <Text fontSize="sm" opacity={0.8}>
                                triggered
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>

            {/* Weekly Activity Chart */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={8}>
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Daily Ghost Activity
                    </Heading>
                    <HStack justify="space-between" align="flex-end" h="200px" px={4}>
                        {analytics.weeklyStats.map((day) => (
                            <VStack key={day.day} gap={2}>
                                <VStack gap={1}>
                                    <Box
                                        w="35px"
                                        h={`${Math.max(day.decisions * 2, 10)}px`}
                                        bg="blue.400"
                                        borderRadius="md"
                                        transition="height 0.3s"
                                        title={`${day.decisions} decisions`}
                                    />
                                    <Box
                                        w="35px"
                                        h={`${Math.max(day.mutations * 3, 5)}px`}
                                        bg="purple.400"
                                        borderRadius="md"
                                        transition="height 0.3s"
                                        title={`${day.mutations} mutations`}
                                    />
                                </VStack>
                                <Text fontSize="sm" fontWeight="medium">
                                    {day.day}
                                </Text>
                            </VStack>
                        ))}
                    </HStack>
                    <HStack justify="center" gap={6} mt={4}>
                        <HStack gap={2}>
                            <Box w="12px" h="12px" bg="blue.400" borderRadius="sm" />
                            <Text fontSize="sm" color="gray.600">Decisions</Text>
                        </HStack>
                        <HStack gap={2}>
                            <Box w="12px" h="12px" bg="purple.400" borderRadius="sm" />
                            <Text fontSize="sm" color="gray.600">Mutations</Text>
                        </HStack>
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Trust Phase Distribution */}
            <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)' }} gap={6}>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={6}>
                            <Heading size="md" mb={6}>
                                Trust Phase Distribution
                            </Heading>
                            <VStack align="stretch" gap={4}>
                                {analytics.trustDistribution.map((phase) => {
                                    const total = analytics.trustDistribution.reduce((s, p) => s + p.count, 0)
                                    const pct = total > 0 ? (phase.count / total) * 100 : 0
                                    return (
                                        <Box key={phase.phase}>
                                            <HStack justify="space-between" mb={2}>
                                                <Text fontWeight="medium" fontSize="sm">{phase.phase}</Text>
                                                <Text color="gray.600" fontSize="sm">
                                                    {phase.count} users ({pct.toFixed(1)}%)
                                                </Text>
                                            </HStack>
                                            <Progress.Root value={pct} size="md" colorPalette="purple">
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
                </GridItem>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={6}>
                            <Heading size="md" mb={6}>
                                Decision Outcomes
                            </Heading>
                            <VStack align="stretch" gap={4}>
                                {[
                                    { name: 'Accepted', value: analytics.acceptRate, color: 'green' },
                                    { name: 'Modified', value: analytics.modifyRate, color: 'blue' },
                                    { name: 'Rejected', value: analytics.rejectRate, color: 'red' },
                                ].map((outcome) => (
                                    <Box key={outcome.name}>
                                        <HStack justify="space-between" mb={2}>
                                            <Text fontWeight="medium" fontSize="sm">{outcome.name}</Text>
                                            <Text color="gray.600" fontSize="sm">
                                                {outcome.value}%
                                            </Text>
                                        </HStack>
                                        <Progress.Root value={outcome.value} size="md" colorPalette={outcome.color}>
                                            <Progress.Track borderRadius="full">
                                                <Progress.Range />
                                            </Progress.Track>
                                        </Progress.Root>
                                    </Box>
                                ))}
                            </VStack>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>

            {/* Performance Metrics */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mt={6}>
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        AI Pipeline Performance
                    </Heading>
                    <Grid templateColumns={{ base: '1fr', md: 'repeat(4, 1fr)' }} gap={4}>
                        <Box p={4} bg="gray.50" borderRadius="md" textAlign="center">
                            <Text fontSize="2xl" fontWeight="bold" color="blue.600">
                                {analytics.avgLatencyMs}ms
                            </Text>
                            <Text fontSize="sm" color="gray.600">Avg Latency</Text>
                        </Box>
                        <Box p={4} bg="gray.50" borderRadius="md" textAlign="center">
                            <Text fontSize="2xl" fontWeight="bold" color="green.600">
                                {analytics.successRate}%
                            </Text>
                            <Text fontSize="sm" color="gray.600">Success Rate</Text>
                        </Box>
                        <Box p={4} bg="gray.50" borderRadius="md" textAlign="center">
                            <Text fontSize="2xl" fontWeight="bold" color="purple.600">
                                {analytics.phenomeQueriesPerDecision}
                            </Text>
                            <Text fontSize="sm" color="gray.600">Phenome Queries/Decision</Text>
                        </Box>
                        <Box p={4} bg="gray.50" borderRadius="md" textAlign="center">
                            <Text fontSize="2xl" fontWeight="bold" color="orange.600">
                                {analytics.avgConfidence}%
                            </Text>
                            <Text fontSize="sm" color="gray.600">Avg Confidence</Text>
                        </Box>
                    </Grid>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default GhostAnalyticsDashboard
