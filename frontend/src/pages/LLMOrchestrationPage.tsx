import {
    Box,
    Button,
    Flex,
    Heading,
    HStack,
    Spacer,
    Text,
    Textarea,
    VStack
} from '@chakra-ui/react';
import React, { useState } from 'react';

interface LLMResponse {
  content: string;
  model_used: string;
  provider: string;
  request_id: string;
  tokens_used: number;
  cost_estimate: number;
  latency_ms: number;
  cached: boolean;
}

export const LLMOrchestrationPage: React.FC = () => {
  const [prompt, setPrompt] = useState('');
  const [response, setResponse] = useState<LLMResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const sendLLMRequest = async () => {
    if (!prompt.trim()) return;

    setLoading(true);
    setError(null);

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
        const data = await response.json();
        setResponse(data);
      } else {
        setError('Failed to get LLM response');
      }
    } catch (error) {
      console.error('LLM request error:', error);
      setError('Network error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box p={6} maxW="1200px" mx="auto">
      <Flex align="center" mb={6}>
        <Heading size="lg">🤖 Enterprise LLM Orchestration</Heading>
        <Spacer />
        <Text fontSize="sm" color="blue.500">
          Intelligent AI Routing
        </Text>
      </Flex>

      {error && (
        <Box p={4} bg="red.100" borderColor="red.300" borderWidth={1} borderRadius="md" mb={4}>
          <Text color="red.700">{error}</Text>
        </Box>
      )}

      <VStack gap={6} align="stretch">
        <Box p={6} borderWidth={1} borderRadius="lg" bg="white" boxShadow="sm">
          <Heading size="md" mb={4}>🧠 Enterprise AI Chat</Heading>
          <Text color="gray.600" fontSize="sm" mb={4}>
            Powered by intelligent routing, budget management, and enterprise security
          </Text>

          <VStack gap={4} align="stretch">
            <Box>
              <Text fontWeight="bold" mb={2}>Your Prompt</Text>
              <Textarea
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                placeholder="Ask me anything about fitness, workouts, nutrition..."
                rows={4}
              />
            </Box>

            <Button
              onClick={sendLLMRequest}
              loading={loading}
              disabled={loading}
              colorScheme="blue"
              size="lg"
              width="full"
            >
              {loading ? 'Processing...' : '🚀 Send Request'}
            </Button>

            {response && (
              <Box p={4} borderWidth={1} borderRadius="md" bg="gray.50">
                <Flex align="center" justify="space-between" mb={3}>
                  <Heading size="sm">Response</Heading>
                  <HStack gap={2}>
                    <Text fontSize="xs" bg="blue.100" px={2} py={1} borderRadius="sm">
                      {response.provider}
                    </Text>
                    <Text fontSize="xs" bg="green.100" px={2} py={1} borderRadius="sm">
                      {response.model_used}
                    </Text>
                    {response.cached && (
                      <Text fontSize="xs" bg="purple.100" px={2} py={1} borderRadius="sm">
                        🚀 Cached
                      </Text>
                    )}
                  </HStack>
                </Flex>

                <Text mb={4} whiteSpace="pre-wrap">{response.content}</Text>

                <VStack gap={2} align="stretch" fontSize="sm" color="gray.600">
                  <HStack justify="space-between">
                    <Text fontWeight="bold">Tokens:</Text>
                    <Text>{response.tokens_used}</Text>
                  </HStack>
                  <HStack justify="space-between">
                    <Text fontWeight="bold">Cost:</Text>
                    <Text>${response.cost_estimate.toFixed(6)}</Text>
                  </HStack>
                  <HStack justify="space-between">
                    <Text fontWeight="bold">Latency:</Text>
                    <Text>{response.latency_ms}ms</Text>
                  </HStack>
                  <HStack justify="space-between">
                    <Text fontWeight="bold">Request ID:</Text>
                    <Text>{response.request_id.slice(0, 8)}...</Text>
                  </HStack>
                </VStack>
              </Box>
            )}
          </VStack>
        </Box>

        <Box p={6} borderWidth={1} borderRadius="lg" bg="white" boxShadow="sm">
          <Heading size="md" mb={4}>🎯 Enterprise Features</Heading>
          <VStack gap={3} align="stretch">
            <HStack>
              <Text fontSize="lg">🔐</Text>
              <Text><strong>Secure Key Vault Integration:</strong> API keys stored securely in Azure/AWS/HashiCorp vaults</Text>
            </HStack>
            <HStack>
              <Text fontSize="lg">💰</Text>
              <Text><strong>Intelligent Budget Management:</strong> Real-time cost tracking and budget enforcement</Text>
            </HStack>
            <HStack>
              <Text fontSize="lg">⚡</Text>
              <Text><strong>High-Performance Caching:</strong> Response caching for cost optimization</Text>
            </HStack>
            <HStack>
              <Text fontSize="lg">🛡️</Text>
              <Text><strong>Circuit Breaker Protection:</strong> Automatic failover and resilience</Text>
            </HStack>
            <HStack>
              <Text fontSize="lg">🎯</Text>
              <Text><strong>Intelligent Routing:</strong> Context-aware model selection and A/B testing</Text>
            </HStack>
            <HStack>
              <Text fontSize="lg">📊</Text>
              <Text><strong>Comprehensive Analytics:</strong> Usage tracking and performance monitoring</Text>
            </HStack>
          </VStack>
        </Box>
      </VStack>
    </Box>
  );
};

export default LLMOrchestrationPage;