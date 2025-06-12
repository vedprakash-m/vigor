import { Box, Button, Heading, Input, Text, VStack } from '@chakra-ui/react'
import { useState } from 'react'
import { supportService } from '../services/supportService'

interface UserInfo {
  id: string
  username: string
  email: string
  user_tier: string
}

interface WorkoutLog {
  id: string
  completed_at: string
  duration_minutes: number
  exercises: unknown[]
}

export const SupportConsolePage = () => {
  const [email, setEmail] = useState('')
  const [user, setUser] = useState<UserInfo | null>(null)
  const [logs, setLogs] = useState<WorkoutLog[]>([])
  const [err, setErr] = useState('')

  const search = async () => {
    try {
      const data = await supportService.searchUser(email)
      setUser(data)
      const userLogs = await supportService.getUserLogs(data.id)
      setLogs(userLogs)
    } catch {
      setErr('User not found')
    }
  }

  return (
    <Box p={8}>
      <Heading mb={6}>Support Console</Heading>
      <VStack align="start" gap={4}>
        <Input placeholder="Search user email" value={email} onChange={e => setEmail(e.target.value)} />
        <Button onClick={search}>Search</Button>
        {err && <Text color="red.500">{err}</Text>}

        {user && (
          <Box w="full" borderWidth={1} borderRadius="md" p={4}>
            <Text fontWeight="bold">{user.username} ({user.email})</Text>
            <Text fontSize="sm">Tier: {user.user_tier}</Text>
          </Box>
        )}

        {user && (
          <Button size="sm" onClick={()=>supportService.exportLogsCsv(user.id)} colorScheme="blue">Export CSV</Button>
        )}

        {logs.length > 0 && (
          <Box w="full" mt={4}>
            <Box display="flex" fontWeight="bold" color="gray.600" px={2} py={1}>
              <Text flex="1">Date</Text>
              <Text w="100px">Duration</Text>
              <Text w="120px">Exercises</Text>
            </Box>
            {logs.map((log) => (
              <Box key={log.id} display="flex" borderWidth={1} borderRadius="md" p={2} fontSize="sm" mb={2}>
                <Text flex="1">{new Date(log.completed_at).toLocaleDateString()}</Text>
                <Text w="100px">{log.duration_minutes}m</Text>
                <Text w="120px">{log.exercises.length}</Text>
              </Box>
            ))}
          </Box>
        )}
      </VStack>
    </Box>
  )
}
