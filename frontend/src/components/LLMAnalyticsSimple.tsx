/**
 * LLM Analytics Dashboard (Simple Version)
 * Advanced analytics and performance monitoring for LLM usage across the platform
 */
import {
    Badge,
    Box,
    Button,
    Container,
    Flex,
    Grid,
    Heading,
    Text,
} from '@chakra-ui/react';
import React, { useCallback, useEffect, useState } from 'react';
import {
    FiActivity,
    FiBarChart,
    FiDollarSign,
    FiDownload,
    FiRefreshCw,
    FiTrendingDown,
    FiTrendingUp,
    FiUsers,
    FiZap,
} from 'react-icons/fi';

interface AnalyticsData {
    overview: {
        totalRequests: number;
        totalCost: number;
        averageResponseTime: number;
        successRate: number;
        activeModels: number;
        totalTokens: number;
    };
    trends: {
        requestsChange: number;
        costChange: number;
        responseTimeChange: number;
        successRateChange: number;
    };
    modelPerformance: Array<{
        modelId: string;
        name: string;
        requests: number;
        cost: number;
        averageResponseTime: number;
        successRate: number;
        tokens: number;
        efficiency: number;
    }>;
    topEndpoints: Array<{
        endpoint: string;
        requests: number;
        averageResponseTime: number;
        errorRate: number;
    }>;
    userMetrics: {
        activeUsers: number;
        newUsers: number;
        retentionRate: number;
        averageSessionLength: number;
    };
}

