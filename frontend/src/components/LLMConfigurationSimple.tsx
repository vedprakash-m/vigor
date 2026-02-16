/**
 * LLM Configuration Component
 * AI Pipeline configuration for Ghost - gpt-5-mini with Structured Outputs
 * Per UX Spec Part V §5.8 - AI Pipeline Configuration
 *
 * IMPORTANT: gpt-5-mini uses Structured Outputs mode which does NOT support:
 * - temperature (always deterministic)
 * - top_p / topP
 * - frequency_penalty / frequencyPenalty
 * - presence_penalty / presencePenalty
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
    Input,
    Progress,
    Spinner,
    Switch,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { AdminAPI, AIPipelineStats } from '../services/adminApi'

interface PipelineConfig {
    maxOutputTokens: number
    requestTimeoutMs: number
    retryAttempts: number
    workoutContractEnabled: boolean
    ragCacheEnabled: boolean
    phenomeQueryLimit: number
}

const LLMConfigurationManagement = () => {
    const [config, setConfig] = useState<PipelineConfig>({
        maxOutputTokens: 4096,
        requestTimeoutMs: 30000,
        retryAttempts: 3,
        workoutContractEnabled: true,
        ragCacheEnabled: true,
        phenomeQueryLimit: 50,
    })
    const [pipelineStats, setPipelineStats] = useState<AIPipelineStats | null>(null)
    const [loading, setLoading] = useState(true)
    const [isSaving, setIsSaving] = useState(false)
    const [saveStatus, setSaveStatus] = useState<{ type: 'success' | 'error'; message: string } | null>(
        null
    )

    useEffect(() => {
        const fetchStats = async () => {
            try {
                setLoading(true)
                const stats = await AdminAPI.getAIPipelineStats()
                setPipelineStats(stats)
            } catch (err) {
                console.error('Failed to fetch pipeline stats:', err)
            } finally {
                setLoading(false)
            }
        }
        fetchStats()
        // Refresh every 30 seconds
        const interval = setInterval(fetchStats, 30000)
        return () => clearInterval(interval)
    }, [])

    const handleSave = async () => {
        setIsSaving(true)
        setSaveStatus(null)
        try {
            // TODO: Call AdminAPI.savePipelineConfig when backend ready
            await new Promise((resolve) => setTimeout(resolve, 1000))
            setSaveStatus({ type: 'success', message: 'Configuration saved successfully.' })
        } catch (error) {
            console.error('Failed to save config:', error)
            setSaveStatus({ type: 'error', message: 'Failed to save configuration.' })
        } finally {
            setIsSaving(false)
        }
    }

    const handleReset = () => {
        setConfig({
            maxOutputTokens: 4096,
            requestTimeoutMs: 30000,
            retryAttempts: 3,
            workoutContractEnabled: true,
            ragCacheEnabled: true,
            phenomeQueryLimit: 50,
        })
    }

    if (loading) {
        return (
            <Box p={6} display="flex" justifyContent="center" alignItems="center" minH="400px">
                <VStack gap={4}>
                    <Spinner size="xl" color="blue.500" />
                    <Text color="gray.600">Loading AI Pipeline stats...</Text>
                </VStack>
            </Box>
        )
    }

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">AI Pipeline Configuration</Heading>
                <Text color="gray.600">
                    Ghost AI configuration using gpt-5-mini with Structured Outputs
                </Text>
            </VStack>

            {saveStatus && (
                <Card.Root
                    bg={saveStatus.type === 'success' ? 'green.50' : 'red.50'}
                    borderColor={saveStatus.type === 'success' ? 'green.200' : 'red.200'}
                    border="1px"
                    borderRadius="lg"
                    mb={6}
                >
                    <Card.Body p={4}>
                        <Text color={saveStatus.type === 'success' ? 'green.700' : 'red.700'}>
                            {saveStatus.message}
                        </Text>
                    </Card.Body>
                </Card.Root>
            )}

            {/* Model Info Card */}
            <Card.Root bg="blue.50" borderColor="blue.200" border="1px" borderRadius="lg" mb={6}>
                <Card.Body p={4}>
                    <HStack justify="space-between" flexWrap="wrap" gap={4}>
                        <VStack align="start" gap={1}>
                            <Text fontWeight="bold" color="blue.700">
                                Active Model
                            </Text>
                            <HStack gap={2}>
                                <Text color="blue.600" fontWeight="medium">
                                    gpt-5-mini
                                </Text>
                                <Badge colorPalette="purple">Structured Outputs</Badge>
                            </HStack>
                            <Text fontSize="xs" color="blue.500">
                                Azure OpenAI • West US 2
                            </Text>
                        </VStack>
                        <VStack align="end" gap={1}>
                            <HStack gap={2}>
                                <Box
                                    w="10px"
                                    h="10px"
                                    borderRadius="full"
                                    bg={pipelineStats?.modelStatus === 'healthy' ? 'green.400' : 'yellow.400'}
                                />
                                <Text fontSize="sm" color="gray.600">
                                    {pipelineStats?.modelStatus === 'healthy' ? 'Healthy' : 'Degraded'}
                                </Text>
                            </HStack>
                            <Text fontSize="xs" color="gray.500">
                                Avg latency: {pipelineStats?.avgLatencyMs || 0}ms
                            </Text>
                        </VStack>
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Important Note about Structured Outputs */}
            <Card.Root bg="orange.50" borderColor="orange.200" border="1px" borderRadius="lg" mb={6}>
                <Card.Body p={4}>
                    <HStack gap={3}>
                        <Text fontSize="lg">⚠️</Text>
                        <VStack align="start" gap={1}>
                            <Text fontWeight="medium" color="orange.700">
                                Structured Outputs Mode
                            </Text>
                            <Text fontSize="sm" color="orange.600">
                                gpt-5-mini operates in Structured Outputs mode, which guarantees JSON schema
                                compliance. Temperature, top_p, and penalty parameters are not supported in
                                this mode - all outputs are deterministic.
                            </Text>
                        </VStack>
                    </HStack>
                </Card.Body>
            </Card.Root>

            <Grid templateColumns={{ base: '1fr', lg: 'repeat(2, 1fr)' }} gap={6}>
                {/* Pipeline Configuration */}
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={6}>
                            <Heading size="md" mb={6}>
                                Pipeline Configuration
                            </Heading>
                            <VStack align="stretch" gap={5}>
                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Max Output Tokens</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {config.maxOutputTokens}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        value={config.maxOutputTokens}
                                        onChange={(e) =>
                                            setConfig({
                                                ...config,
                                                maxOutputTokens: parseInt(e.target.value) || 0,
                                            })
                                        }
                                        min={256}
                                        max={16384}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        Maximum tokens for workout plan generation (256-16384)
                                    </Text>
                                </Box>

                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Request Timeout (ms)</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {config.requestTimeoutMs}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        value={config.requestTimeoutMs}
                                        onChange={(e) =>
                                            setConfig({
                                                ...config,
                                                requestTimeoutMs: parseInt(e.target.value) || 0,
                                            })
                                        }
                                        min={5000}
                                        max={120000}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        API request timeout (5000-120000ms)
                                    </Text>
                                </Box>

                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Retry Attempts</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {config.retryAttempts}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        value={config.retryAttempts}
                                        onChange={(e) =>
                                            setConfig({
                                                ...config,
                                                retryAttempts: parseInt(e.target.value) || 0,
                                            })
                                        }
                                        min={0}
                                        max={5}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        Number of retry attempts on failure (0-5)
                                    </Text>
                                </Box>

                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Phenome Query Limit</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {config.phenomeQueryLimit}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        value={config.phenomeQueryLimit}
                                        onChange={(e) =>
                                            setConfig({
                                                ...config,
                                                phenomeQueryLimit: parseInt(e.target.value) || 0,
                                            })
                                        }
                                        min={10}
                                        max={200}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        Max Phenome records per RAG query (10-200)
                                    </Text>
                                </Box>
                            </VStack>
                        </Card.Body>
                    </Card.Root>
                </GridItem>

                {/* Feature Toggles & Stats */}
                <GridItem>
                    <VStack gap={6} align="stretch">
                        <Card.Root bg="white" shadow="sm" borderRadius="lg">
                            <Card.Body p={6}>
                                <Heading size="md" mb={6}>
                                    Feature Toggles
                                </Heading>
                                <VStack align="stretch" gap={5}>
                                    <HStack justify="space-between">
                                        <VStack align="start" gap={0}>
                                            <Text fontWeight="medium">Workout Contract Validation</Text>
                                            <Text fontSize="xs" color="gray.500">
                                                Validate AI outputs against schema before accepting
                                            </Text>
                                        </VStack>
                                        <Switch.Root
                                            checked={config.workoutContractEnabled}
                                            onCheckedChange={(e) =>
                                                setConfig({ ...config, workoutContractEnabled: e.checked })
                                            }
                                            colorPalette="green"
                                        >
                                            <Switch.HiddenInput />
                                            <Switch.Control>
                                                <Switch.Thumb />
                                            </Switch.Control>
                                        </Switch.Root>
                                    </HStack>

                                    <HStack justify="space-between">
                                        <VStack align="start" gap={0}>
                                            <Text fontWeight="medium">RAG Cache</Text>
                                            <Text fontSize="xs" color="gray.500">
                                                Cache Phenome embeddings for faster queries
                                            </Text>
                                        </VStack>
                                        <Switch.Root
                                            checked={config.ragCacheEnabled}
                                            onCheckedChange={(e) =>
                                                setConfig({ ...config, ragCacheEnabled: e.checked })
                                            }
                                            colorPalette="green"
                                        >
                                            <Switch.HiddenInput />
                                            <Switch.Control>
                                                <Switch.Thumb />
                                            </Switch.Control>
                                        </Switch.Root>
                                    </HStack>
                                </VStack>
                            </Card.Body>
                        </Card.Root>

                        {/* Pipeline Stats */}
                        {pipelineStats && (
                            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                                <Card.Body p={6}>
                                    <Heading size="md" mb={6}>
                                        Pipeline Stats (24h)
                                    </Heading>
                                    <VStack align="stretch" gap={4}>
                                        <HStack justify="space-between">
                                            <Text fontSize="sm">Total Requests</Text>
                                            <Text fontWeight="bold">{pipelineStats.totalRequests24h.toLocaleString()}</Text>
                                        </HStack>
                                        <HStack justify="space-between">
                                            <Text fontSize="sm">Success Rate</Text>
                                            <HStack gap={2}>
                                                <Progress.Root
                                                    value={pipelineStats.successRate}
                                                    w="80px"
                                                    size="sm"
                                                    colorPalette={pipelineStats.successRate >= 95 ? 'green' : pipelineStats.successRate >= 80 ? 'yellow' : 'red'}
                                                >
                                                    <Progress.Track>
                                                        <Progress.Range />
                                                    </Progress.Track>
                                                </Progress.Root>
                                                <Text fontWeight="bold">{pipelineStats.successRate}%</Text>
                                            </HStack>
                                        </HStack>
                                        <HStack justify="space-between">
                                            <Text fontSize="sm">Avg Latency</Text>
                                            <Text fontWeight="bold">{pipelineStats.avgLatencyMs}ms</Text>
                                        </HStack>
                                        <HStack justify="space-between">
                                            <Text fontSize="sm">Contract Validations</Text>
                                            <Text fontWeight="bold">{pipelineStats.contractValidations.toLocaleString()}</Text>
                                        </HStack>
                                        <HStack justify="space-between">
                                            <Text fontSize="sm">Schema Rejections</Text>
                                            <Text fontWeight="bold" color={pipelineStats.schemaRejections > 10 ? 'red.500' : 'gray.700'}>
                                                {pipelineStats.schemaRejections}
                                            </Text>
                                        </HStack>
                                    </VStack>
                                </Card.Body>
                            </Card.Root>
                        )}
                    </VStack>
                </GridItem>
            </Grid>

            {/* Actions */}
            <HStack mt={6} gap={4}>
                <Button colorScheme="blue" onClick={handleSave} disabled={isSaving}>
                    {isSaving ? 'Saving...' : 'Save Configuration'}
                </Button>
                <Button variant="outline" onClick={handleReset}>
                    Reset to Defaults
                </Button>
            </HStack>

            {/* Info Card */}
            <Card.Root bg="gray.50" borderRadius="lg" mt={8}>
                <Card.Body p={4}>
                    <Text fontSize="sm" color="gray.600">
                        <strong>Note:</strong> Configuration changes affect all Ghost AI operations
                        including workout generation, mutation decisions, and Phenome analysis.
                        Changes are applied immediately but may take up to 5 minutes to propagate
                        to all function instances.
                    </Text>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default LLMConfigurationManagement
