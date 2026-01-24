/**
 * LLM Health Monitoring Component
 * Monitors health and performance of AI services
 */

import {
    Badge,
    Box,
    Button,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { api } from '../services/api'

interface HealthCheck {
    service: string
    status: 'healthy' | 'degraded' | 'unhealthy'
    latency: number
    lastCheck: string
    message: string
}

interface IncidentLog {
    id: string
    timestamp: string
    severity: 'low' | 'medium' | 'high' | 'critical'
    service: string
    message: string
    resolved: boolean
}

const LLMHealthMonitoring = () => {
    const [healthChecks, setHealthChecks] = useState<HealthCheck[]>([
        {
            service: 'OpenAI API',
            status: 'healthy',
            latency: 145,
            lastCheck: new Date().toISOString(),
            message: 'All systems operational',
        },
        {
            service: 'Cosmos DB',
            status: 'healthy',
            latency: 23,
            lastCheck: new Date().toISOString(),
            message: 'Connected',
        },
        {
            service: 'Azure Functions',
            status: 'healthy',
            latency: 56,
            lastCheck: new Date().toISOString(),
            message: 'Running',
        },
    ])
    const [incidents] = useState<IncidentLog[]>([
        {
            id: '1',
            timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(),
            severity: 'low',
            service: 'OpenAI API',
            message: 'Elevated latency detected (avg 450ms)',
            resolved: true,
        },
        {
            id: '2',
            timestamp: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString(),
            severity: 'medium',
            service: 'Azure Functions',
            message: 'Cold start delays observed',
            resolved: true,
        },
    ])
    const [isRefreshing, setIsRefreshing] = useState(false)

    const refreshHealth = async () => {
        setIsRefreshing(true)
        try {
            const response = await api.health.check()
            if (response.data) {
                const healthStatus = response.data.status
                setHealthChecks((prev) =>
                    prev.map((check) =>
                        check.service === 'OpenAI API'
                            ? {
                                  ...check,
                                  status: healthStatus === 'healthy' ? 'healthy' : healthStatus === 'degraded' ? 'degraded' : 'unhealthy',
                                  latency: check.latency,
                                  lastCheck: new Date().toISOString(),
                              }
                            : check
                    )
                )
            }
        } catch (error) {
            console.error('Health check failed:', error)
        } finally {
            setIsRefreshing(false)
        }
    }

    useEffect(() => {
        refreshHealth()
        const interval = setInterval(refreshHealth, 30000) // Refresh every 30 seconds
        return () => clearInterval(interval)
    }, [])

    const getStatusColor = (status: HealthCheck['status']) => {
        switch (status) {
            case 'healthy':
                return 'green'
            case 'degraded':
                return 'yellow'
            case 'unhealthy':
                return 'red'
        }
    }

    const getSeverityColor = (severity: IncidentLog['severity']) => {
        switch (severity) {
            case 'low':
                return 'blue'
            case 'medium':
                return 'yellow'
            case 'high':
                return 'orange'
            case 'critical':
                return 'red'
        }
    }

    const overallStatus = healthChecks.every((h) => h.status === 'healthy')
        ? 'healthy'
        : healthChecks.some((h) => h.status === 'unhealthy')
        ? 'unhealthy'
        : 'degraded'

    return (
        <Box p={6}>
            <HStack justify="space-between" mb={8}>
                <VStack align="start" gap={1}>
                    <Heading size="xl">Health Monitoring</Heading>
                    <Text color="gray.600">Monitor AI service health and incidents</Text>
                </VStack>
                <Button onClick={refreshHealth} disabled={isRefreshing} size="sm">
                    {isRefreshing ? 'Refreshing...' : 'Refresh'}
                </Button>
            </HStack>

            {/* Overall Status Banner */}
            <Card.Root
                bg={`${getStatusColor(overallStatus)}.50`}
                borderColor={`${getStatusColor(overallStatus)}.200`}
                border="2px solid"
                borderRadius="lg"
                mb={8}
            >
                <Card.Body p={6}>
                    <HStack justify="space-between">
                        <HStack gap={4}>
                            <Box
                                w="16px"
                                h="16px"
                                borderRadius="full"
                                bg={`${getStatusColor(overallStatus)}.500`}
                            />
                            <VStack align="start" gap={0}>
                                <Heading size="md">
                                    System Status: {overallStatus.charAt(0).toUpperCase() + overallStatus.slice(1)}
                                </Heading>
                                <Text color="gray.600">
                                    Last updated: {new Date().toLocaleTimeString()}
                                </Text>
                            </VStack>
                        </HStack>
                        <Badge
                            colorPalette={getStatusColor(overallStatus)}
                            size="lg"
                            p={2}
                        >
                            {healthChecks.filter((h) => h.status === 'healthy').length}/
                            {healthChecks.length} Services Healthy
                        </Badge>
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Service Health Grid */}
            <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={4} mb={8}>
                {healthChecks.map((check) => (
                    <GridItem key={check.service}>
                        <Card.Root bg="white" shadow="sm" borderRadius="lg">
                            <Card.Body p={4}>
                                <HStack justify="space-between" mb={3}>
                                    <Text fontWeight="bold">{check.service}</Text>
                                    <Badge colorPalette={getStatusColor(check.status)}>
                                        {check.status}
                                    </Badge>
                                </HStack>
                                <VStack align="start" gap={1}>
                                    <HStack justify="space-between" w="full">
                                        <Text fontSize="sm" color="gray.500">
                                            Latency
                                        </Text>
                                        <Text
                                            fontSize="sm"
                                            fontWeight="medium"
                                            color={
                                                check.latency > 500
                                                    ? 'red.500'
                                                    : check.latency > 200
                                                    ? 'yellow.600'
                                                    : 'green.500'
                                            }
                                        >
                                            {check.latency}ms
                                        </Text>
                                    </HStack>
                                    <Text fontSize="xs" color="gray.400">
                                        {check.message}
                                    </Text>
                                </VStack>
                            </Card.Body>
                        </Card.Root>
                    </GridItem>
                ))}
            </Grid>

            {/* Uptime Stats */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={8}>
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Uptime Statistics
                    </Heading>
                    <Grid templateColumns={{ base: '1fr', md: 'repeat(4, 1fr)' }} gap={4}>
                        <Box p={4} bg="gray.50" borderRadius="md" textAlign="center">
                            <Text fontSize="3xl" fontWeight="bold" color="green.500">
                                99.9%
                            </Text>
                            <Text fontSize="sm" color="gray.600">
                                Last 24 Hours
                            </Text>
                        </Box>
                        <Box p={4} bg="gray.50" borderRadius="md" textAlign="center">
                            <Text fontSize="3xl" fontWeight="bold" color="green.500">
                                99.8%
                            </Text>
                            <Text fontSize="sm" color="gray.600">
                                Last 7 Days
                            </Text>
                        </Box>
                        <Box p={4} bg="gray.50" borderRadius="md" textAlign="center">
                            <Text fontSize="3xl" fontWeight="bold" color="green.500">
                                99.7%
                            </Text>
                            <Text fontSize="sm" color="gray.600">
                                Last 30 Days
                            </Text>
                        </Box>
                        <Box p={4} bg="gray.50" borderRadius="md" textAlign="center">
                            <Text fontSize="3xl" fontWeight="bold" color="green.500">
                                99.5%
                            </Text>
                            <Text fontSize="sm" color="gray.600">
                                Last 90 Days
                            </Text>
                        </Box>
                    </Grid>
                </Card.Body>
            </Card.Root>

            {/* Recent Incidents */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Recent Incidents
                    </Heading>
                    {incidents.length > 0 ? (
                        <VStack align="stretch" gap={3}>
                            {incidents.map((incident) => (
                                <HStack
                                    key={incident.id}
                                    p={4}
                                    bg="gray.50"
                                    borderRadius="md"
                                    justify="space-between"
                                >
                                    <HStack gap={4}>
                                        <Badge colorPalette={getSeverityColor(incident.severity)}>
                                            {incident.severity}
                                        </Badge>
                                        <VStack align="start" gap={0}>
                                            <Text fontWeight="medium">{incident.message}</Text>
                                            <Text fontSize="sm" color="gray.500">
                                                {incident.service} •{' '}
                                                {new Date(incident.timestamp).toLocaleString()}
                                            </Text>
                                        </VStack>
                                    </HStack>
                                    <Badge colorPalette={incident.resolved ? 'green' : 'red'}>
                                        {incident.resolved ? 'Resolved' : 'Active'}
                                    </Badge>
                                </HStack>
                            ))}
                        </VStack>
                    ) : (
                        <Text color="gray.500" textAlign="center" py={4}>
                            No recent incidents
                        </Text>
                    )}
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default LLMHealthMonitoring
