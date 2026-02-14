/**
 * LLM Analytics Simple Component
 * Displays analytics for AI/LLM usage
 */

import {
    Box,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    Table,
    Text,
    VStack
} from '@chakra-ui/react'
import { useState } from 'react'

interface DailyUsage {
    date: string
    requests: number
    tokens: number
    cost: number
    avgLatency: number
}

interface EndpointStats {
    endpoint: string
    requests: number
    avgLatency: number
    errorRate: number
}

const mockDailyUsage: DailyUsage[] = Array.from({ length: 7 }, (_, i) => ({
    date: new Date(Date.now() - (6 - i) * 24 * 60 * 60 * 1000).toLocaleDateString(),
    requests: Math.floor(Math.random() * 500) + 200,
    tokens: Math.floor(Math.random() * 100000) + 50000,
    cost: Math.random() * 5 + 1,
    avgLatency: Math.floor(Math.random() * 200) + 150,
}))

const mockEndpointStats: EndpointStats[] = [
    { endpoint: '/api/ai/generate-workout', requests: 1245, avgLatency: 245, errorRate: 0.5 },
    { endpoint: '/api/ai/coach', requests: 892, avgLatency: 312, errorRate: 0.8 },
    { endpoint: '/api/ai/analyze-progress', requests: 456, avgLatency: 189, errorRate: 0.2 },
    { endpoint: '/api/ai/nutrition-advice', requests: 234, avgLatency: 267, errorRate: 0.4 },
]

const LLMAnalyticsSimple = () => {
    const [dailyUsage] = useState<DailyUsage[]>(mockDailyUsage)
    const [endpointStats] = useState<EndpointStats[]>(mockEndpointStats)

    // Calculate totals
    const totalRequests = dailyUsage.reduce((sum, d) => sum + d.requests, 0)
    const totalTokens = dailyUsage.reduce((sum, d) => sum + d.tokens, 0)
    const totalCost = dailyUsage.reduce((sum, d) => sum + d.cost, 0)
    const avgLatency = Math.round(
        dailyUsage.reduce((sum, d) => sum + d.avgLatency, 0) / dailyUsage.length
    )

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <HStack>
                    <Heading size="xl">LLM Analytics</Heading>
                    <Badge colorPalette="yellow" variant="solid" fontSize="xs">
                        MOCK DATA
                    </Badge>
                </HStack>
                <Text color="gray.600">
                    Monitor AI usage and performance metrics
                </Text>
                <Text color="orange.500" fontSize="sm">
                    ⚠️ Displaying simulated data. Live analytics will be available once the backend telemetry pipeline is connected.
                </Text>
            </VStack>

            {/* Summary Stats */}
            <Grid templateColumns={{ base: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }} gap={4} mb={8}>
                <GridItem>
                    <Card.Root bg="blue.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" opacity={0.9}>
                                Total Requests (7d)
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold">
                                {totalRequests.toLocaleString()}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="green.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" opacity={0.9}>
                                Total Tokens (7d)
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold">
                                {(totalTokens / 1000).toFixed(1)}K
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="orange.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" opacity={0.9}>
                                Est. Cost (7d)
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold">
                                ${totalCost.toFixed(2)}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="purple.500" color="white" shadow="md" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" opacity={0.9}>
                                Avg Latency
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold">
                                {avgLatency}ms
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>

            {/* Daily Usage Chart (simplified) */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={8}>
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Daily Usage (Last 7 Days)
                    </Heading>
                    <HStack justify="space-between" align="flex-end" h="200px" px={4}>
                        {dailyUsage.map((day) => (
                            <VStack key={day.date} gap={2}>
                                <Box
                                    w="50px"
                                    h={`${(day.requests / 700) * 150}px`}
                                    bg="blue.400"
                                    borderRadius="md"
                                    title={`${day.requests} requests`}
                                />
                                <Text fontSize="xs" color="gray.500">
                                    {day.date.split('/').slice(0, 2).join('/')}
                                </Text>
                            </VStack>
                        ))}
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Endpoint Performance */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={8}>
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Endpoint Performance
                    </Heading>
                    <Box overflowX="auto">
                        <Table.Root>
                            <Table.Header>
                                <Table.Row>
                                    <Table.ColumnHeader>Endpoint</Table.ColumnHeader>
                                    <Table.ColumnHeader>Requests</Table.ColumnHeader>
                                    <Table.ColumnHeader>Avg Latency</Table.ColumnHeader>
                                    <Table.ColumnHeader>Error Rate</Table.ColumnHeader>
                                </Table.Row>
                            </Table.Header>
                            <Table.Body>
                                {endpointStats.map((stat) => (
                                    <Table.Row key={stat.endpoint}>
                                        <Table.Cell fontFamily="mono" fontSize="sm">
                                            {stat.endpoint}
                                        </Table.Cell>
                                        <Table.Cell>{stat.requests.toLocaleString()}</Table.Cell>
                                        <Table.Cell>{stat.avgLatency}ms</Table.Cell>
                                        <Table.Cell
                                            color={stat.errorRate > 1 ? 'red.500' : 'green.500'}
                                        >
                                            {stat.errorRate}%
                                        </Table.Cell>
                                    </Table.Row>
                                ))}
                            </Table.Body>
                        </Table.Root>
                    </Box>
                </Card.Body>
            </Card.Root>

            {/* Model Info */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={6}>
                    <Heading size="md" mb={4}>
                        Active Model Configuration
                    </Heading>
                    <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={4}>
                        <Box p={4} bg="gray.50" borderRadius="md">
                            <Text fontSize="sm" color="gray.500">
                                Provider
                            </Text>
                            <Text fontWeight="bold">OpenAI</Text>
                        </Box>
                        <Box p={4} bg="gray.50" borderRadius="md">
                            <Text fontSize="sm" color="gray.500">
                                Model
                            </Text>
                            <Text fontWeight="bold">gpt-5-mini</Text>
                        </Box>
                        <Box p={4} bg="gray.50" borderRadius="md">
                            <Text fontSize="sm" color="gray.500">
                                Max Tokens
                            </Text>
                            <Text fontWeight="bold">4,096</Text>
                        </Box>
                    </Grid>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default LLMAnalyticsSimple
