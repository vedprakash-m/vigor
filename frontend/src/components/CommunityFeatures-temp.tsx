import { Box, Text } from '@chakra-ui/react'

// Temporary placeholder component while fixing Chakra UI v3 compatibility
const CommunityFeatures = () => {
  return (
    <Box p={6}>
      <Text fontSize="xl" fontWeight="bold" mb={4}>
        Community Features
      </Text>
      <Text color="gray.600">
        Community features are temporarily disabled while migrating to Chakra UI v3.
      </Text>
    </Box>
  )
}

export default CommunityFeatures
