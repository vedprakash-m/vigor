import {
    Badge,
    Box,
    Button,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useVedAuth } from '../contexts/useVedAuth'

interface StatCardProps {
  title: string
  value: string | number
  description?: string
  status?: 'success' | 'warning' | 'error'
}

const StatCard = ({ title, value, description, status = 'success' }: StatCardProps) => {
  const statusColors = {
    success: 'green',
    warning: 'yellow',
    error: 'red',
  }

  return (
    <Card.Root p={6}>
      <Card.Body>
        <VStack align="start" gap={2}>
          <Text fontSize="sm" color="gray.500">{title}</Text>
          <HStack>
            <Heading size="lg">{value}</Heading>
            {status && <Badge colorPalette={statusColors[status]}>{status}</Badge>}
          </HStack>
          {description && <Text fontSize="xs" color="gray.400">{description}</Text>}
        </VStack>
      </Card.Body>
    </Card.Root>
  )
}

export const AdminPage = () => {
  const { user } = useVedAuth()

  return (
    <Box p={6}>
      <VStack align="stretch" gap={6}>
        <Box>
          <Heading size="xl" mb={2}>Admin Dashboard</Heading>
          <Text color="gray.500">
            System monitoring and management for Vigor platform
          </Text>
        </Box>

        {/* System Health Overview */}
        <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(4, 1fr)' }} gap={4}>
          <GridItem>
            <StatCard
              title="API Status"
              value="Healthy"
              description="All endpoints responding"
              status="success"
            />
          </GridItem>
          <GridItem>
            <StatCard
              title="Database"
              value="Connected"
              description="Cosmos DB serverless"
              status="success"
            />
          </GridItem>
          <GridItem>
            <StatCard
              title="AI Provider"
              value="OpenAI"
              description="gpt-5-mini active"
              status="success"
            />
          </GridItem>
          <GridItem>
            <StatCard
              title="Active Users"
              value="0"
              description="Last 24 hours"
              status="success"
            />
          </GridItem>
        </Grid>

        {/* AI Cost Management */}
        <Card.Root>
          <Card.Header>
            <Heading size="md">AI Cost Management</Heading>
          </Card.Header>
          <Card.Body>
            <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={4}>
              <Box p={4} borderWidth={1} borderRadius="md">
                <Text fontSize="sm" color="gray.500">Monthly Budget</Text>
                <Heading size="lg">$100.00</Heading>
                <Text fontSize="xs" color="gray.400">Current limit</Text>
              </Box>
              <Box p={4} borderWidth={1} borderRadius="md">
                <Text fontSize="sm" color="gray.500">Current Spend</Text>
                <Heading size="lg">$0.00</Heading>
                <Text fontSize="xs" color="gray.400">This month</Text>
              </Box>
              <Box p={4} borderWidth={1} borderRadius="md">
                <Text fontSize="sm" color="gray.500">Budget Utilization</Text>
                <Heading size="lg">0%</Heading>
                <Text fontSize="xs" color="green.400">On track</Text>
              </Box>
            </Grid>
          </Card.Body>
        </Card.Root>

        {/* Quick Actions */}
        <Card.Root>
          <Card.Header>
            <Heading size="md">Quick Actions</Heading>
          </Card.Header>
          <Card.Body>
            <HStack gap={4} flexWrap="wrap">
              <Button colorPalette="blue" variant="outline">
                View LLM Health
              </Button>
              <Button colorPalette="blue" variant="outline">
                Manage Users
              </Button>
              <Button colorPalette="blue" variant="outline">
                LLM Configuration
              </Button>
              <Button colorPalette="blue" variant="outline">
                View Analytics
              </Button>
              <Button colorPalette="blue" variant="outline">
                Audit Logs
              </Button>
            </HStack>
          </Card.Body>
        </Card.Root>

        {/* System Information */}
        <Card.Root>
          <Card.Header>
            <Heading size="md">System Information</Heading>
          </Card.Header>
          <Card.Body>
            <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)' }} gap={4}>
              <Box>
                <Text fontSize="sm" color="gray.500">Environment</Text>
                <Text fontWeight="bold">Production</Text>
              </Box>
              <Box>
                <Text fontSize="sm" color="gray.500">Region</Text>
                <Text fontWeight="bold">West US 2</Text>
              </Box>
              <Box>
                <Text fontSize="sm" color="gray.500">Backend</Text>
                <Text fontWeight="bold">Azure Functions (Y1)</Text>
              </Box>
              <Box>
                <Text fontSize="sm" color="gray.500">Database</Text>
                <Text fontWeight="bold">Cosmos DB Serverless</Text>
              </Box>
              <Box>
                <Text fontSize="sm" color="gray.500">Current User</Text>
                <Text fontWeight="bold">{user?.email || 'Not logged in'}</Text>
              </Box>
              <Box>
                <Text fontSize="sm" color="gray.500">User Tier</Text>
                <Text fontWeight="bold">{user?.tier || 'N/A'}</Text>
              </Box>
            </Grid>
          </Card.Body>
        </Card.Root>
      </VStack>
    </Box>
  )
}

export default AdminPage
