import React, { useState } from 'react'
import {
  Box,
  Heading,
  Text,
  Input,
  Button,
  VStack,
  HStack,
  Flex,
} from '@chakra-ui/react'

interface Message {
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
}

export const CoachPage = () => {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'assistant',
      content: 'Hello! I\'m your AI fitness coach. How can I help you with your fitness journey today?',
      timestamp: new Date()
    }
  ])
  const [inputMessage, setInputMessage] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  const sendMessage = async () => {
    if (!inputMessage.trim()) return

    const userMessage: Message = {
      role: 'user',
      content: inputMessage,
      timestamp: new Date()
    }

    setMessages(prev => [...prev, userMessage])
    setInputMessage('')
    setIsLoading(true)

    try {
      // This would be replaced with actual API call to the AI service
      const response = await fetch('http://localhost:8000/ai/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
        },
        body: JSON.stringify({ message: inputMessage })
      })

      if (response.ok) {
        const data = await response.json()
        const assistantMessage: Message = {
          role: 'assistant',
          content: data.response,
          timestamp: new Date()
        }
        setMessages(prev => [...prev, assistantMessage])
      } else {
        throw new Error('Failed to get response')
      }
    } catch (error) {
      console.error('Error sending message:', error)
      const errorMessage: Message = {
        role: 'assistant',
        content: 'Sorry, I\'m having trouble responding right now. Please try again later.',
        timestamp: new Date()
      }
      setMessages(prev => [...prev, errorMessage])
    } finally {
      setIsLoading(false)
    }
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      sendMessage()
    }
  }

  return (
    <Box h="calc(100vh - 200px)" display="flex" flexDirection="column">
      <Heading mb={6}>AI Coach</Heading>
      
      {/* Chat Messages */}
      <Box
        flex="1"
        bg="white"
        border="1px"
        borderColor="gray.200"
        rounded="lg"
        p={4}
        overflowY="auto"
        mb={4}
      >
        <VStack gap={4} align="stretch">
          {messages.map((message, index) => (
            <Flex
              key={index}
              justify={message.role === 'user' ? 'flex-end' : 'flex-start'}
            >
              <Box
                maxW="70%"
                bg={message.role === 'user' ? 'blue.500' : 'gray.100'}
                color={message.role === 'user' ? 'white' : 'black'}
                p={3}
                rounded="lg"
              >
                <Text>{message.content}</Text>
                <Text fontSize="xs" opacity={0.7} mt={1}>
                  {message.timestamp.toLocaleTimeString()}
                </Text>
              </Box>
            </Flex>
          ))}
          {isLoading && (
            <Flex justify="flex-start">
              <Box bg="gray.100" p={3} rounded="lg">
                <Text>AI is typing...</Text>
              </Box>
            </Flex>
          )}
        </VStack>
      </Box>

      {/* Input Area */}
      <HStack>
        <Input
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Ask your AI coach anything about fitness..."
          disabled={isLoading}
        />
        <Button
          onClick={sendMessage}
          bg="blue.500"
          color="white"
          disabled={isLoading || !inputMessage.trim()}
          _hover={{ bg: 'blue.600' }}
        >
          Send
        </Button>
      </HStack>
    </Box>
  )
} 