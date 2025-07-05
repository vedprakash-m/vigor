import { Box, Text } from '@chakra-ui/react'

// Temporary placeholder component while fixing Chakra UI v3 compatibility
const AnalyticsDashboard = ({ gamificationStats }: any) => {
  return (
    <Box p={6}>
      <Text fontSize="xl" fontWeight="bold" mb={4}>
        Analytics Dashboard
      </Text>
      <Text color="gray.600">
        Analytics dashboard is temporarily disabled while migrating to Chakra UI v3.
        Gamification stats available: {gamificationStats ? 'Yes' : 'No'}
      </Text>
    </Box>
  )
}

export default AnalyticsDashboard
