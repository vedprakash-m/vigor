/**
 * Premium Features Component
 * Showcases and manages premium tier features
 */

import {
    Badge,
    Box,
    Button,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    List,
    Text,
    VStack,
} from '@chakra-ui/react'
import { Link as RouterLink } from 'react-router-dom'
import { useVedAuth } from '../contexts/useVedAuth'

interface PremiumFeature {
    id: string
    title: string
    description: string
    icon: string
    available: boolean
}

const premiumFeatures: PremiumFeature[] = [
    {
        id: 'unlimited-workouts',
        title: 'Unlimited AI Workouts',
        description: 'Generate as many AI-powered workout plans as you need',
        icon: '🏋️',
        available: true,
    },
    {
        id: 'advanced-analytics',
        title: 'Advanced Analytics',
        description: 'Deep insights into your fitness progress with detailed charts',
        icon: '📊',
        available: true,
    },
    {
        id: 'coach-unlimited',
        title: 'Unlimited AI Coach',
        description: 'Chat with your personal AI fitness coach anytime',
        icon: '🤖',
        available: true,
    },
    {
        id: 'nutrition',
        title: 'Nutrition Guidance',
        description: 'Personalized meal suggestions and macro tracking',
        icon: '🥗',
        available: true,
    },
    {
        id: 'custom-plans',
        title: 'Custom Workout Plans',
        description: 'Create and save your own workout templates',
        icon: '📝',
        available: true,
    },
    {
        id: 'priority-support',
        title: 'Priority Support',
        description: '24/7 priority customer support',
        icon: '⚡',
        available: true,
    },
]

const PremiumFeatures = () => {
    const { user } = useVedAuth()
    const isPremium = user?.tier === 'premium' || user?.tier === 'enterprise'

    if (isPremium) {
        return (
            <Box p={6}>
                <VStack align="start" mb={8} gap={2}>
                    <HStack>
                        <Heading size="xl">Premium Features</Heading>
                        <Badge colorPalette="blue" size="lg" p={2}>
                            {user?.tier?.toUpperCase()}
                        </Badge>
                    </HStack>
                    <Text color="gray.600">
                        Enjoy all the premium features included in your subscription
                    </Text>
                </VStack>

                <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(3, 1fr)' }} gap={6}>
                    {premiumFeatures.map((feature) => (
                        <GridItem key={feature.id}>
                            <Card.Root bg="white" shadow="sm" borderRadius="lg" h="full">
                                <Card.Body p={6}>
                                    <VStack align="start" gap={3}>
                                        <Text fontSize="3xl">{feature.icon}</Text>
                                        <Heading size="md">{feature.title}</Heading>
                                        <Text color="gray.600">{feature.description}</Text>
                                        <Badge colorPalette="green">Active</Badge>
                                    </VStack>
                                </Card.Body>
                            </Card.Root>
                        </GridItem>
                    ))}
                </Grid>

                {/* Usage Stats */}
                <Card.Root bg="white" shadow="sm" borderRadius="lg" mt={8}>
                    <Card.Body p={6}>
                        <Heading size="md" mb={6}>
                            Your Premium Usage
                        </Heading>
                        <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={4}>
                            <Box p={4} bg="blue.50" borderRadius="md">
                                <Text fontSize="sm" color="blue.700">
                                    AI Workouts Generated
                                </Text>
                                <Text fontSize="2xl" fontWeight="bold" color="blue.600">
                                    42
                                </Text>
                                <Text fontSize="xs" color="blue.500">
                                    This month
                                </Text>
                            </Box>
                            <Box p={4} bg="purple.50" borderRadius="md">
                                <Text fontSize="sm" color="purple.700">
                                    Coach Conversations
                                </Text>
                                <Text fontSize="2xl" fontWeight="bold" color="purple.600">
                                    156
                                </Text>
                                <Text fontSize="xs" color="purple.500">
                                    This month
                                </Text>
                            </Box>
                            <Box p={4} bg="green.50" borderRadius="md">
                                <Text fontSize="sm" color="green.700">
                                    Custom Plans Created
                                </Text>
                                <Text fontSize="2xl" fontWeight="bold" color="green.600">
                                    8
                                </Text>
                                <Text fontSize="xs" color="green.500">
                                    Total saved
                                </Text>
                            </Box>
                        </Grid>
                    </Card.Body>
                </Card.Root>
            </Box>
        )
    }

    // Non-premium view - upgrade prompt
    return (
        <Box p={6}>
            <VStack align="center" textAlign="center" py={12} gap={6}>
                <Text fontSize="5xl">⭐</Text>
                <Heading size="xl">Unlock Premium Features</Heading>
                <Text color="gray.600" maxW="600px">
                    Upgrade to Premium to unlock unlimited AI workouts, advanced analytics,
                    personalized nutrition guidance, and more.
                </Text>

                <Card.Root bg="white" shadow="lg" borderRadius="xl" maxW="500px" w="full">
                    <Card.Body p={8}>
                        <VStack gap={6}>
                            <HStack>
                                <Text fontSize="4xl" fontWeight="bold">
                                    $9.99
                                </Text>
                                <Text color="gray.500">/month</Text>
                            </HStack>

                            <List.Root gap={3} w="full">
                                {premiumFeatures.map((feature) => (
                                    <List.Item key={feature.id} display="flex" alignItems="center" gap={3}>
                                        <Text>{feature.icon}</Text>
                                        <Text>{feature.title}</Text>
                                    </List.Item>
                                ))}
                            </List.Root>

                            <RouterLink to="/app/tiers" style={{ width: '100%' }}>
                                <Button
                                    colorScheme="blue"
                                    size="lg"
                                    w="full"
                                >
                                    Upgrade Now
                                </Button>
                            </RouterLink>

                            <Text fontSize="sm" color="gray.500">
                                14-day money-back guarantee
                            </Text>
                        </VStack>
                    </Card.Body>
                </Card.Root>
            </VStack>
        </Box>
    )
}

export default PremiumFeatures
