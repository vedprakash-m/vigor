import {
    Box,
    Button,
    Heading,
    HStack,
    SimpleGrid,
    Spinner,
    Text,
    VStack
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import { adminService } from '../services/adminService';
import { authService } from '../services/authService';

const AdminPage: React.FC = () => {
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('providers');
  const [pricing, setPricing] = useState<Record<string, number> | null>(null)

  useEffect(() => {
    checkAdminAccess();
    adminService.getProviderPricing().then(setPricing).catch(() => {})
  }, []);

  const checkAdminAccess = async () => {
    try {
      const user = await authService.getCurrentUser();
      // Check if user has admin privileges (username contains 'admin')
      const hasAdminAccess = user.username.toLowerCase().includes('admin');
      setIsAdmin(hasAdminAccess);

      if (!hasAdminAccess) {
        console.warn('Admin access denied for user:', user.username);
      }
    } catch (error) {
      console.error('Error checking admin access:', error);
      setIsAdmin(false);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minH="50vh">
        <VStack gap={4}>
          <Spinner size="xl" color="purple.500" />
          <Text>Checking admin access...</Text>
        </VStack>
      </Box>
    );
  }

  if (!isAdmin) {
    return (
      <Box p={8}>
        <Box border="1px" borderColor="red.200" borderRadius="md" p={6} bg="red.50">
          <Heading size="md" color="red.500" mb={2}>Access Denied</Heading>
          <Text>You need admin privileges to access this page. Admin usernames must contain 'admin'.</Text>
        </Box>
      </Box>
    );
  }

  const tabOptions = [
    { id: 'providers', label: 'AI Providers', description: 'Manage AI provider priorities and limits' },
    { id: 'budget', label: 'Budget Settings', description: 'Set weekly and monthly budgets' },
    { id: 'analytics', label: 'Usage Analytics', description: 'Monitor AI usage and costs' }
  ];

  return (
    <Box p={8}>
      <Heading mb={6} color="purple.600">
        Admin Dashboard
      </Heading>

      {/* Tab Navigation */}
      <HStack gap={4} mb={8}>
        {tabOptions.map(tab => (
          <Button
            key={tab.id}
            variant={activeTab === tab.id ? 'solid' : 'outline'}
            colorScheme="purple"
            onClick={() => setActiveTab(tab.id)}
          >
            {tab.label}
          </Button>
        ))}
      </HStack>

      {/* Tab Content */}
      <Box>
        {activeTab === 'providers' && (
          <Box border="1px" borderColor="gray.200" borderRadius="md" p={6} bg="white">
            <Heading size="md" mb={4}>AI Provider Management</Heading>
            <Text mb={4}>Configure AI provider priorities and cost limits.</Text>
            <Text color="gray.600" mb={4}>
              AI Provider management interface will be implemented here.
              Features include:
            </Text>
            <VStack align="start" gap={2}>
              <Text>• Set provider priority order (1=highest priority)</Text>
              <Text>• Configure daily/weekly/monthly cost limits per provider</Text>
              <Text>• Enable/disable providers</Text>
              <Text>• View real-time provider status</Text>
            </VStack>
            <Button mt={4} colorScheme="blue" onClick={async ()=>{
              const res = await adminService.validateProvider('gemini-flash-2.5','demo_key')
              alert('Validation result: '+res.status)
            }}>Validate Provider Credentials</Button>
          </Box>
        )}

        {activeTab === 'budget' && (
          <Box border="1px" borderColor="gray.200" borderRadius="md" p={6} bg="white">
            <Heading size="md" mb={4}>Budget Settings</Heading>
            <Text mb={4}>Set overall budget limits and alert thresholds.</Text>
            <SimpleGrid columns={2} gap={6}>
              <Box>
                <Text fontWeight="bold" mb={2}>Weekly Budget</Text>
                <Text color="gray.600">Set maximum weekly AI spending limit {pricing && pricing['gemini-flash-2.5'] ? `(e.g., $10 / ${(10000000/(pricing['gemini-flash-2.5']*1e6)).toFixed(0)} tokens)` : ''}</Text>
              </Box>
              <Box>
                <Text fontWeight="bold" mb={2}>Monthly Budget</Text>
                <Text color="gray.600">Set maximum monthly AI spending limit {pricing && pricing['gemini-flash-2.5'] ? `(e.g., $30 / ${(30000000/(pricing['gemini-flash-2.5']*1e6)).toFixed(0)} tokens)` : ''}</Text>
              </Box>
              <Box>
                <Text fontWeight="bold" mb={2}>Alert Threshold</Text>
                <Text color="gray.600">Get alerts when reaching % of budget</Text>
              </Box>
              <Box>
                <Text fontWeight="bold" mb={2}>Auto-disable</Text>
                <Text color="gray.600">Automatically disable AI when budget exceeded</Text>
              </Box>
            </SimpleGrid>
          </Box>
        )}

        {activeTab === 'analytics' && (
          <VStack gap={6}>
            <Box width="100%" border="1px" borderColor="gray.200" borderRadius="md" p={6} bg="white">
              <Heading size="md" mb={4}>Usage Statistics</Heading>
              <SimpleGrid columns={{ base: 1, md: 3 }} gap={6}>
                <Box textAlign="center">
                  <Text fontSize="2xl" fontWeight="bold" color="green.500">$0.00</Text>
                  <Text color="gray.600">Weekly Spending</Text>
                </Box>
                <Box textAlign="center">
                  <Text fontSize="2xl" fontWeight="bold" color="blue.500">$0.00</Text>
                  <Text color="gray.600">Monthly Spending</Text>
                </Box>
                <Box textAlign="center">
                  <Text fontSize="2xl" fontWeight="bold" color="purple.500">0</Text>
                  <Text color="gray.600">Total Requests</Text>
                </Box>
              </SimpleGrid>
            </Box>

            <Box width="100%" border="1px" borderColor="gray.200" borderRadius="md" p={6} bg="white">
              <Heading size="md" mb={4}>Top Providers</Heading>
              <Text color="gray.600">No usage data available yet. AI usage will appear here once you start using the system.</Text>
            </Box>
          </VStack>
        )}
      </Box>
    </Box>
  );
};

export default AdminPage;
