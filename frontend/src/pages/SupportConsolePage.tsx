import { Box, Button, Heading, HStack, Input, Text, Textarea, VStack } from '@chakra-ui/react'
import { useState } from 'react'
import { QuickReplies } from '../components/QuickReplies'
import { supportService } from '../services/supportService'

interface UserInfo {
  id: string
  username: string
  email: string
  user_tier: string
}

interface Exercise {
  name: string
  sets: number
  reps: number
  weight?: number
}

interface WorkoutLog {
  id: string
  completed_at: string
  duration_minutes: number
  exercises: Exercise[]
}

export const SupportConsolePage = () => {
  const [email, setEmail] = useState('')
  const [user, setUser] = useState<UserInfo | null>(null)
  const [logs, setLogs] = useState<WorkoutLog[]>([])
  const [err, setErr] = useState('')
  const [replyText, setReplyText] = useState('')

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

  const handleQuickReply = (content: string) => {
    setReplyText(content)
  }

  const sendReply = () => {
    // In a real implementation, this would send the reply to the user
    console.log('Sending reply to user:', user?.email, 'Content:', replyText)
    alert(`Reply sent to ${user?.email}: ${replyText}`)
    setReplyText('')
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
          <HStack gap={4} w="full">
            <Button size="sm" onClick={()=>supportService.exportLogsCsv(user.id)} colorScheme="blue">
              Export CSV
            </Button>
          </HStack>
        )}

        {logs.length > 0 && (
          <Box w="full" mt={4}>
            <Text fontWeight="bold" mb={2}>User Workout Logs</Text>
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

        {user && (
          <Box w="full" mt={6} p={4} borderWidth={1} borderRadius="md">
            <Text fontWeight="bold" mb={3}>Send Reply to User</Text>
            <QuickReplies onSelectReply={handleQuickReply} />
            <VStack align="start" mt={4} w="full">
              <Textarea
                placeholder="Type your reply or select a template above..."
                value={replyText}
                onChange={(e) => setReplyText(e.target.value)}
                minH="100px"
              />
              <HStack>
                <Button colorScheme="blue" onClick={sendReply} disabled={!replyText.trim()}>
                  Send Reply
                </Button>
                <Button variant="outline" onClick={() => setReplyText('')}>
                  Clear
                </Button>
              </HStack>
            </VStack>
          </Box>
        )}
      </VStack>
    </Box>
  )
}
