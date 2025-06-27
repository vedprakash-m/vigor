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

// Type definitions for the new features
interface AzureAnalytics {
  alerts: Array<{
    alert_id: string;
    alert_level: string;
    message: string;
  }>;
  cost_breakdown: Array<{
    service_name: string;
    cost: number;
    percentage: number;
  }>;
}

interface Recommendations {
  recommendations: Array<{
    title: string;
    description: string;
    potential_savings?: number;
    impact?: string;
    effort?: string;
  }>;
  generated_at: string;
}

interface RealTimeData {
  global_usage: number;
  global_limit: number;
  usage_percentage: number;
  last_updated: string;
  data_source: string;
  azure_error?: string;
}

const AdminPage: React.FC = () => {
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('providers');
  const [pricing, setPricing] = useState<Record<string, number> | null>(null);
  const [azureAnalytics, setAzureAnalytics] = useState<AzureAnalytics | null>(null);
  const [realTimeAnalytics, setRealTimeAnalytics] = useState<RealTimeData | null>(null);
  const [syncStatus, setSyncStatus] = useState<string>('');
  const [recommendations, setRecommendations] = useState<Recommendations | null>(null);

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
    { id: 'analytics', label: 'Usage Analytics', description: 'Monitor AI usage and costs' },
    { id: 'azure-cost', label: 'Azure Cost Management', description: 'Real-time Azure cost analytics and controls' },
    { id: 'optimization', label: 'Cost Optimization', description: 'AI-powered cost optimization recommendations' }
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

        {activeTab === 'azure-cost' && (
          <VStack gap={6}>
            {/* Real-time Azure Cost Dashboard */}
            <Box width="100%" border="1px" borderColor="gray.200" borderRadius="md" p={6} bg="white">
              <HStack justifyContent="space-between" mb={4}>
                <Heading size="md">Azure Cost Management</Heading>
                <HStack gap={2}>
                  <Button
                    size="sm"
                    colorScheme="blue"
                    onClick={async () => {
                      try {
                        setSyncStatus('Syncing...');
                        const result = await adminService.syncAzureBudget();
                        setSyncStatus(`Sync completed: ${result.status}`);

                        // Refresh analytics after sync
                        const analytics = await adminService.getRealTimeAnalytics();
                        setRealTimeAnalytics(analytics);
                      } catch (error) {
                        setSyncStatus(`Sync failed: ${error}`);
                      }
                    }}
                  >
                    Sync Azure Budget
                  </Button>
                  <Button
                    size="sm"
                    colorScheme="green"
                    onClick={async () => {
                      try {
                        const analytics = await adminService.getAzureCostAnalytics();
                        setAzureAnalytics(analytics);
                      } catch (error) {
                        console.error('Failed to fetch Azure analytics:', error);
                      }
                    }}
                  >
                    Refresh Data
                  </Button>
                </HStack>
              </HStack>

              {syncStatus && (
                <Box mb={4} p={3} bg="blue.50" borderRadius="md">
                  <Text color="blue.700">{syncStatus}</Text>
                </Box>
              )}

              <SimpleGrid columns={{ base: 1, md: 3 }} gap={6} mb={6}>
                <Box textAlign="center" p={4} bg="green.50" borderRadius="md">
                  <Text fontSize="2xl" fontWeight="bold" color="green.600">
                    ${realTimeAnalytics?.global_usage?.toFixed(2) || '0.00'}
                  </Text>
                  <Text color="gray.600">Current Usage</Text>
                  <Text fontSize="sm" color="gray.500">
                    {realTimeAnalytics?.data_source === 'azure_real_time' ? 'Azure Live Data' : 'Local Cache'}
                  </Text>
                </Box>
                <Box textAlign="center" p={4} bg="blue.50" borderRadius="md">
                  <Text fontSize="2xl" fontWeight="bold" color="blue.600">
                    ${realTimeAnalytics?.global_limit?.toFixed(2) || '0.00'}
                  </Text>
                  <Text color="gray.600">Budget Limit</Text>
                </Box>
                <Box textAlign="center" p={4} bg="purple.50" borderRadius="md">
                  <Text fontSize="2xl" fontWeight="bold" color="purple.600">
                    {realTimeAnalytics?.usage_percentage?.toFixed(1) || '0.0'}%
                  </Text>
                  <Text color="gray.600">Usage Percentage</Text>
                </Box>
              </SimpleGrid>

              {azureAnalytics && azureAnalytics.alerts && azureAnalytics.alerts.length > 0 && (
                <Box mb={4} p={4} bg="orange.50" borderColor="orange.200" borderWidth="1px" borderRadius="md">
                  <Heading size="sm" mb={2} color="orange.700">Active Budget Alerts</Heading>
                  <VStack align="start" gap={2}>
                    {azureAnalytics.alerts.map((alert, index: number) => (
                      <HStack key={index} justify="space-between" width="100%">
                        <Text color="orange.700">{alert.message}</Text>
                        <Text fontSize="sm" color="orange.600">{alert.alert_level}</Text>
                      </HStack>
                    ))}
                  </VStack>
                </Box>
              )}

              <Box p={4} bg="gray.50" borderRadius="md">
                <Text fontSize="sm" color="gray.600" mb={2}>
                  Last Updated: {realTimeAnalytics?.last_updated ? new Date(realTimeAnalytics.last_updated).toLocaleString() : 'Never'}
                </Text>
                <Text fontSize="sm" color="gray.600">
                  Data Source: {realTimeAnalytics?.data_source || 'Unknown'}
                </Text>
                {realTimeAnalytics?.azure_error && (
                  <Text fontSize="sm" color="red.600" mt={1}>
                    Azure Error: {realTimeAnalytics.azure_error}
                  </Text>
                )}
              </Box>
            </Box>

            {/* Cost Breakdown Chart */}
            {azureAnalytics && azureAnalytics.cost_breakdown && (
              <Box width="100%" border="1px" borderColor="gray.200" borderRadius="md" p={6} bg="white">
                <Heading size="md" mb={4}>Cost Breakdown by Service</Heading>
                <VStack align="start" gap={3}>
                  {azureAnalytics.cost_breakdown.map((item, index: number) => (
                    <Box key={index} width="100%">
                      <HStack justify="space-between" mb={1}>
                        <Text fontWeight="medium">{item.service_name}</Text>
                        <Text fontWeight="bold">${item.cost?.toFixed(2)}</Text>
                      </HStack>
                      <Box width="100%" bg="gray.200" height="4px" borderRadius="2px">
                        <Box
                          width={`${item.percentage || 0}%`}
                          bg="blue.500"
                          height="100%"
                          borderRadius="2px"
                        />
                      </Box>
                      <Text fontSize="sm" color="gray.600">{item.percentage?.toFixed(1)}%</Text>
                    </Box>
                  ))}
                </VStack>
              </Box>
            )}
          </VStack>
        )}

        {activeTab === 'optimization' && (
          <VStack gap={6}>
            <Box width="100%" border="1px" borderColor="gray.200" borderRadius="md" p={6} bg="white">
              <HStack justifyContent="space-between" mb={4}>
                <Heading size="md">Cost Optimization Recommendations</Heading>
                <Button
                  colorScheme="purple"
                  onClick={async () => {
                    try {
                      const recs = await adminService.getCostOptimizationRecommendations();
                      setRecommendations(recs);
                    } catch (error) {
                      console.error('Failed to fetch recommendations:', error);
                    }
                  }}
                >
                  Generate Recommendations
                </Button>
              </HStack>

              {recommendations ? (
                <VStack align="start" gap={4}>
                  {recommendations.recommendations && recommendations.recommendations.length > 0 ? (
                    recommendations.recommendations.map((rec, index: number) => (
                      <Box key={index} p={4} bg="purple.50" borderRadius="md" width="100%">
                        <HStack justify="space-between" mb={2}>
                          <Text fontWeight="bold" color="purple.700">{rec.title}</Text>
                          <Text fontSize="sm" color="green.600" fontWeight="medium">
                            Save ${rec.potential_savings?.toFixed(2) || 'N/A'}
                          </Text>
                        </HStack>
                        <Text color="gray.700" mb={2}>{rec.description}</Text>
                        <Text fontSize="sm" color="purple.600">
                          Impact: {rec.impact || 'Medium'} | Effort: {rec.effort || 'Medium'}
                        </Text>
                      </Box>
                    ))
                  ) : (
                    <Box p={4} bg="gray.50" borderRadius="md" width="100%">
                      <Text color="gray.600">No optimization recommendations available at this time.</Text>
                      <Text fontSize="sm" color="gray.500" mt={2}>
                        This could mean your costs are already well-optimized, or there's insufficient data for analysis.
                      </Text>
                    </Box>
                  )}

                  {recommendations.generated_at && (
                    <Text fontSize="sm" color="gray.500">
                      Generated at: {new Date(recommendations.generated_at).toLocaleString()}
                    </Text>
                  )}
                </VStack>
              ) : (
                <Box p={8} textAlign="center">
                  <Text color="gray.600" mb={4}>
                    Click "Generate Recommendations" to get AI-powered cost optimization suggestions.
                  </Text>
                  <Text fontSize="sm" color="gray.500">
                    Our AI analyzes your usage patterns, Azure costs, and industry best practices to provide actionable insights.
                  </Text>
                </Box>
              )}
            </Box>

            {/* Quick Actions */}
            <Box width="100%" border="1px" borderColor="gray.200" borderRadius="md" p={6} bg="white">
              <Heading size="md" mb={4}>Quick Optimization Actions</Heading>
              <SimpleGrid columns={{ base: 1, md: 2 }} gap={4}>
                <Button
                  colorScheme="green"
                  variant="outline"
                  onClick={async () => {
                    try {
                      await adminService.createBudgetAlert('Vigor-Monthly', 80, ['admin@vigor.com']);
                      alert('Budget alert created successfully');
                    } catch (error) {
                      alert(`Failed to create alert: ${error}`);
                    }
                  }}
                >
                  Set 80% Budget Alert
                </Button>
                <Button
                  colorScheme="blue"
                  variant="outline"
                  onClick={async () => {
                    const result = await adminService.syncAzureBudget();
                    alert(`Sync result: ${result.status}`);
                  }}
                >
                  Force Budget Sync
                </Button>
                <Button
                  colorScheme="orange"
                  variant="outline"
                  onClick={() => {
                    window.open('https://portal.azure.com/#view/Microsoft_Azure_CostManagement', '_blank');
                  }}
                >
                  Open Azure Portal
                </Button>
                <Button
                  colorScheme="purple"
                  variant="outline"
                  onClick={async () => {
                    const analytics = await adminService.getRealTimeAnalytics();
                    console.log('Current Analytics:', analytics);
                    alert('Analytics logged to console');
                  }}
                >
                  Export Analytics
                </Button>
              </SimpleGrid>
            </Box>
          </VStack>
        )}
      </Box>
    </Box>
  );
};

export default AdminPage;
