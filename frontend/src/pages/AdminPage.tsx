/**
 * Admin Dashboard Page
 *
 * Per UX Spec Part V §5.5: Dashboard provides at-a-glance Ghost system health
 * Shows Ghost mode, Trust distribution, and key operational metrics
 */

import {
    Badge,
    Box,
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
import { type GhostMode } from '../config/adminConfig'
import { useAuth } from '../contexts/useAuth'
import { AdminAPI, type GhostHealth, type GhostMetrics, type TrustDistribution } from '../services/adminApi'

/**
 * Ghost Mode Status Card
 */
const GhostModeCard = ({ mode, lastUpdated }: { mode: GhostMode; lastUpdated: string }) => {
    const modeConfig = {
        NORMAL: { color: 'green', label: 'Normal', description: 'All systems operational' },
        SAFE_MODE: { color: 'yellow', label: 'Safe Mode', description: 'Reduced automation due to errors' },
        DEGRADED: { color: 'orange', label: 'Degraded', description: 'Some components unhealthy' },
        PAUSED: { color: 'red', label: 'Paused', description: 'Ghost operations suspended' },
    }

    const config = modeConfig[mode]
    const updatedTime = new Date(lastUpdated).toLocaleTimeString()

    return (
        <Card.Root p={4} bg="white" shadow="sm" borderRadius="lg">
            <Card.Body>
                <VStack align="start" gap={1}>
                    <Text fontSize="sm" color="gray.500">Ghost Mode</Text>
                    <HStack>
                        <Box
                            w="10px"
                            h="10px"
                            borderRadius="full"
                            bg={`${config.color}.400`}
                        />
                        <Text fontWeight="bold" fontSize="lg">{config.label}</Text>
                    </HStack>
                    <Text fontSize="xs" color="gray.400">{config.description}</Text>
                    <Text fontSize="xs" color="gray.300">Updated: {updatedTime}</Text>
                </VStack>
            </Card.Body>
        </Card.Root>
    )
}

/**
 * Component Health Card
 */
const ComponentCard = ({
    name,
    status,
    description,
}: {
    name: string
    status: 'healthy' | 'degraded' | 'unhealthy'
    description: string
}) => {
    const statusColors = {
        healthy: 'green',
        degraded: 'yellow',
        unhealthy: 'red',
    }

    return (
        <Card.Root p={4} bg="white" shadow="sm" borderRadius="lg">
            <Card.Body>
                <VStack align="start" gap={1}>
                    <Text fontSize="sm" color="gray.500">{name}</Text>
                    <HStack>
                        <Text fontWeight="bold" fontSize="lg">
                            {status === 'healthy' ? 'Connected' : status}
                        </Text>
                        <Badge colorPalette={statusColors[status]} size="sm">
                            {status === 'healthy' ? '●' : status === 'degraded' ? '◐' : '○'}
                        </Badge>
                    </HStack>
                    <Text fontSize="xs" color="gray.400">{description}</Text>
                </VStack>
            </Card.Body>
        </Card.Root>
    )
}

/**
 * Metrics Card
 */
const MetricCard = ({
    title,
    value,
    subtitle,
    trend,
}: {
    title: string
    value: string | number
    subtitle?: string
    trend?: { value: string; positive: boolean }
}) => {
    return (
        <Card.Root p={4} bg="white" shadow="sm" borderRadius="lg">
            <Card.Body>
                <VStack align="start" gap={1}>
                    <Text fontSize="sm" color="gray.500">{title}</Text>
                    <HStack>
                        <Text fontWeight="bold" fontSize="xl">{value}</Text>
                        {trend && (
                            <Text
                                fontSize="sm"
                                color={trend.positive ? 'green.500' : 'red.500'}
                            >
                                {trend.positive ? '↑' : '↓'} {trend.value}
                            </Text>
                        )}
                    </HStack>
                    {subtitle && <Text fontSize="xs" color="gray.400">{subtitle}</Text>}
                </VStack>
            </Card.Body>
        </Card.Root>
    )
}

/**
 * Trust Distribution visualization
 */
const TrustDistributionCard = ({ distribution }: { distribution: TrustDistribution }) => {
    const phaseColors = ['gray', 'blue', 'cyan', 'purple', 'green']

    return (
        <Card.Root bg="white" shadow="sm" borderRadius="lg">
            <Card.Header pb={2}>
                <Heading size="md">Trust Distribution</Heading>
                <Text fontSize="sm" color="gray.500">Users across Ghost trust phases</Text>
            </Card.Header>
            <Card.Body pt={0}>
                <VStack align="stretch" gap={3}>
                    {distribution.phases.map((phase, index) => (
                        <Box key={phase.phase}>
                            <HStack justify="space-between" mb={1}>
                                <HStack>
                                    <Text fontSize="sm" fontWeight="medium">{phase.phase}</Text>
                                    <Text fontSize="xs" color="gray.500">
                                        ({phase.count} users)
                                    </Text>
                                </HStack>
                                <Text fontSize="sm" fontWeight="bold">{phase.percentage}%</Text>
                            </HStack>
                            <Progress.Root value={phase.percentage} size="sm">
                                <Progress.Track>
                                    <Progress.Range bg={`${phaseColors[index]}.400`} />
                                </Progress.Track>
                            </Progress.Root>
                        </Box>
                    ))}
                </VStack>
                <HStack mt={4} pt={4} borderTopWidth={1} justify="space-between">
                    <VStack align="start" gap={0}>
                        <Text fontSize="xs" color="gray.500">Avg. time to Phase 2</Text>
                        <Text fontSize="sm" fontWeight="bold">{distribution.avgTimeToPhase2} days</Text>
                    </VStack>
                    <VStack align="end" gap={0}>
                        <Text fontSize="xs" color="gray.500">Avg. time to Phase 5</Text>
                        <Text fontSize="sm" fontWeight="bold">{distribution.avgTimeToPhase5} days</Text>
                    </VStack>
                </HStack>
            </Card.Body>
        </Card.Root>
    )
}

/**
 * Ghost Decisions Summary
 */
const GhostDecisionsCard = ({ metrics }: { metrics: GhostMetrics }) => {
    return (
        <Card.Root bg="white" shadow="sm" borderRadius="lg">
            <Card.Header pb={2}>
                <Heading size="md">Ghost Decisions (24h)</Heading>
                <Text fontSize="sm" color="gray.500">Autonomous actions taken by the Ghost</Text>
            </Card.Header>
            <Card.Body pt={0}>
                <Grid templateColumns="repeat(2, 1fr)" gap={4}>
                    <Box p={3} bg="blue.50" borderRadius="md">
                        <Text fontSize="sm" color="blue.600">Decisions</Text>
                        <Text fontSize="2xl" fontWeight="bold" color="blue.700">
                            {metrics.decisionsToday.toLocaleString()}
                        </Text>
                    </Box>
                    <Box p={3} bg="green.50" borderRadius="md">
                        <Text fontSize="sm" color="green.600">Calendar Mutations</Text>
                        <Text fontSize="2xl" fontWeight="bold" color="green.700">
                            {metrics.mutationsToday.toLocaleString()}
                        </Text>
                    </Box>
                    <Box p={3} bg="purple.50" borderRadius="md">
                        <Text fontSize="sm" color="purple.600">Accept Rate</Text>
                        <Text fontSize="2xl" fontWeight="bold" color="purple.700">
                            {metrics.acceptRate}%
                        </Text>
                        <Text fontSize="xs" color="purple.500">Target: 85%</Text>
                    </Box>
                    <Box p={3} bg="orange.50" borderRadius="md">
                        <Text fontSize="sm" color="orange.600">Safety Breakers</Text>
                        <Text fontSize="2xl" fontWeight="bold" color="orange.700">
                            {metrics.safetyBreakersTriggered}
                        </Text>
                        <Text fontSize="xs" color="orange.500">triggered</Text>
                    </Box>
                </Grid>
            </Card.Body>
        </Card.Root>
    )
}

/**
 * Quick Navigation Links
 */
const QuickLinksCard = () => {
    const links = [
        { path: '/admin/llm-health', label: 'Ghost Health', icon: '👻' },
        { path: '/admin/users', label: 'User Management', icon: '👥' },
        { path: '/admin/llm-config', label: 'AI Pipeline', icon: '🤖' },
        { path: '/admin/analytics', label: 'Analytics', icon: '📊' },
        { path: '/admin/audit', label: 'Decision Audit', icon: '🔒' },
    ]

    return (
        <Card.Root bg="white" shadow="sm" borderRadius="lg">
            <Card.Header pb={2}>
                <Heading size="md">Quick Navigation</Heading>
            </Card.Header>
            <Card.Body pt={0}>
                <HStack gap={3} flexWrap="wrap">
                    {links.map((link) => (
                        <RouterLink
                            key={link.path}
                            to={link.path}
                            style={{ textDecoration: 'none' }}
                        >
                            <Box
                                p={3}
                                bg="gray.50"
                                borderRadius="md"
                                _hover={{ bg: 'blue.50', transform: 'translateY(-1px)' }}
                                transition="all 0.2s"
                                cursor="pointer"
                            >
                                <VStack gap={1}>
                                    <Text fontSize="xl">{link.icon}</Text>
                                    <Text fontSize="sm" fontWeight="medium">{link.label}</Text>
                                </VStack>
                            </Box>
                        </RouterLink>
                    ))}
                </HStack>
            </Card.Body>
        </Card.Root>
    )
}

/**
 * System Information
 */
const SystemInfoCard = ({ user }: { user: { email?: string } | null }) => {
    return (
        <Card.Root bg="white" shadow="sm" borderRadius="lg">
            <Card.Header pb={2}>
                <Heading size="md">System Information</Heading>
            </Card.Header>
            <Card.Body pt={0}>
                <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={4}>
                    <Box>
                        <Text fontSize="xs" color="gray.500">Environment</Text>
                        <Text fontWeight="medium">Production</Text>
                    </Box>
                    <Box>
                        <Text fontSize="xs" color="gray.500">Region</Text>
                        <Text fontWeight="medium">West US 2</Text>
                    </Box>
                    <Box>
                        <Text fontSize="xs" color="gray.500">Backend</Text>
                        <Text fontWeight="medium">Azure Functions (Y1)</Text>
                    </Box>
                    <Box>
                        <Text fontSize="xs" color="gray.500">Database</Text>
                        <Text fontWeight="medium">Cosmos DB Serverless</Text>
                    </Box>
                    <Box>
                        <Text fontSize="xs" color="gray.500">AI Model</Text>
                        <Text fontWeight="medium">gpt-5-mini (Structured)</Text>
                    </Box>
                    <Box>
                        <Text fontSize="xs" color="gray.500">Admin User</Text>
                        <Text fontWeight="medium">{user?.email || 'Unknown'}</Text>
                    </Box>
                </Grid>
            </Card.Body>
        </Card.Root>
    )
}

export const AdminPage = () => {
    const { user } = useAuth()
    const [ghostHealth, setGhostHealth] = useState<GhostHealth | null>(null)
    const [trustDistribution, setTrustDistribution] = useState<TrustDistribution | null>(null)
    const [isLoading, setIsLoading] = useState(true)
    const [lastUpdated, setLastUpdated] = useState<Date>(new Date())

    useEffect(() => {
        const fetchData = async () => {
            setIsLoading(true)
            try {
                const [health, trust] = await Promise.all([
                    AdminAPI.getGhostHealth(),
                    AdminAPI.getTrustDistribution(),
                ])
                setGhostHealth(health)
                setTrustDistribution(trust)
                setLastUpdated(new Date())
            } catch (error) {
                console.error('Failed to fetch admin data:', error)
            } finally {
                setIsLoading(false)
            }
        }

        fetchData()
        // Refresh every 30 seconds
        const interval = setInterval(fetchData, 30000)
        return () => clearInterval(interval)
    }, [])

    // Calculate active users from trust distribution
    const activeUsers = trustDistribution?.phases.reduce((sum, p) => sum + p.count, 0) || 0

    return (
        <Box p={6}>
            <VStack align="stretch" gap={6}>
                {/* Header */}
                <Box>
                    <HStack justify="space-between" align="start">
                        <Box>
                            <Heading size="xl" mb={2}>Admin Dashboard</Heading>
                            <Text color="gray.500">
                                Ghost monitoring and management for Vigor platform
                            </Text>
                        </Box>
                        <VStack align="end" gap={0}>
                            <Text fontSize="xs" color="gray.400">
                                Last updated: {lastUpdated.toLocaleTimeString()}
                            </Text>
                            {isLoading && (
                                <Text fontSize="xs" color="blue.500">Refreshing...</Text>
                            )}
                        </VStack>
                    </HStack>
                </Box>

                {/* Ghost Status Row */}
                <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(4, 1fr)' }} gap={4}>
                    <GridItem>
                        <GhostModeCard
                            mode={ghostHealth?.mode || 'NORMAL'}
                            lastUpdated={ghostHealth?.lastUpdated || new Date().toISOString()}
                        />
                    </GridItem>
                    <GridItem>
                        <ComponentCard
                            name="Database"
                            status={ghostHealth?.components.find(c => c.name === 'Cosmos DB')?.status || 'healthy'}
                            description="Cosmos DB Serverless"
                        />
                    </GridItem>
                    <GridItem>
                        <ComponentCard
                            name="AI Pipeline"
                            status={ghostHealth?.components.find(c => c.name === 'gpt-5-mini')?.status || 'healthy'}
                            description="RAG + gpt-5-mini"
                        />
                    </GridItem>
                    <GridItem>
                        <MetricCard
                            title="Active Users"
                            value={activeUsers.toLocaleString()}
                            subtitle="7-day active"
                        />
                    </GridItem>
                </Grid>

                {/* Main Content Grid */}
                <Grid templateColumns={{ base: '1fr', lg: 'repeat(2, 1fr)' }} gap={6}>
                    {/* Trust Distribution */}
                    <GridItem>
                        {trustDistribution && (
                            <TrustDistributionCard distribution={trustDistribution} />
                        )}
                    </GridItem>

                    {/* Ghost Decisions */}
                    <GridItem>
                        {ghostHealth && (
                            <GhostDecisionsCard metrics={ghostHealth.metrics} />
                        )}
                    </GridItem>
                </Grid>

                {/* Quick Navigation */}
                <QuickLinksCard />

                {/* System Information */}
                <SystemInfoCard user={user} />
            </VStack>
        </Box>
    )
}

export default AdminPage
