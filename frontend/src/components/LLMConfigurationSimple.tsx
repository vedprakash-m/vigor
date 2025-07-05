/**
 * LLM Configuration Management
 * Advanced interface for managing LLM model configurations, parameters, and settings
 */
import {
    Badge,
    Box,
    Button,
    Container,
    Flex,
    Grid,
    Heading,
    HStack,
    Input,
    Text,
    VStack,
} from '@chakra-ui/react';
import React, { useCallback, useEffect, useState } from 'react';
import {
    FiActivity,
    FiAlertTriangle,
    FiRefreshCw,
    FiSave,
    FiTarget,
    FiZap,
} from 'react-icons/fi';
import { llmHealthService, type LLMModel } from '../services/llmHealthService';

interface ConfigurationChange {
    modelId: string;
    field: string;
    oldValue: string | number | boolean;
    newValue: string | number | boolean;
    timestamp: Date;
}

const LLMConfigurationManagement: React.FC = () => {
    const [models, setModels] = useState<LLMModel[]>([]);
    const [selectedModel, setSelectedModel] = useState<LLMModel | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);
    const [configChanges, setConfigChanges] = useState<ConfigurationChange[]>([]);
    const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);

    // Temporary configuration state for editing
    const [tempConfig, setTempConfig] = useState<LLMModel['configuration'] | null>(null);

    const loadModels = useCallback(async () => {
        try {
            setIsLoading(true);
            const modelsData = await llmHealthService.getModels();
            setModels(modelsData);
            if (modelsData.length > 0 && !selectedModel) {
                setSelectedModel(modelsData[0]);
                setTempConfig(modelsData[0].configuration);
            }
        } catch (error) {
            console.error('Failed to load models:', error);
            // Load mock data as fallback
            loadMockData();
        } finally {
            setIsLoading(false);
        }
    }, [selectedModel]);

    const loadMockData = () => {
        const mockModels: LLMModel[] = [
            {
                id: 'gpt-4',
                name: 'GPT-4',
                provider: 'OpenAI',
                status: 'healthy',
                responseTime: 1200,
                requestCount: 15432,
                errorRate: 0.02,
                cost: 89.45,
                lastHealthCheck: new Date(),
                configuration: {
                    temperature: 0.7,
                    maxTokens: 4096,
                    topP: 0.9,
                    enabled: true,
                },
            },
            {
                id: 'claude-3',
                name: 'Claude-3',
                provider: 'Anthropic',
                status: 'healthy',
                responseTime: 980,
                requestCount: 8920,
                errorRate: 0.01,
                cost: 67.23,
                lastHealthCheck: new Date(),
                configuration: {
                    temperature: 0.8,
                    maxTokens: 8192,
                    topP: 0.95,
                    enabled: true,
                },
            },
        ];

        setModels(mockModels);
        if (mockModels.length > 0) {
            setSelectedModel(mockModels[0]);
            setTempConfig(mockModels[0].configuration);
        }
    };

    useEffect(() => {
        loadModels();
    }, [loadModels]);

    useEffect(() => {
        if (selectedModel && tempConfig) {
            const hasChanges =
                selectedModel.configuration.temperature !== tempConfig.temperature ||
                selectedModel.configuration.maxTokens !== tempConfig.maxTokens ||
                selectedModel.configuration.topP !== tempConfig.topP ||
                selectedModel.configuration.enabled !== tempConfig.enabled;

            setHasUnsavedChanges(hasChanges);
        }
    }, [selectedModel, tempConfig]);

    const handleModelSelect = (model: LLMModel) => {
        if (hasUnsavedChanges) {
            if (!window.confirm('You have unsaved changes. Are you sure you want to switch models?')) {
                return;
            }
        }
        setSelectedModel(model);
        setTempConfig(model.configuration);
        setHasUnsavedChanges(false);
    };

    const handleConfigChange = (field: keyof LLMModel['configuration'], value: any) => {
        if (!tempConfig) return;

        setTempConfig({
            ...tempConfig,
            [field]: value,
        });
    };

    const handleSaveConfiguration = async () => {
        if (!selectedModel || !tempConfig) return;

        try {
            setIsSaving(true);

            // Track changes
            const changes: ConfigurationChange[] = [];
            Object.entries(tempConfig).forEach(([field, newValue]) => {
                const oldValue = selectedModel.configuration[field as keyof LLMModel['configuration']];
                if (oldValue !== newValue) {
                    changes.push({
                        modelId: selectedModel.id,
                        field,
                        oldValue,
                        newValue,
                        timestamp: new Date(),
                    });
                }
            });

            // Save to backend
            await llmHealthService.updateModelConfiguration(selectedModel.id, tempConfig);

            // Update local state
            const updatedModels = models.map(model =>
                model.id === selectedModel.id
                    ? { ...model, configuration: tempConfig }
                    : model
            );
            setModels(updatedModels);
            setSelectedModel({ ...selectedModel, configuration: tempConfig });
            setConfigChanges([...configChanges, ...changes]);
            setHasUnsavedChanges(false);

            alert('Configuration saved successfully!');
        } catch (error) {
            console.error('Failed to save configuration:', error);
            alert('Failed to save configuration. Please try again.');
        } finally {
            setIsSaving(false);
        }
    };

    const handleResetConfiguration = () => {
        if (!selectedModel) return;
        setTempConfig(selectedModel.configuration);
        setHasUnsavedChanges(false);
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'healthy':
                return 'green';
            case 'degraded':
                return 'yellow';
            case 'offline':
                return 'red';
            default:
                return 'gray';
        }
    };

    if (isLoading) {
        return (
            <Container maxW="7xl" py={8}>
                <VStack gap={8}>
                    <Heading>Loading LLM Configuration...</Heading>
                </VStack>
            </Container>
        );
    }

    return (
        <Container maxW="7xl" py={8}>
            <VStack gap={8} alignItems="stretch">
                {/* Header */}
                <Flex justify="space-between" align="center">
                    <VStack alignItems="flex-start" gap={1}>
                        <Heading size="lg">LLM Configuration Management</Heading>
                        <Text color="gray.500">
                            Configure model parameters and settings
                        </Text>
                    </VStack>

                    <HStack gap={4}>
                        <Button
                            variant="outline"
                            onClick={() => loadModels()}
                            disabled={isLoading}
                        >
                            <FiRefreshCw style={{ marginRight: '8px' }} />
                            Refresh
                        </Button>
                        {hasUnsavedChanges && (
                            <Badge colorScheme="orange" p={2}>
                                <FiAlertTriangle style={{ marginRight: '4px' }} />
                                Unsaved Changes
                            </Badge>
                        )}
                    </HStack>
                </Flex>

                <Grid templateColumns="300px 1fr" gap={8}>
                    {/* Model Selection Sidebar */}
                    <Box>
                        <Heading size="md" mb={4}>Models</Heading>
                        <VStack gap={3} alignItems="stretch">
                            {models.map((model) => (
                                <Box
                                    key={model.id}
                                    p={4}
                                    borderRadius="lg"
                                    border="2px"
                                    borderColor={selectedModel?.id === model.id ? 'blue.500' : 'gray.200'}
                                    bg={selectedModel?.id === model.id ? 'blue.50' : 'white'}
                                    cursor="pointer"
                                    onClick={() => handleModelSelect(model)}
                                    _hover={{
                                        borderColor: 'blue.300',
                                        bg: 'blue.25',
                                    }}
                                    _dark={{
                                        bg: selectedModel?.id === model.id ? 'blue.900' : 'gray.800',
                                        borderColor: selectedModel?.id === model.id ? 'blue.300' : 'gray.600',
                                    }}
                                >
                                    <VStack alignItems="flex-start" gap={2}>
                                        <HStack justify="space-between" width="100%">
                                            <Text fontWeight="bold">{model.name}</Text>
                                            <Badge colorScheme={getStatusColor(model.status)} size="sm">
                                                {model.status}
                                            </Badge>
                                        </HStack>
                                        <Text fontSize="sm" color="gray.500">{model.provider}</Text>
                                        <Text fontSize="xs" color="gray.400">
                                            {model.requestCount.toLocaleString()} requests
                                        </Text>
                                    </VStack>
                                </Box>
                            ))}
                        </VStack>
                    </Box>

                    {/* Configuration Panel */}
                    {selectedModel && tempConfig && (
                        <Box>
                            <Flex justify="space-between" align="center" mb={6}>
                                <Heading size="md">Configure {selectedModel.name}</Heading>
                                <HStack gap={3}>
                                    <Button
                                        variant="outline"
                                        onClick={handleResetConfiguration}
                                        disabled={!hasUnsavedChanges}
                                    >
                                        Reset
                                    </Button>
                                    <Button
                                        colorScheme="blue"
                                        onClick={handleSaveConfiguration}
                                        disabled={!hasUnsavedChanges || isSaving}
                                    >
                                        <FiSave style={{ marginRight: '8px' }} />
                                        {isSaving ? 'Saving...' : 'Save Configuration'}
                                    </Button>
                                </HStack>
                            </Flex>

                            <VStack gap={8} alignItems="stretch">
                                {/* Model Status */}
                                <Box
                                    bg="white"
                                    p={6}
                                    borderRadius="lg"
                                    border="1px"
                                    borderColor="gray.200"
                                    _dark={{
                                        bg: 'gray.800',
                                        borderColor: 'gray.600',
                                    }}
                                >
                                    <Heading size="sm" mb={4}>Model Status</Heading>
                                    <Grid templateColumns="repeat(auto-fit, minmax(150px, 1fr))" gap={4}>
                                        <VStack alignItems="flex-start">
                                            <HStack>
                                                <FiActivity color="blue" />
                                                <Text fontSize="sm" color="gray.500">Status</Text>
                                            </HStack>
                                            <Badge colorScheme={getStatusColor(selectedModel.status)}>
                                                {selectedModel.status.toUpperCase()}
                                            </Badge>
                                        </VStack>
                                        <VStack alignItems="flex-start">
                                            <HStack>
                                                <FiZap color="purple" />
                                                <Text fontSize="sm" color="gray.500">Response Time</Text>
                                            </HStack>
                                            <Text fontWeight="bold">{selectedModel.responseTime}ms</Text>
                                        </VStack>
                                        <VStack alignItems="flex-start">
                                            <HStack>
                                                <FiTarget color="green" />
                                                <Text fontSize="sm" color="gray.500">Error Rate</Text>
                                            </HStack>
                                            <Text fontWeight="bold">{(selectedModel.errorRate * 100).toFixed(2)}%</Text>
                                        </VStack>
                                        <VStack alignItems="flex-start">
                                            <Text fontSize="sm" color="gray.500">Enabled</Text>
                                            <label style={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
                                                <input
                                                    type="checkbox"
                                                    checked={tempConfig.enabled}
                                                    onChange={(e) => handleConfigChange('enabled', e.target.checked)}
                                                    style={{ marginRight: '8px' }}
                                                />
                                                <Text fontSize="sm">
                                                    {tempConfig.enabled ? 'Active' : 'Disabled'}
                                                </Text>
                                            </label>
                                        </VStack>
                                    </Grid>
                                </Box>

                                {/* Configuration Parameters */}
                                <Box
                                    bg="white"
                                    p={6}
                                    borderRadius="lg"
                                    border="1px"
                                    borderColor="gray.200"
                                    _dark={{
                                        bg: 'gray.800',
                                        borderColor: 'gray.600',
                                    }}
                                >
                                    <Heading size="sm" mb={6}>Model Parameters</Heading>
                                    <Grid templateColumns="repeat(auto-fit, minmax(300px, 1fr))" gap={6}>
                                        {/* Temperature */}
                                        <Box>
                                            <VStack alignItems="flex-start" gap={3}>
                                                <Text fontWeight="medium">Temperature</Text>
                                                <Text fontSize="sm" color="gray.500">
                                                    Controls randomness (0.0 = deterministic, 2.0 = very random)
                                                </Text>
                                                <Input
                                                    value={tempConfig.temperature}
                                                    onChange={(e) => handleConfigChange('temperature', parseFloat(e.target.value) || 0)}
                                                    type="number"
                                                    step="0.1"
                                                    min="0"
                                                    max="2"
                                                    placeholder="0.7"
                                                />
                                                <Text fontSize="xs" color="gray.400">
                                                    Range: 0.0 - 2.0
                                                </Text>
                                            </VStack>
                                        </Box>

                                        {/* Top-P */}
                                        <Box>
                                            <VStack alignItems="flex-start" gap={3}>
                                                <Text fontWeight="medium">Top-P (Nucleus Sampling)</Text>
                                                <Text fontSize="sm" color="gray.500">
                                                    Controls diversity by considering only top P probability mass
                                                </Text>
                                                <Input
                                                    value={tempConfig.topP}
                                                    onChange={(e) => handleConfigChange('topP', parseFloat(e.target.value) || 0)}
                                                    type="number"
                                                    step="0.05"
                                                    min="0"
                                                    max="1"
                                                    placeholder="0.9"
                                                />
                                                <Text fontSize="xs" color="gray.400">
                                                    Range: 0.0 - 1.0
                                                </Text>
                                            </VStack>
                                        </Box>

                                        {/* Max Tokens */}
                                        <Box>
                                            <VStack alignItems="flex-start" gap={3}>
                                                <Text fontWeight="medium">Max Tokens</Text>
                                                <Text fontSize="sm" color="gray.500">
                                                    Maximum number of tokens in the response
                                                </Text>
                                                <Input
                                                    value={tempConfig.maxTokens}
                                                    onChange={(e) => handleConfigChange('maxTokens', parseInt(e.target.value) || 0)}
                                                    type="number"
                                                    step="256"
                                                    min="256"
                                                    max="32768"
                                                    placeholder="4096"
                                                />
                                                <Text fontSize="xs" color="gray.400">
                                                    Current: {tempConfig.maxTokens.toLocaleString()} tokens
                                                </Text>
                                            </VStack>
                                        </Box>
                                    </Grid>
                                </Box>

                                {/* Recent Changes */}
                                {configChanges.length > 0 && (
                                    <Box
                                        bg="white"
                                        p={6}
                                        borderRadius="lg"
                                        border="1px"
                                        borderColor="gray.200"
                                        _dark={{
                                            bg: 'gray.800',
                                            borderColor: 'gray.600',
                                        }}
                                    >
                                        <Heading size="sm" mb={4}>Recent Configuration Changes</Heading>
                                        <VStack gap={3} alignItems="stretch">
                                            {configChanges.slice(-5).reverse().map((change, index) => (
                                                <Box key={index} p={3} bg="gray.50" borderRadius="md" _dark={{ bg: 'gray.700' }}>
                                                    <Text fontSize="sm">
                                                        <Text as="span" fontWeight="medium">{change.field}</Text>
                                                        {' changed from '}
                                                        <Text as="span" color="red.500">{String(change.oldValue)}</Text>
                                                        {' to '}
                                                        <Text as="span" color="green.500">{String(change.newValue)}</Text>
                                                    </Text>
                                                    <Text fontSize="xs" color="gray.500">
                                                        {change.timestamp.toLocaleString()}
                                                    </Text>
                                                </Box>
                                            ))}
                                        </VStack>
                                    </Box>
                                )}
                            </VStack>
                        </Box>
                    )}
                </Grid>
            </VStack>
        </Container>
    );
};

export default LLMConfigurationManagement;
