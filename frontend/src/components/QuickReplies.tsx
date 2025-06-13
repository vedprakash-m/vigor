import { Box, Button, Text } from '@chakra-ui/react'
import { useState } from 'react'

interface QuickReply {
  id: string
  title: string
  content: string
  category: 'general' | 'technical' | 'billing' | 'feature'
}

const quickReplyTemplates: QuickReply[] = [
  {
    id: 'welcome',
    title: 'Welcome Message',
    content: 'Welcome to Vigor! I\'m here to help you with your fitness journey. How can I assist you today?',
    category: 'general'
  },
  {
    id: 'password_reset',
    title: 'Password Reset Help',
    content: 'I can help you reset your password. Please check your email for the reset link, or let me know if you need assistance with the process.',
    category: 'technical'
  },
  {
    id: 'tier_upgrade',
    title: 'Tier Upgrade Information',
    content: 'To upgrade your tier, please visit your profile settings or contact our billing team. Premium features include unlimited AI coaching and advanced analytics.',
    category: 'billing'
  },
  {
    id: 'feature_request',
    title: 'Feature Request Acknowledgment',
    content: 'Thank you for your feature request! We\'ve logged it and will consider it for future updates. You\'ll be notified if it gets implemented.',
    category: 'feature'
  },
  {
    id: 'technical_issue',
    title: 'Technical Issue Support',
    content: 'I understand you\'re experiencing a technical issue. Let me help you troubleshoot. Can you provide more details about what you\'re seeing?',
    category: 'technical'
  },
  {
    id: 'workout_help',
    title: 'Workout Planning Help',
    content: 'I can help you with workout planning! Our AI coach can generate personalized plans based on your goals, equipment, and fitness level.',
    category: 'general'
  }
]

interface QuickRepliesProps {
  onSelectReply: (content: string) => void
  disabled?: boolean
}

export const QuickReplies: React.FC<QuickRepliesProps> = ({ onSelectReply, disabled = false }) => {
  const [selectedCategory, setSelectedCategory] = useState<string>('all')

  const filteredReplies = selectedCategory === 'all'
    ? quickReplyTemplates
    : quickReplyTemplates.filter(reply => reply.category === selectedCategory)

  const categories = [
    { id: 'all', label: 'All Templates' },
    { id: 'general', label: 'General' },
    { id: 'technical', label: 'Technical' },
    { id: 'billing', label: 'Billing' },
    { id: 'feature', label: 'Feature Requests' }
  ]

  return (
    <Box>
      <Text fontSize="sm" fontWeight="medium" mb={2}>Quick Reply Templates</Text>

      {/* Category Filter */}
      <Box mb={3}>
        <select
          value={selectedCategory}
          onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setSelectedCategory(e.target.value)}
          disabled={disabled}
          style={{
            padding: '8px 12px',
            border: '1px solid #e2e8f0',
            borderRadius: '6px',
            fontSize: '14px',
            maxWidth: '200px'
          }}
        >
          {categories.map(category => (
            <option key={category.id} value={category.id}>
              {category.label}
            </option>
          ))}
        </select>
      </Box>

      {/* Quick Reply Buttons */}
      <Box display="flex" flexWrap="wrap" gap={2}>
        {filteredReplies.map(reply => (
          <Button
            key={reply.id}
            size="sm"
            variant="outline"
            onClick={() => onSelectReply(reply.content)}
            disabled={disabled}
            maxW="200px"
            textAlign="left"
            whiteSpace="normal"
            height="auto"
            py={2}
          >
            <Text fontSize="xs" fontWeight="medium">{reply.title}</Text>
          </Button>
        ))}
      </Box>
    </Box>
  )
}
