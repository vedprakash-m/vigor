import { Badge, Box, HStack, Spinner, Text, VStack } from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';

interface ProviderInfo {
  configured: boolean;
  model: string;
}

interface LLMStatus {
  configured_provider: string;
  active_provider: string;
  is_available: boolean;
  provider_info: {
    openai: ProviderInfo;
    gemini: ProviderInfo;
    perplexity: ProviderInfo;
  };
}

const LLMStatus: React.FC = () => {
  const [status, setStatus] = useState<LLMStatus | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const response = await fetch('http://localhost:8001/ai/provider-status');
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        setStatus(data);
      } catch (error) {
        console.error('Failed to fetch LLM status:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchStatus();
  }, []);

  if (loading) {
    return (
      <Box p={3} borderWidth={1} borderRadius="md" bg="gray.50">
        <HStack>
          <Spinner size="sm" />
          <Text fontSize="sm">Loading AI status...</Text>
        </HStack>
      </Box>
    );
  }

  if (!status) {
    return (
      <Box p={3} borderWidth={1} borderRadius="md" bg="red.50">
        <Text fontSize="sm" color="red.600">Failed to load AI status</Text>
      </Box>
    );
  }

  const getProviderColor = (providerName: string) => {
    if (!status || !status.provider_info) return 'gray';
    if (status.active_provider?.toLowerCase().includes(providerName.toLowerCase())) {
      return 'green';
    }
    return status.provider_info[providerName as keyof typeof status.provider_info]?.configured ? 'blue' : 'gray';
  };

  const getStatusText = (providerName: string) => {
    if (!status || !status.provider_info) return 'Not Configured';
    if (status.active_provider?.toLowerCase().includes(providerName.toLowerCase())) {
      return 'Active';
    }
    return status.provider_info[providerName as keyof typeof status.provider_info]?.configured ? 'Configured' : 'Not Configured';
  };

  return (
    <Box p={3} borderWidth={1} borderRadius="md" bg="gray.50">
      <VStack align="start">
        <HStack>
          <Text fontSize="sm" fontWeight="bold">AI Provider:</Text>
          <Badge colorScheme={status.is_available ? 'green' : 'red'}>
            {status.active_provider}
          </Badge>
        </HStack>

        <VStack align="start">
          <Text fontSize="xs" color="gray.600">Available Providers:</Text>

          <HStack flexWrap="wrap">
            <HStack>
              <Text fontSize="xs">OpenAI:</Text>
              <Badge size="sm" colorScheme={getProviderColor('openai')}>
                {getStatusText('openai')}
              </Badge>
            </HStack>

            <HStack>
              <Text fontSize="xs">Gemini:</Text>
              <Badge size="sm" colorScheme={getProviderColor('gemini')}>
                {getStatusText('gemini')}
              </Badge>
            </HStack>

            <HStack>
              <Text fontSize="xs">Perplexity:</Text>
              <Badge size="sm" colorScheme={getProviderColor('perplexity')}>
                {getStatusText('perplexity')}
              </Badge>
            </HStack>
          </HStack>
        </VStack>

        {status.active_provider === 'FallbackProvider' && (
          <Text fontSize="xs" color="orange.600">
            Using fallback responses. Configure an API key for personalized AI features.
          </Text>
        )}
      </VStack>
    </Box>
  );
};

export default LLMStatus;
