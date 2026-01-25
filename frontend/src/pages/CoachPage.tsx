/**
 * AI Coach Page - "Coach Vigor"
 * Conversational AI fitness coach with personality
 *
 * Design Principle: AI with persona creates emotional connection
 * Features: Coach persona, quick action chips, context awareness
 */

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

// Quick action topics for easy engagement
const quickTopics = [
  { label: 'Form tips', prompt: 'Can you give me tips on proper squat form?' },
  { label: 'Motivation', prompt: 'I\'m feeling unmotivated today. Can you help?' },
  { label: 'Recovery', prompt: 'What should I do for muscle recovery after workouts?' },
  { label: 'Nutrition', prompt: 'What should I eat before and after workouts?' },
]

export const CoachPage = () => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 'welcome',
      role: 'assistant',
      content: "Hey there! 👋 I'm Coach Vigor, your personal AI fitness coach. I'm here to help you with workout advice, form tips, motivation, and anything else on your fitness journey. What would you like to work on today?",
      timestamp: new Date()
    }
  ])
  const [inputMessage, setInputMessage] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [hasLoadedHistory, setHasLoadedHistory] = useState(false)
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
          setHasLoadedHistory(true)
        }
      } catch (err) {
        console.error('Failed to load chat history:', err)
      }
    }
    loadHistory()
  }, [])

  const sendMessage = async (messageText?: string) => {
    const textToSend = messageText || inputMessage
    if (!textToSend.trim() || isLoading) return

    const userMessage: Message = {
      id: `user-${Date.now()}`,
      role: 'user',
      content: textToSend,
      timestamp: new Date()
    }

    setMessages(prev => [...prev, userMessage])
    setInputMessage('')
    setIsLoading(true)

    try {
      const response = await api.coach.chat(textToSend)
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
        content: "Sorry, I'm having trouble responding right now. Please try again in a moment!",
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

  const handleQuickTopic = (prompt: string) => {
    sendMessage(prompt)
  }

  return (
    <Box h={{ base: 'calc(100vh - 150px)', md: 'calc(100vh - 200px)' }} display="flex" flexDirection="column">
      {/* Coach Header */}
      <HStack mb={4} gap={3}>
        <Box
          w="50px"
          h="50px"
          borderRadius="full"
          bg="purple.100"
          display="flex"
          alignItems="center"
          justifyContent="center"
          fontSize="2xl"
        >
          🤖
        </Box>
        <Box>
          <Heading size={{ base: 'md', md: 'lg' }}>Coach Vigor</Heading>
          <Text fontSize="sm" color="gray.500">Your AI Fitness Coach</Text>
        </Box>
      </HStack>

      {/* Quick Topics - Show only if no history or few messages */}
      {messages.length <= 2 && !hasLoadedHistory && (
        <Box mb={4}>
          <Text fontSize="sm" color="gray.500" mb={2}>Quick topics:</Text>
          <HStack gap={2} flexWrap="wrap">
            {quickTopics.map((topic) => (
              <Button
                key={topic.label}
                size="sm"
                variant="outline"
                colorScheme="purple"
                onClick={() => handleQuickTopic(topic.prompt)}
                disabled={isLoading}
              >
                {topic.label}
              </Button>
            ))}
          </HStack>
        </Box>
      )}

      {/* Chat Messages */}
      <Box
        flex="1"
        bg="white"
        border="1px"
        borderColor="gray.200"
        rounded="lg"
        p={{ base: 2, md: 4 }}
        overflowY="auto"
        mb={4}
      >
        <VStack gap={{ base: 2, md: 4 }} align="stretch">
          {messages.map((message) => (
            <Flex
              key={message.id}
              justify={message.role === 'user' ? 'flex-end' : 'flex-start'}
            >
              {message.role === 'assistant' && (
                <Box mr={2} mt={1}>
                  <Text fontSize="lg">🤖</Text>
                </Box>
              )}
              <Box
                maxW={{ base: '85%', md: '70%' }}
                bg={message.role === 'user' ? 'blue.500' : 'purple.50'}
                color={message.role === 'user' ? 'white' : 'gray.800'}
                p={3}
                rounded="lg"
                borderBottomLeftRadius={message.role === 'assistant' ? '4px' : 'lg'}
                borderBottomRightRadius={message.role === 'user' ? '4px' : 'lg'}
              >
                <Text whiteSpace="pre-wrap" fontSize={{ base: 'sm', md: 'md' }}>{message.content}</Text>
                <Text fontSize="xs" opacity={0.7} mt={1}>
                  {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </Text>
              </Box>
            </Flex>
          ))}
          {isLoading && (
            <Flex justify="flex-start">
              <HStack bg="purple.50" p={3} rounded="lg" gap={2}>
                <Text fontSize="lg">🤖</Text>
                <Spinner size="sm" color="purple.500" />
                <Text color="purple.600">Coach Vigor is typing...</Text>
              </HStack>
            </Flex>
          )}
          <div ref={messagesEndRef} />
        </VStack>
      </Box>

      {/* Input Area */}
      <HStack gap={2}>
        <Input
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Ask Coach Vigor anything..."
          disabled={isLoading}
          size={{ base: 'md', md: 'lg' }}
          bg="white"
        />
        <Button
          onClick={() => sendMessage()}
          colorScheme="purple"
          disabled={isLoading || !inputMessage.trim()}
          size={{ base: 'md', md: 'lg' }}
          px={{ base: 4, md: 6 }}
        >
          Send
        </Button>
      </HStack>
    </Box>
  )
}
