import { Box, Button, Heading, Text, VStack, useToast } from '@chakra-ui/react'

export const ProfilePage = () => {
  const toast = useToast()

  const handleDelete = () => {
    toast({ title: 'Account scheduled for deletion', description: 'You have 14 days to undo via link in email.', status: 'info' })
    // TODO call API to flag deletion
  }

  return (
    <Box>
      <Heading mb={6}>Profile</Heading>
      <Text>Your profile settings and preferences will appear here.</Text>

      <VStack mt={8} align="start">
        <Heading size="sm" color="red.500">Danger Zone</Heading>
        <Text fontSize="sm">Deleting your account will permanently remove your data after a 14-day grace period.</Text>
        <Button colorScheme="red" onClick={handleDelete}>Delete Account</Button>
      </VStack>
    </Box>
  )
}
