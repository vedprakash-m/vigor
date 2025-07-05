import {
    Badge,
    Box,
    Button,
    Container,
    Flex,
    Grid,
    Heading,
    HStack,
    Text,
    VStack
} from '@chakra-ui/react';
import React, { useCallback, useEffect, useState } from 'react';
import {
    FiActivity,
    FiCpu,
    FiDollarSign,
    FiHeart,
    FiRefreshCw,
    FiSettings,
    FiTrendingUp,
    FiUsers,
    FiZap,
} from 'react-icons/fi';
import { llmHealthService, type LLMModel, type SystemMetrics } from '../services/llmHealthService';

const LLMHealthMonitoring: React.FC = () => {
  const [models, setModels] = useState<LLMModel[]>([]);
  const [systemMetrics, setSystemMetrics] = useState<SystemMetrics | null>(null);
  const [selectedTimeRange, setSelectedTimeRange] = useState('24h');
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState(new Date());

  // Fetch real data from the API
  const fetchHealthData = useCallback(async () => {
    try {
      setIsLoading(true);
      const overview = await llmHealthService.getHealthOverview(selectedTimeRange);
      setModels(overview.models);
      setSystemMetrics(overview.systemMetrics);
      setLastUpdated(overview.lastUpdated);
    } catch (error) {
      console.error('Failed to fetch LLM health data:', error);
      // Fallback to mock data for development
      loadMockData();
    } finally {
      setIsLoading(false);
    }
  }, [selectedTimeRange]);

  // Mock data fallback for development
  const loadMockData = () => {
    const mockModels: LLMModel[] = [
      {
        id: '1',
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
        id: '2',
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
      {
        id: '3',
        name: 'Azure-GPT-4',
        provider: 'Azure',
        status: 'degraded',
        responseTime: 2100,
        requestCount: 5640,
        errorRate: 0.08,
        cost: 45.12,
        lastHealthCheck: new Date(),
        configuration: {
          temperature: 0.7,
          maxTokens: 4096,
          topP: 0.9,
          enabled: true,
        },
      },
    ];

    const mockSystemMetrics: SystemMetrics = {
      totalRequests: 30092,
      averageResponseTime: 1320,
      overallErrorRate: 0.035,
      dailyCost: 201.80,
      activeUsers: 247,
      systemLoad: 0.68,
    };

    setModels(mockModels);
    setSystemMetrics(mockSystemMetrics);
    setIsLoading(false);
    setLastUpdated(new Date());
  };

  useEffect(() => {
    fetchHealthData();
  }, [fetchHealthData]);

  // Auto refresh every 30 seconds
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(() => {
      fetchHealthData();
    }, 30000);

    return () => clearInterval(interval);
  }, [autoRefresh, fetchHealthData]);

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

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatPercentage = (value: number) => {
    return `${(value * 100).toFixed(2)}%`;
  };

  const StatCard = ({ icon, label, value, color = 'blue' }: {
    icon: React.ElementType;
    label: string;
    value: string | number;
    color?: string;
  }) => {
    const IconComponent = icon;
    return (
      <Box
        bg="white"
        p={6}
        borderRadius="lg"
        border="1px"
        borderColor="gray.200"
        shadow="sm"
        _dark={{
          bg: 'gray.800',
          borderColor: 'gray.600',
        }}
      >
        <VStack alignItems="flex-start" gap={2}>
          <HStack>
            <IconComponent color={color} />
            <Text fontSize="sm" color="gray.500">{label}</Text>
          </HStack>
          <Text fontSize="2xl" fontWeight="bold">{value}</Text>
        </VStack>
      </Box>
    );
  };

  const ModelCard = ({ model }: { model: LLMModel }) => (
    <Box
      bg="white"
      p={6}
      borderRadius="lg"
      border="1px"
      borderColor="gray.200"
      shadow="sm"
      _dark={{
        bg: 'gray.800',
        borderColor: 'gray.600',
      }}
    >
      <VStack alignItems="stretch" gap={4}>
        <HStack justify="space-between">
          <VStack alignItems="flex-start" gap={1}>
            <Heading size="md">{model.name}</Heading>
            <Text color="gray.500" fontSize="sm">{model.provider}</Text>
          </VStack>
          <Badge colorScheme={getStatusColor(model.status)}>
            {model.status.toUpperCase()}
          </Badge>
        </HStack>

        <Grid templateColumns="repeat(2, 1fr)" gap={4}>
          <VStack alignItems="flex-start">
            <Text fontSize="sm" color="gray.500">Response Time</Text>
            <Text fontWeight="bold">{model.responseTime}ms</Text>
          </VStack>
          <VStack alignItems="flex-start">
            <Text fontSize="sm" color="gray.500">Requests</Text>
            <Text fontWeight="bold">{model.requestCount.toLocaleString()}</Text>
          </VStack>
          <VStack alignItems="flex-start">
            <Text fontSize="sm" color="gray.500">Error Rate</Text>
            <Text fontWeight="bold">{formatPercentage(model.errorRate)}</Text>
          </VStack>
          <VStack alignItems="flex-start">
            <Text fontSize="sm" color="gray.500">Daily Cost</Text>
            <Text fontWeight="bold">{formatCurrency(model.cost)}</Text>
          </VStack>
        </Grid>

        <Box>
          <Text fontSize="sm" color="gray.500" mb={2}>Configuration</Text>
          <Grid templateColumns="repeat(2, 1fr)" gap={2} fontSize="sm">
            <Text>Temperature: {model.configuration.temperature}</Text>
            <Text>Max Tokens: {model.configuration.maxTokens}</Text>
            <Text>Top-P: {model.configuration.topP}</Text>
            <Text>Status: {model.configuration.enabled ? 'Enabled' : 'Disabled'}</Text>
          </Grid>
        </Box>

        <HStack justify="space-between">
          <Button size="sm">
            <FiSettings style={{ marginRight: '8px' }} />
            Configure
          </Button>
          <Button size="sm" variant="outline">
            <FiActivity style={{ marginRight: '8px' }} />
            View Metrics
          </Button>
        </HStack>
      </VStack>
    </Box>
  );

  if (isLoading) {
    return (
      <Container maxW="7xl" py={8}>
        <VStack gap={8}>
          <Heading>Loading LLM Health Dashboard...</Heading>
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
            <Heading size="lg">LLM Health Monitoring</Heading>
            <Text color="gray.500">
              Last updated: {lastUpdated.toLocaleTimeString()}
            </Text>
          </VStack>

          <HStack gap={4}>
            <Box>
              <Text fontSize="sm" color="gray.500" mb={1}>Time Range</Text>
              <select
                value={selectedTimeRange}
                onChange={(e) => setSelectedTimeRange(e.target.value)}
                style={{
                  padding: '8px 12px',
                  borderRadius: '6px',
                  border: '1px solid #e2e8f0',
                  backgroundColor: 'white',
                }}
              >
                <option value="1h">1 Hour</option>
                <option value="24h">24 Hours</option>
                <option value="7d">7 Days</option>
                <option value="30d">30 Days</option>
              </select>
            </Box>

            <VStack alignItems="flex-start" gap={1}>
              <Text fontSize="sm" color="gray.500">Auto Refresh</Text>
              <label style={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={autoRefresh}
                  onChange={(e) => setAutoRefresh(e.target.checked)}
                  style={{ marginRight: '8px' }}
                />
                <Text fontSize="sm">Enabled</Text>
              </label>
            </VStack>

            <Button onClick={() => fetchHealthData()}>
              <FiRefreshCw style={{ marginRight: '8px' }} />
              Refresh
            </Button>
          </HStack>
        </Flex>

        {/* System Overview */}
        {systemMetrics && (
          <Box>
            <Heading size="md" mb={4}>System Overview</Heading>
            <Grid templateColumns="repeat(auto-fit, minmax(250px, 1fr))" gap={6}>
              <StatCard
                icon={FiActivity}
                label="Total Requests"
                value={systemMetrics.totalRequests.toLocaleString()}
                color="blue"
              />
              <StatCard
                icon={FiZap}
                label="Avg Response Time"
                value={`${systemMetrics.averageResponseTime}ms`}
                color="purple"
              />
              <StatCard
                icon={FiTrendingUp}
                label="Error Rate"
                value={formatPercentage(systemMetrics.overallErrorRate)}
                color="red"
              />
              <StatCard
                icon={FiDollarSign}
                label="Daily Cost"
                value={formatCurrency(systemMetrics.dailyCost)}
                color="green"
              />
              <StatCard
                icon={FiUsers}
                label="Active Users"
                value={systemMetrics.activeUsers}
                color="cyan"
              />
              <StatCard
                icon={FiCpu}
                label="System Load"
                value={formatPercentage(systemMetrics.systemLoad)}
                color="orange"
              />
            </Grid>
          </Box>
        )}

        {/* LLM Models Status */}
        <Box>
          <Heading size="md" mb={4}>LLM Models</Heading>
          <Grid templateColumns="repeat(auto-fit, minmax(400px, 1fr))" gap={6}>
            {models.map((model) => (
              <ModelCard key={model.id} model={model} />
            ))}
          </Grid>
        </Box>

        {/* Health Status Summary */}
        <Box
          bg="white"
          p={6}
          borderRadius="lg"
          border="1px"
          borderColor="gray.200"
          shadow="sm"
          _dark={{
            bg: 'gray.800',
            borderColor: 'gray.600',
          }}
        >
          <Heading size="md" mb={4}>System Health Status</Heading>
          <Grid templateColumns="repeat(auto-fit, minmax(200px, 1fr))" gap={4}>
            <VStack alignItems="flex-start">
              <Badge colorScheme="green" fontSize="sm">
                <HStack>
                  <FiHeart />
                  <Text>HEALTHY MODELS</Text>
                </HStack>
              </Badge>
              <Text fontSize="2xl" fontWeight="bold">
                {models.filter(m => m.status === 'healthy').length}
              </Text>
            </VStack>
            <VStack alignItems="flex-start">
              <Badge colorScheme="yellow" fontSize="sm">
                DEGRADED MODELS
              </Badge>
              <Text fontSize="2xl" fontWeight="bold">
                {models.filter(m => m.status === 'degraded').length}
              </Text>
            </VStack>
            <VStack alignItems="flex-start">
              <Badge colorScheme="red" fontSize="sm">
                OFFLINE MODELS
              </Badge>
              <Text fontSize="2xl" fontWeight="bold">
                {models.filter(m => m.status === 'offline').length}
              </Text>
            </VStack>
          </Grid>
        </Box>
      </VStack>
    </Container>
  );
};

export default LLMHealthMonitoring;
