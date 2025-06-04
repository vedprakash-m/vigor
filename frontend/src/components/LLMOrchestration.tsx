import {
    Badge,
    Box,
    Button,
    Flex,
    Grid,
    Heading,
    HStack,
    Spacer,
    Spinner,
    Text,
    Textarea,
    VStack
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import { useAuth } from '../contexts/useAuth';

// Define missing types
interface User {
  id: string;
  name: string;
}

interface LLMResponse {
  content: string;
  model_used: string;
  provider: string;
  request_id: string;
  status: string;
  timestamp: string;
  cached: boolean;
  tokens_used: number;
  cost_estimate: number;
  latency_ms: number;
}

interface SystemStatus {
  active_models: number;
  total_models: number;
  cache_stats: {
    size: number;
    hits: number;
    misses: number;
    hit_rate: number;
  };
  budget_status: {
    total_usage: number;
    global_limit: number;
    usage_percentage: number;
  };
  providers: Record<string, { is_healthy: boolean; status: string; provider: string; model_name: string; latency_ms?: number }>; // Updated type
}

export const LLMOrchestration: React.FC = () => {
  const { user }: { user: User | null } = useAuth();
  const [prompt, setPrompt] = useState('');
  const [response, setResponse] = useState<LLMResponse | null>(null);
  const [systemStatus, setSystemStatus] = useState<SystemStatus | null>(null);

  // Fetch system status
  const fetchSystemStatus = async () => {
    try {
      const response = await fetch('/api/llm/status', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      if (response.ok) {
        const data = await response.json();
        setSystemStatus(data);
      }
    } catch (error) {
      console.error('Failed to fetch system status:', error);
    }
  };

  // Send LLM request
  const sendLLMRequest = async () => {
    if (!prompt.trim()) return;

    try {
      const response = await fetch('/api/llm/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({
          prompt,
          task_type: 'chat',
          metadata: {
            source: 'vigor_frontend',
            timestamp: new Date().toISOString()
          }
        })
      });

      if (response.ok) {
        const data: LLMResponse = await response.json();
        setResponse(data);
        fetchSystemStatus();
      } else {
        // Handle error response
      }
    } catch (error) {
      console.error('LLM request error:', error);
      // Handle network error
    }
  };

  useEffect(() => {
    if (user) {
      fetchSystemStatus();
    }
  }, [user]);

  // Fix implicit 'any' types
  const handlePromptChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => setPrompt(e.target.value);

  return (
    <Box p={6} maxW="1200px" mx="auto">
      <Flex align="center" mb={6}>
        <Heading size="lg">Enterprise LLM Orchestration</Heading>
        <Spacer />
        <Badge colorScheme="blue" fontSize="sm">
          🤖 Intelligent AI Routing
        </Badge>
      </Flex>

      <VStack alignItems="stretch">
        {/* AI Chat Section */}
        <Box p={6} borderWidth={1} borderRadius="lg" bg="white" boxShadow="sm">
          <Heading size="md" mb={4}>🧠 Enterprise AI Chat</Heading>
          <Text color="gray.600" fontSize="sm" mb={4}>
            Powered by intelligent routing, budget management, and enterprise security
          </Text>

          <VStack alignItems="stretch">
            <Box>
              <Text fontWeight="bold" mb={2}>Your Prompt</Text>
              <Textarea
                placeholder="Enter prompt"
                value={prompt}
                onChange={handlePromptChange}
                rows={4}
              />
            </Box>

            <VStack alignItems="stretch">
              <Button
                colorScheme="blue"
                size="lg"
                width="full"
                onClick={sendLLMRequest}
              >
                Send Request
              </Button>
            </VStack>

            {response && (
              <Box p={4} borderWidth={1} borderRadius="md" bg="gray.50">
                <Flex align="center" justify="space-between" mb={3}>
                  <Heading size="sm">Response</Heading>
                  <HStack>
                    <Badge colorScheme="blue">{response.provider}</Badge>
                    <Badge colorScheme="green">{response.model_used}</Badge>
                    {response.cached && <Badge colorScheme="purple">🚀 Cached</Badge>}
                  </HStack>
                </Flex>

                <Text mb={4} whiteSpace="pre-wrap">{response.content}</Text>

                <Grid templateColumns="repeat(auto-fit, minmax(150px, 1fr))" gap={4}>
                  <Box fontSize="sm" color="gray.600">
                    <Text fontWeight="bold">Tokens:</Text>
                    <Text>{response.tokens_used}</Text>
                  </Box>
                  <Box fontSize="sm" color="gray.600">
                    <Text fontWeight="bold">Cost:</Text>
                    <Text>${response.cost_estimate.toFixed(6)}</Text>
                  </Box>
                  <Box fontSize="sm" color="gray.600">
                    <Text fontWeight="bold">Latency:</Text>
                    <Text>{response.latency_ms}ms</Text>
                  </Box>
                  <Box fontSize="sm" color="gray.600">
                    <Text fontWeight="bold">Request ID:</Text>
                    <Text>{response.request_id.slice(0, 8)}...</Text>
                  </Box>
                </Grid>
              </Box>
            )}
          </VStack>
        </Box>

        {/* System Status Section */}
        <Box p={6} borderWidth={1} borderRadius="lg" bg="white" boxShadow="sm">
          <Heading size="md" mb={4}>📊 System Status</Heading>

          {systemStatus ? (
            <Grid templateColumns="repeat(auto-fit, minmax(250px, 1fr))" gap={4}>
              <Box p={4} borderWidth={1} borderRadius="md">
                <Heading size="sm" mb={2}>🤖 Models</Heading>
                <VStack spacing={2} align="stretch">
                  <Flex justify="space-between">
                    <Text>Active:</Text>
                    <Badge>{systemStatus.active_models}</Badge>
                  </Flex>
                  <Flex justify="space-between">
                    <Text>Total:</Text>
                    <Badge>{systemStatus.total_models}</Badge>
                  </Flex>
                </VStack>
              </Box>

              <Box p={4} borderWidth={1} borderRadius="md">
                <Heading size="sm" mb={2}>⚡ Cache</Heading>
                <VStack spacing={2} align="stretch">
                  <Flex justify="space-between">
                    <Text>Hit Rate:</Text>
                    <Badge colorScheme="green">{systemStatus.cache_stats.hit_rate.toFixed(1)}%</Badge>
                  </Flex>
                  <Flex justify="space-between">
                    <Text>Size:</Text>
                    <Badge>{systemStatus.cache_stats.size}</Badge>
                  </Flex>
                </VStack>
              </Box>

              <Box p={4} borderWidth={1} borderRadius="md">
                <Heading size="sm" mb={2}>💰 Budget</Heading>
                <VStack spacing={2} align="stretch">
                  <Flex justify="space-between">
                    <Text>Usage:</Text>
                    <Badge>${systemStatus.budget_status.total_usage.toFixed(2)}</Badge>
                  </Flex>
                  <Flex justify="space-between">
                    <Text>Percentage:</Text>
                    <Badge
                      colorScheme={systemStatus.budget_status.usage_percentage > 80 ? 'red' : 'green'}
                    >
                      {systemStatus.budget_status.usage_percentage.toFixed(1)}%
                    </Badge>
                  </Flex>
                </VStack>
              </Box>
            </Grid>
          ) : (
            <Flex justify="center">
              <Spinner />
            </Flex>
          )}
        </Box>

        {/* Provider Health */}
        {systemStatus?.providers && (
          <Box p={6} borderWidth={1} borderRadius="lg" bg="white" boxShadow="sm">
            <Heading size="md" mb={4}>🛡️ Provider Health</Heading>
            <Grid templateColumns="repeat(auto-fit, minmax(250px, 1fr))" gap={4}>
              {Object.entries(systemStatus.providers).map(([modelId, provider]: [string, { is_healthy: boolean; status: string; provider: string; model_name: string; latency_ms?: number }]) => (
                <Box key={modelId} p={3} borderWidth={1} borderRadius="md">
                  <Flex align="center" justify="space-between" mb={2}>
                    <Text fontWeight="bold">{modelId}</Text>
                    <Badge colorScheme={provider.is_healthy ? "green" : "red"}>
                      {provider.is_healthy ? '✅ Healthy' : '❌ Unhealthy'}
                    </Badge>
                  </Flex>
                  <VStack align="start" spacing={1} fontSize="sm" color="gray.600">
                    <Text>Provider: {provider.provider}</Text>
                    <Text>Model: {provider.model_name}</Text>
                    {provider.latency_ms && <Text>Latency: {provider.latency_ms}ms</Text>}
                  </VStack>
                </Box>
              ))}
            </Grid>
          </Box>
        )}
      </VStack>
    </Box>
  );
};