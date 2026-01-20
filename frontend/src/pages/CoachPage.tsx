import {
    Box,
    Button,
    Flex,
    Heading,
    HStack,
    Input,
    Spinner,
    Text,
    VStack,
} from '@chakra-ui/react'
import React, { useEffect, useRef, useState } from 'react'
import { api } from '../services/api'

interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
}

export const CoachPage = () => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 'welcome',
      role: 'assistant',
      content: "Hello! I'm your AI fitness coach. How can I help you with your fitness journey today?",
      timestamp: new Date()
    }
  ])
  const [inputMessage, setInputMessage] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  // Scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  // Load history on mount
  useEffect(() => {
    const loadHistory = async () => {
      try {
        const response = await api.coach.history(50)
        if (response.data && response.data.length > 0) {
          setMessages(response.data.map(msg => ({
            id: msg.id,
            role: msg.role,
            content: msg.content,
            timestamp: new Date(msg.timestamp)
          })))
        }
      } catch (err) {
        console.error('Failed to load chat history:', err)
      }
    }
    loadHistory()
  }, [])

  const sendMessage = async () => {
    if (!inputMessage.trim() || isLoading) return

    const userMessage: Message = {
      id: `user-${Date.now()}`,
      role: 'user',
      content: inputMessage,
      timestamp: new Date()
    }

    setMessages(prev => [...prev, userMessage])
    const messageToSend = inputMessage
    setInputMessage('')
    setIsLoading(true)

    try {
      const response = await api.coach.chat(messageToSend)
      const assistantMessage: Message = {
        id: `assistant-${Date.now()}`,
        role: 'assistant',
        content: response.data.response,
        timestamp: new Date()
      }
      setMessages(prev => [...prev, assistantMessage])
    } catch (error) {
      console.error('Error sending message:', error)
      const errorMessage: Message = {
        id: `error-${Date.now()}`,
        role: 'assistant',
        content: "Sorry, I'm having trouble responding right now. Please try again later.",
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
          {messages.map((message) => (
            <Flex
              key={message.id}
              justify={message.role === 'user' ? 'flex-end' : 'flex-start'}
            >
              <Box
                maxW="70%"
                bg={message.role === 'user' ? 'blue.500' : 'gray.100'}
                color={message.role === 'user' ? 'white' : 'black'}
                p={3}
                rounded="lg"
              >
                <Text whiteSpace="pre-wrap">{message.content}</Text>
                <Text fontSize="xs" opacity={0.7} mt={1}>
                  {message.timestamp.toLocaleTimeString()}
                </Text>
              </Box>
            </Flex>
          ))}
          {isLoading && (
            <Flex justify="flex-start">
              <Box bg="gray.100" p={3} rounded="lg">
                <HStack>
                  <Spinner size="sm" />
                  <Text>Coach is typing...</Text>
                </HStack>
              </Box>
            </Flex>
          )}
          <div ref={messagesEndRef} />
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
          colorScheme="blue"
          disabled={isLoading || !inputMessage.trim()}
        >
          Send
        </Button>
      </HStack>
    </Box>
  )
}