const LLMAnalyticsSimple: React.FC = () => {
    const [analyticsData, setAnalyticsData] = useState<AnalyticsData | null>(null);
    const [selectedTimeRange, setSelectedTimeRange] = useState('24h');
    const [isLoading, setIsLoading] = useState(true);
    const [isExporting, setIsExporting] = useState(false);
    const [lastUpdated, setLastUpdated] = useState(new Date());

    const fetchAnalyticsData = useCallback(async () => {
        try {
            setIsLoading(true);
            // Generate realistic mock data for demonstration
            const mockData: AnalyticsData = {
                overview: {
                    totalRequests: 45230,
                    totalCost: 127.45,
                    averageResponseTime: 1240,
                    successRate: 99.2,
                    activeModels: 4,
                    totalTokens: 2847392,
                },
                trends: {
                    requestsChange: 12.3,
                    costChange: -5.2,
                    responseTimeChange: -8.1,
                    successRateChange: 0.3,
                },
                modelPerformance: [
                    {
                        modelId: 'gpt-4o',
                        name: 'GPT-4 Optimized',
                        requests: 23450,
                        cost: 78.23,
                        averageResponseTime: 980,
                        successRate: 99.8,
                        tokens: 1847392,
                        efficiency: 94.2,
                    },
                    {
                        modelId: 'gpt-3.5-turbo',
                        name: 'GPT-3.5 Turbo',
                        requests: 18390,
                        cost: 23.12,
                        averageResponseTime: 650,
                        successRate: 99.1,
                        tokens: 892847,
                        efficiency: 87.6,
                    },
                    {
                        modelId: 'claude-3-sonnet',
                        name: 'Claude 3 Sonnet',
                        requests: 2890,
                        cost: 18.97,
                        averageResponseTime: 1450,
                        successRate: 98.3,
                        tokens: 89453,
                        efficiency: 91.4,
                    },
                    {
                        modelId: 'gemini-pro',
                        name: 'Gemini Pro',
                        requests: 500,
                        cost: 7.13,
                        averageResponseTime: 2100,
                        successRate: 96.8,
                        tokens: 17700,
                        efficiency: 76.2,
                    },
                ],
                topEndpoints: [
                    { endpoint: '/api/workouts/generate', requests: 28340, averageResponseTime: 1200, errorRate: 0.5 },
                    { endpoint: '/api/coach/chat', requests: 12890, averageResponseTime: 800, errorRate: 0.8 },
                    { endpoint: '/api/workouts/analyze', requests: 3890, averageResponseTime: 1500, errorRate: 1.2 },
                    { endpoint: '/api/nutrition/suggestions', requests: 120, averageResponseTime: 2100, errorRate: 2.1 },
                ],
                userMetrics: {
                    activeUsers: 1247,
                    newUsers: 89,
                    retentionRate: 78.3,
                    averageSessionLength: 18.7,
                },
            };

            setAnalyticsData(mockData);
            setLastUpdated(new Date());
        } catch (error) {
            console.error('Failed to fetch analytics data:', error);
        } finally {
            setIsLoading(false);
        }
    }, []);

    const exportData = useCallback(async () => {
        try {
            setIsExporting(true);
            // Generate CSV data from analytics
            const csvData = analyticsData?.modelPerformance.map(model => ({
                Model: model.name,
                Requests: model.requests,
                Cost: `$${model.cost.toFixed(2)}`,
                'Response Time (ms)': model.averageResponseTime,
                'Success Rate (%)': model.successRate,
                Tokens: model.tokens,
                'Efficiency Score': model.efficiency,
            }));

            const csvString = [
                Object.keys(csvData?.[0] || {}).join(','),
                ...(csvData || []).map(row => Object.values(row).join(','))
            ].join('\n');

            const blob = new Blob([csvString], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.style.display = 'none';
            a.href = url;
            a.download = `llm-analytics-${selectedTimeRange}-${new Date().toISOString().split('T')[0]}.csv`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
        } catch (error) {
            console.error('Failed to export data:', error);
        } finally {
            setIsExporting(false);
        }
    }, [analyticsData, selectedTimeRange]);

    useEffect(() => {
        fetchAnalyticsData();
        const interval = setInterval(fetchAnalyticsData, 60000); // Refresh every minute
        return () => clearInterval(interval);
    }, [fetchAnalyticsData]);

    const getStatusColor = (value: number, isInverted = false) => {
        if (isInverted) {
            return value > 0 ? 'red.500' : 'green.500';
        }
        return value > 0 ? 'green.500' : 'red.500';
    };

    const getTrendIcon = (value: number, isInverted = false) => {
        if (isInverted) {
            return value > 0 ? FiTrendingDown : FiTrendingUp;
        }
        return value > 0 ? FiTrendingUp : FiTrendingDown;
    };

    if (isLoading && !analyticsData) {
        return (
            <Container maxW="7xl" py={8}>
                <Flex direction="column" align="stretch" gap={6}>
                    <Flex justify="center" py={20}>
                        <Box textAlign="center">
                            <FiBarChart size={48} />
                            <Text mt={4}>Loading analytics data...</Text>
                        </Box>
                    </Flex>
                </Flex>
            </Container>
        );
    }

    return (
        <Container maxW="7xl" py={8}>
            <Flex direction="column" align="stretch" gap={6}>
                {/* Header */}
                <Flex justify="space-between" align="center" wrap="wrap" gap={4}>
                    <Box>
                        <Heading size="lg">LLM Analytics Dashboard</Heading>
                        <Text color="gray.600" fontSize="sm">
                            Last updated: {lastUpdated.toLocaleTimeString()}
                        </Text>
                    </Box>

                    <Flex gap={3}>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={exportData}
                            loading={isExporting}
                            loadingText="Exporting..."
                        >
                            <FiDownload style={{ marginRight: '8px' }} />
                            Export Data
                        </Button>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={fetchAnalyticsData}
                            loading={isLoading}
                        >
                            <FiRefreshCw style={{ marginRight: '8px' }} />
                            Refresh
                        </Button>
                    </Flex>
                </Flex>

                {/* Time Range Selector */}
                <Flex gap={3}>
                    {['1h', '6h', '24h', '7d', '30d'].map((range) => (
                        <Button
                            key={range}
                            size="sm"
                            variant={selectedTimeRange === range ? 'solid' : 'outline'}
                            onClick={() => setSelectedTimeRange(range)}
                        >
                            {range}
                        </Button>
                    ))}
                </Flex>

                {/* Overview Metrics */}
                <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(4, 1fr)' }} gap={6}>
                    <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                        <Flex direction="column" align="flex-start" gap={3}>
                            <Flex align="center" gap={2}>
                                <Box p={2} bg="blue.100" borderRadius="md">
                                    <FiActivity color="blue.600" />
                                </Box>
                                <Text fontSize="sm" color="gray.600">Total Requests</Text>
                            </Flex>
                            <Box>
                                <Text fontSize="2xl" fontWeight="bold">
                                    {analyticsData?.overview.totalRequests.toLocaleString()}
                                </Text>
                                <Flex align="center" gap={1}>
                                    {React.createElement(getTrendIcon(analyticsData?.trends.requestsChange || 0), {
                                        size: 16,
                                        color: getStatusColor(analyticsData?.trends.requestsChange || 0)
                                    })}
                                    <Text
                                        fontSize="sm"
                                        color={getStatusColor(analyticsData?.trends.requestsChange || 0)}
                                    >
                                        {Math.abs(analyticsData?.trends.requestsChange || 0).toFixed(1)}%
                                    </Text>
                                </Flex>
                            </Box>
                        </Flex>
                    </Box>

                    <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                        <Flex direction="column" align="flex-start" gap={3}>
                            <Flex align="center" gap={2}>
                                <Box p={2} bg="green.100" borderRadius="md">
                                    <FiDollarSign color="green.600" />
                                </Box>
                                <Text fontSize="sm" color="gray.600">Total Cost</Text>
                            </Flex>
                            <Box>
                                <Text fontSize="2xl" fontWeight="bold">
                                    ${analyticsData?.overview.totalCost.toFixed(2)}
                                </Text>
                                <Flex align="center" gap={1}>
                                    {React.createElement(getTrendIcon(analyticsData?.trends.costChange || 0, true), {
                                        size: 16,
                                        color: getStatusColor(analyticsData?.trends.costChange || 0, true)
                                    })}
                                    <Text
                                        fontSize="sm"
                                        color={getStatusColor(analyticsData?.trends.costChange || 0, true)}
                                    >
                                        {Math.abs(analyticsData?.trends.costChange || 0).toFixed(1)}%
                                    </Text>
                                </Flex>
                            </Box>
                        </Flex>
                    </Box>

                    <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                        <Flex direction="column" align="flex-start" gap={3}>
                            <Flex align="center" gap={2}>
                                <Box p={2} bg="orange.100" borderRadius="md">
                                    <FiZap color="orange.600" />
                                </Box>
                                <Text fontSize="sm" color="gray.600">Avg Response Time</Text>
                            </Flex>
                            <Box>
                                <Text fontSize="2xl" fontWeight="bold">
                                    {analyticsData?.overview.averageResponseTime}ms
                                </Text>
                                <Flex align="center" gap={1}>
                                    {React.createElement(getTrendIcon(analyticsData?.trends.responseTimeChange || 0, true), {
                                        size: 16,
                                        color: getStatusColor(analyticsData?.trends.responseTimeChange || 0, true)
                                    })}
                                    <Text
                                        fontSize="sm"
                                        color={getStatusColor(analyticsData?.trends.responseTimeChange || 0, true)}
                                    >
                                        {Math.abs(analyticsData?.trends.responseTimeChange || 0).toFixed(1)}%
                                    </Text>
                                </Flex>
                            </Box>
                        </Flex>
                    </Box>

                    <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                        <Flex direction="column" align="flex-start" gap={3}>
                            <Flex align="center" gap={2}>
                                <Box p={2} bg="purple.100" borderRadius="md">
                                    <FiUsers color="purple.600" />
                                </Box>
                                <Text fontSize="sm" color="gray.600">Success Rate</Text>
                            </Flex>
                            <Box>
                                <Text fontSize="2xl" fontWeight="bold">
                                    {analyticsData?.overview.successRate}%
                                </Text>
                                <Flex align="center" gap={1}>
                                    {React.createElement(getTrendIcon(analyticsData?.trends.successRateChange || 0), {
                                        size: 16,
                                        color: getStatusColor(analyticsData?.trends.successRateChange || 0)
                                    })}
                                    <Text
                                        fontSize="sm"
                                        color={getStatusColor(analyticsData?.trends.successRateChange || 0)}
                                    >
                                        {Math.abs(analyticsData?.trends.successRateChange || 0).toFixed(1)}%
                                    </Text>
                                </Flex>
                            </Box>
                        </Flex>
                    </Box>
                </Grid>

                {/* Model Performance */}
                <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                    <Heading size="md" mb={4}>Model Performance Analysis</Heading>
                    <Flex direction="column" gap={4}>
                        {analyticsData?.modelPerformance.map((model) => (
                            <Box key={model.modelId} p={4} border="1px" borderColor="gray.200" borderRadius="md">
                                <Flex direction="column" gap={3}>
                                    <Flex justify="space-between" align="center">
                                        <Box>
                                            <Text fontWeight="semibold">{model.name}</Text>
                                            <Text fontSize="sm" color="gray.600">
                                                {model.requests.toLocaleString()} requests
                                            </Text>
                                        </Box>
                                        <Badge
                                            colorScheme={model.efficiency > 90 ? 'green' : model.efficiency > 80 ? 'orange' : 'red'}
                                        >
                                            {model.efficiency}% efficiency
                                        </Badge>
                                    </Flex>

                                    <Grid templateColumns={{ base: '1fr', md: 'repeat(4, 1fr)' }} gap={4}>
                                        <Box>
                                            <Text fontSize="sm" color="gray.600">Cost</Text>
                                            <Text fontWeight="semibold">${model.cost.toFixed(2)}</Text>
                                        </Box>
                                        <Box>
                                            <Text fontSize="sm" color="gray.600">Response Time</Text>
                                            <Text fontWeight="semibold">{model.averageResponseTime}ms</Text>
                                        </Box>
                                        <Box>
                                            <Text fontSize="sm" color="gray.600">Success Rate</Text>
                                            <Text fontWeight="semibold">{model.successRate}%</Text>
                                        </Box>
                                        <Box>
                                            <Text fontSize="sm" color="gray.600">Tokens</Text>
                                            <Text fontWeight="semibold">{model.tokens.toLocaleString()}</Text>
                                        </Box>
                                    </Grid>

                                    <Box w="full" bg="gray.200" borderRadius="md" h="8px">
                                        <Box
                                            h="full"
                                            bg="blue.500"
                                            borderRadius="md"
                                            width={`${model.efficiency}%`}
                                            transition="width 0.3s ease"
                                        />
                                    </Box>
                                </Flex>
                            </Box>
                        ))}
                    </Flex>
                </Box>

                {/* Top Endpoints and User Metrics */}
                <Grid templateColumns={{ base: '1fr', lg: 'repeat(2, 1fr)' }} gap={6}>
                    <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                        <Heading size="md" mb={4}>Top API Endpoints</Heading>
                        <Flex direction="column" gap={3}>
                            {analyticsData?.topEndpoints.map((endpoint) => (
                                <Flex key={endpoint.endpoint} justify="space-between" align="center">
                                    <Box>
                                        <Text fontWeight="semibold" fontSize="sm">
                                            {endpoint.endpoint}
                                        </Text>
                                        <Text fontSize="xs" color="gray.600">
                                            {endpoint.requests.toLocaleString()} requests
                                        </Text>
                                    </Box>
                                    <Box textAlign="right">
                                        <Text fontSize="sm">{endpoint.averageResponseTime}ms</Text>
                                        <Badge
                                            colorScheme={endpoint.errorRate < 1 ? 'green' : endpoint.errorRate < 2 ? 'orange' : 'red'}
                                            size="sm"
                                        >
                                            {endpoint.errorRate}% errors
                                        </Badge>
                                    </Box>
                                </Flex>
                            ))}
                        </Flex>
                    </Box>

                    <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                        <Heading size="md" mb={4}>User Metrics</Heading>
                        <Flex direction="column" gap={4}>
                            <Flex justify="space-between" align="center">
                                <Text fontSize="sm" color="gray.600">Active Users</Text>
                                <Text fontWeight="semibold">
                                    {analyticsData?.userMetrics.activeUsers.toLocaleString()}
                                </Text>
                            </Flex>
                            <Flex justify="space-between" align="center">
                                <Text fontSize="sm" color="gray.600">New Users</Text>
                                <Text fontWeight="semibold">
                                    {analyticsData?.userMetrics.newUsers.toLocaleString()}
                                </Text>
                            </Flex>
                            <Flex justify="space-between" align="center">
                                <Text fontSize="sm" color="gray.600">Retention Rate</Text>
                                <Text fontWeight="semibold">
                                    {analyticsData?.userMetrics.retentionRate}%
                                </Text>
                            </Flex>
                            <Flex justify="space-between" align="center">
                                <Text fontSize="sm" color="gray.600">Avg Session Length</Text>
                                <Text fontWeight="semibold">
                                    {analyticsData?.userMetrics.averageSessionLength}min
                                </Text>
                            </Flex>
                        </Flex>
                    </Box>
                </Grid>
            </Flex>
        </Container>
    );
};

export default LLMAnalyticsSimple;
