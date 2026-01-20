import { Badge, Box, HStack, Spinner, Text, VStack } from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import api from '../services/api';

interface AIStatus {
  provider: string;
  model: string;
  is_available: boolean;
  version: string;
}

/**
 * AI Status Component
 * Shows the current AI provider status (OpenAI gpt-5-mini)
 */
const LLMStatus: React.FC = () => {
  const [status, setStatus] = useState<AIStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const response = await api.health.check();
        setStatus({
          provider: 'OpenAI',
          model: 'gpt-5-mini',
          is_available: response.data.status === 'healthy',
          version: response.data.version || '2.0.0',
        });
        setError(null);
      } catch (err) {
        console.error('Failed to fetch AI status:', err);
        setError('Unable to connect to AI service');
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

  if (error || !status) {
    return (
      <Box p={3} borderWidth={1} borderRadius="md" bg="red.50">
        <Text fontSize="sm" color="red.600">{error || 'AI service unavailable'}</Text>
      </Box>
    );
  }

  return (
    <Box p={3} borderWidth={1} borderRadius="md" bg="gray.50">
      <VStack align="start" gap={2}>
        <HStack>
          <Text fontSize="sm" fontWeight="bold">AI Provider:</Text>
          <Badge colorScheme={status.is_available ? 'green' : 'red'}>
            {status.provider}
          </Badge>
        </HStack>
        <HStack>
          <Text fontSize="xs" color="gray.600">Model:</Text>
          <Text fontSize="xs">{status.model}</Text>
        </HStack>
        <HStack>
          <Text fontSize="xs" color="gray.600">Status:</Text>
          <Badge colorScheme={status.is_available ? 'green' : 'red'}>
            {status.is_available ? 'Online' : 'Offline'}
          </Badge>
        </HStack>
      </VStack>
    </Box>
  );
};

export default LLMStatus;
