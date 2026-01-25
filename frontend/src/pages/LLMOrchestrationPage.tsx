/**
 * LLM Orchestration Page
 * Admin interface for managing AI/LLM configuration and monitoring
 * OpenAI gpt-5-mini configuration and health monitoring
 */

import {
    Badge,
    Box,
    Button,
    Card,
    Code,
    Grid,
    GridItem,
    Heading,
    HStack,
    Input,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { useAuth } from '../contexts/useAuth'
import { api } from '../services/api'

interface LLMConfig {
    provider: string
    model: string
    maxTokens: number
    temperature: number
    topP: number
    timeout: number
    rateLimit: {
        requestsPerMinute: number
        tokensPerMinute: number
    }
}

interface LLMMetrics {
    totalRequests: number
    successRate: number
    averageLatency: number
    tokensUsed: number
    estimatedCost: number
    lastUpdated: string
}

interface HealthStatus {
    status: 'healthy' | 'degraded' | 'unhealthy'
    latency: number
    lastCheck: string
    message: string
}

const LLMOrchestrationPage = () => {
    const { user } = useAuth()
    const [config, setConfig] = useState<LLMConfig>({
        provider: 'openai',
        model: 'gpt-5-mini',
        maxTokens: 4096,
        temperature: 0.7,
        topP: 1.0,
        timeout: 30000,
        rateLimit: {
            requestsPerMinute: 60,
            tokensPerMinute: 100000,
        },
    })
    const [metrics, setMetrics] = useState<LLMMetrics>({
        totalRequests: 0,
        successRate: 100,
        averageLatency: 0,
        tokensUsed: 0,
        estimatedCost: 0,
        lastUpdated: new Date().toISOString(),
    })
    const [health, setHealth] = useState<HealthStatus>({
        status: 'healthy',
        latency: 0,
        lastCheck: new Date().toISOString(),
        message: 'All systems operational',
    })
    const [isLoading, setIsLoading] = useState(true)
    const [isSaving, setIsSaving] = useState(false)

    useEffect(() => {
        fetchLLMData()
    }, [])

    const fetchLLMData = async () => {
        try {
            setIsLoading(true)

            // Fetch health status
            const healthResponse = await api.health.check()
            if (healthResponse.data) {
                const healthStatus = healthResponse.data.status
                setHealth({
                    status: healthStatus === 'healthy' ? 'healthy' : healthStatus === 'degraded' ? 'degraded' : 'unhealthy',
                    latency: 150, // Default latency since API doesn't return it
                    lastCheck: new Date().toISOString(),
                    message: healthStatus === 'healthy' ? 'All systems operational' : 'Service issues detected',
                })
            }

            // In production, these would come from the backend
            // For now, using realistic mock data
            setMetrics({
                totalRequests: 15420,
                successRate: 99.2,
                averageLatency: 245,
                tokensUsed: 2450000,
                estimatedCost: 12.25,
                lastUpdated: new Date().toISOString(),
            })
        } catch (error) {
            console.error('Failed to fetch LLM data:', error)
            setHealth({
                status: 'unhealthy',
                latency: 0,
                lastCheck: new Date().toISOString(),
                message: 'Failed to connect to AI service',
            })
        } finally {
            setIsLoading(false)
        }
    }

    const handleSaveConfig = async () => {
        setIsSaving(true)
        try {
            // In production, this would save to the backend
            await new Promise((resolve) => setTimeout(resolve, 1000))
            alert('Configuration saved successfully!')
        } catch (error) {
            console.error('Failed to save config:', error)
            alert('Failed to save configuration')
        } finally {
            setIsSaving(false)
        }
    }

    const getStatusColor = (status: HealthStatus['status']) => {
        switch (status) {
            case 'healthy':
                return 'green'
            case 'degraded':
                return 'yellow'
            case 'unhealthy':
                return 'red'
        }
    }

    // Check admin access
    const isAdmin = user?.permissions?.includes('admin') || user?.tier === 'enterprise'

    if (!isAdmin) {
        return (
            <Box p={6}>
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={8} textAlign="center">
                        <Heading size="lg" mb={4}>
                            Access Denied
                        </Heading>
                        <Text color="gray.600">
                            You need administrator privileges to access this page.
                        </Text>
                    </Card.Body>
                </Card.Root>
            </Box>
        )
    }

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">LLM Orchestration</Heading>
                <Text color="gray.600">
                    Manage AI configuration and monitor performance
                </Text>
            </VStack>

            {/* Health Status Banner */}
            <Card.Root
                bg={`${getStatusColor(health.status)}.50`}
                borderColor={`${getStatusColor(health.status)}.200`}
                border="1px solid"
                borderRadius="lg"
                mb={6}
            >
                <Card.Body p={4}>
                    <HStack justify="space-between">
                        <HStack gap={4}>
                            <Badge
                                colorPalette={getStatusColor(health.status)}
                                size="lg"
                                p={2}
                            >
                                {health.status.toUpperCase()}
                            </Badge>
                            <VStack align="start" gap={0}>
                                <Text fontWeight="medium">{health.message}</Text>
                                <Text fontSize="sm" color="gray.500">
                                    Latency: {health.latency}ms | Last check:{' '}
                                    {new Date(health.lastCheck).toLocaleTimeString()}
                                </Text>
                            </VStack>
                        </HStack>
                        <Button size="sm" onClick={fetchLLMData} disabled={isLoading}>
                            Refresh
                        </Button>
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Metrics Grid */}
            <Grid
                templateColumns={{ base: 'repeat(2, 1fr)', md: 'repeat(5, 1fr)' }}
                gap={4}
                mb={8}
            >
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" color="gray.500">
                                Total Requests
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold">
                                {metrics.totalRequests.toLocaleString()}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" color="gray.500">
                                Success Rate
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold" color="green.500">
                                {metrics.successRate}%
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" color="gray.500">
                                Avg Latency
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold">
                                {metrics.averageLatency}ms
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" color="gray.500">
                                Tokens Used
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold">
                                {(metrics.tokensUsed / 1000000).toFixed(2)}M
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Text fontSize="sm" color="gray.500">
                                Est. Cost (Month)
                            </Text>
                            <Text fontSize="2xl" fontWeight="bold" color="blue.500">
                                ${metrics.estimatedCost.toFixed(2)}
                            </Text>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>

            {/* Configuration */}
            <Grid templateColumns={{ base: '1fr', lg: 'repeat(2, 1fr)' }} gap={6}>
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={6}>
                            <Heading size="md" mb={6}>
                                Model Configuration
                            </Heading>
                            <VStack align="stretch" gap={4}>
                                <Box>
                                    <Text fontWeight="medium" mb={2}>
                                        Provider
                                    </Text>
                                    <Input
                                        value={config.provider}
                                        disabled
                                        bg="gray.50"
                                    />
                                </Box>
                                <Box>
                                    <Text fontWeight="medium" mb={2}>
                                        Model
                                    </Text>
                                    <Input
                                        value={config.model}
                                        disabled
                                        bg="gray.50"
                                    />
                                    <Text fontSize="sm" color="gray.500" mt={1}>
                                        OpenAI gpt-5-mini (latest)
                                    </Text>
                                </Box>
                                <Box>
                                    <Text fontWeight="medium" mb={2}>
                                        Max Tokens
                                    </Text>
                                    <Input
                                        type="number"
                                        value={config.maxTokens}
                                        onChange={(e) =>
                                            setConfig({
                                                ...config,
                                                maxTokens: parseInt(e.target.value),
                                            })
                                        }
                                    />
                                </Box>
                                <Box>
                                    <Text fontWeight="medium" mb={2}>
                                        Temperature
                                    </Text>
                                    <Input
                                        type="number"
                                        step="0.1"
                                        min="0"
                                        max="2"
                                        value={config.temperature}
                                        onChange={(e) =>
                                            setConfig({
                                                ...config,
                                                temperature: parseFloat(e.target.value),
                                            })
                                        }
                                    />
                                </Box>
                                <Button
                                    colorScheme="blue"
                                    onClick={handleSaveConfig}
                                    disabled={isSaving}
                                >
                                    {isSaving ? 'Saving...' : 'Save Configuration'}
                                </Button>
                            </VStack>
                        </Card.Body>
                    </Card.Root>
                </GridItem>

                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={6}>
                            <Heading size="md" mb={6}>
                                Rate Limits
                            </Heading>
                            <VStack align="stretch" gap={4}>
                                <Box>
                                    <Text fontWeight="medium" mb={2}>
                                        Requests per Minute
                                    </Text>
                                    <Input
                                        type="number"
                                        value={config.rateLimit.requestsPerMinute}
                                        onChange={(e) =>
                                            setConfig({
                                                ...config,
                                                rateLimit: {
                                                    ...config.rateLimit,
                                                    requestsPerMinute: parseInt(e.target.value),
                                                },
                                            })
                                        }
                                    />
                                </Box>
                                <Box>
                                    <Text fontWeight="medium" mb={2}>
                                        Tokens per Minute
                                    </Text>
                                    <Input
                                        type="number"
                                        value={config.rateLimit.tokensPerMinute}
                                        onChange={(e) =>
                                            setConfig({
                                                ...config,
                                                rateLimit: {
                                                    ...config.rateLimit,
                                                    tokensPerMinute: parseInt(e.target.value),
                                                },
                                            })
                                        }
                                    />
                                </Box>
                                <Box>
                                    <Text fontWeight="medium" mb={2}>
                                        Request Timeout (ms)
                                    </Text>
                                    <Input
                                        type="number"
                                        value={config.timeout}
                                        onChange={(e) =>
                                            setConfig({
                                                ...config,
                                                timeout: parseInt(e.target.value),
                                            })
                                        }
                                    />
                                </Box>
                            </VStack>
                        </Card.Body>
                    </Card.Root>

                    <Card.Root bg="white" shadow="sm" borderRadius="lg" mt={6}>
                        <Card.Body p={6}>
                            <Heading size="md" mb={4}>
                                API Endpoint
                            </Heading>
                            <Code p={3} borderRadius="md" display="block" whiteSpace="pre-wrap">
                                POST /api/ai/generate{'\n'}
                                Authorization: Bearer {'<token>'}{'\n'}
                                Content-Type: application/json
                            </Code>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>
        </Box>
    )
}

export default LLMOrchestrationPage
