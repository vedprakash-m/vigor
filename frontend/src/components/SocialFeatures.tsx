/**
 * Social Features Component
 * Social sharing and friend connections
 */

import {
    Avatar,
    Badge,
    Box,
    Button,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    Input,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useState } from 'react'
import { useAuth } from '../contexts/useAuth'

interface Friend {
    id: string
    name: string
    avatar?: string
    status: 'online' | 'offline' | 'workout'
    lastActive: string
    workoutsThisWeek: number
}

interface Activity {
    id: string
    user: { name: string; avatar?: string }
    action: string
    timestamp: string
}

const mockFriends: Friend[] = [
    {
        id: '1',
        name: 'Alex Johnson',
        status: 'online',
        lastActive: 'Now',
        workoutsThisWeek: 5,
    },
    {
        id: '2',
        name: 'Sam Williams',
        status: 'workout',
        lastActive: 'Working out',
        workoutsThisWeek: 4,
    },
    {
        id: '3',
        name: 'Jordan Lee',
        status: 'offline',
        lastActive: '2 hours ago',
        workoutsThisWeek: 3,
    },
]

const mockActivities: Activity[] = [
    {
        id: '1',
        user: { name: 'Alex' },
        action: 'completed a 45-min HIIT workout',
        timestamp: '10 min ago',
    },
    {
        id: '2',
        user: { name: 'Sam' },
        action: 'started a new workout streak',
        timestamp: '1 hour ago',
    },
    {
        id: '3',
        user: { name: 'Jordan' },
        action: 'reached a new personal record',
        timestamp: '3 hours ago',
    },
]

const SocialFeatures = () => {
    useAuth() // For future user-specific features
    const [friends] = useState<Friend[]>(mockFriends)
    const [activities] = useState<Activity[]>(mockActivities)
    const [searchQuery, setSearchQuery] = useState('')

    const getStatusColor = (status: Friend['status']) => {
        switch (status) {
            case 'online':
                return 'green.400'
            case 'workout':
                return 'blue.400'
            case 'offline':
                return 'gray.400'
        }
    }

    const getStatusText = (status: Friend['status']) => {
        switch (status) {
            case 'online':
                return 'Online'
            case 'workout':
                return 'Working out'
            case 'offline':
                return 'Offline'
        }
    }

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">Social</Heading>
                <Text color="gray.600">
                    Connect with friends and share your fitness journey
                </Text>
            </VStack>

            <Grid templateColumns={{ base: '1fr', lg: '2fr 1fr' }} gap={6}>
                {/* Main Content */}
                <GridItem>
                    {/* Quick Share */}
                    <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={6}>
                        <Card.Body p={4}>
                            <Heading size="sm" mb={4}>
                                Share Your Progress
                            </Heading>
                            <HStack gap={2} flexWrap="wrap">
                                <Button size="sm" colorScheme="blue">
                                    Share Workout
                                </Button>
                                <Button size="sm" colorScheme="green">
                                    Share Achievement
                                </Button>
                                <Button size="sm" colorScheme="purple">
                                    Challenge Friend
                                </Button>
                            </HStack>
                        </Card.Body>
                    </Card.Root>

                    {/* Activity Feed */}
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={6}>
                            <Heading size="md" mb={6}>
                                Friend Activity
                            </Heading>
                            <VStack align="stretch" gap={4}>
                                {activities.map((activity) => (
                                    <HStack
                                        key={activity.id}
                                        p={4}
                                        bg="gray.50"
                                        borderRadius="lg"
                                        gap={4}
                                    >
                                        <Avatar.Root size="md">
                                            <Avatar.Fallback>
                                                {activity.user.name.charAt(0)}
                                            </Avatar.Fallback>
                                        </Avatar.Root>
                                        <Box flex="1">
                                            <Text>
                                                <Text as="span" fontWeight="bold">
                                                    {activity.user.name}
                                                </Text>{' '}
                                                {activity.action}
                                            </Text>
                                            <Text fontSize="sm" color="gray.500">
                                                {activity.timestamp}
                                            </Text>
                                        </Box>
                                        <Button size="sm" variant="ghost">
                                            👏
                                        </Button>
                                    </HStack>
                                ))}
                            </VStack>
                        </Card.Body>
                    </Card.Root>

                    {/* Your Stats to Share */}
                    <Card.Root bg="white" shadow="sm" borderRadius="lg" mt={6}>
                        <Card.Body p={6}>
                            <Heading size="md" mb={4}>
                                Your Shareable Stats
                            </Heading>
                            <Grid templateColumns="repeat(3, 1fr)" gap={4}>
                                <Box
                                    p={4}
                                    bg="gradient-to-br"
                                    bgGradient="linear(to-br, blue.400, blue.600)"
                                    borderRadius="lg"
                                    color="white"
                                    textAlign="center"
                                >
                                    <Text fontSize="2xl" fontWeight="bold">
                                        12
                                    </Text>
                                    <Text fontSize="sm">Workouts</Text>
                                </Box>
                                <Box
                                    p={4}
                                    bg="gradient-to-br"
                                    bgGradient="linear(to-br, green.400, green.600)"
                                    borderRadius="lg"
                                    color="white"
                                    textAlign="center"
                                >
                                    <Text fontSize="2xl" fontWeight="bold">
                                        5 🔥
                                    </Text>
                                    <Text fontSize="sm">Day Streak</Text>
                                </Box>
                                <Box
                                    p={4}
                                    bg="gradient-to-br"
                                    bgGradient="linear(to-br, purple.400, purple.600)"
                                    borderRadius="lg"
                                    color="white"
                                    textAlign="center"
                                >
                                    <Text fontSize="2xl" fontWeight="bold">
                                        #8
                                    </Text>
                                    <Text fontSize="sm">Leaderboard</Text>
                                </Box>
                            </Grid>
                        </Card.Body>
                    </Card.Root>
                </GridItem>

                {/* Sidebar - Friends */}
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={6}>
                            <Heading size="md" mb={4}>
                                Friends ({friends.length})
                            </Heading>

                            <Input
                                placeholder="Find friends..."
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                mb={4}
                            />

                            <VStack align="stretch" gap={3}>
                                {friends.map((friend) => (
                                    <HStack
                                        key={friend.id}
                                        p={3}
                                        bg="gray.50"
                                        borderRadius="lg"
                                        justify="space-between"
                                    >
                                        <HStack gap={3}>
                                            <Box position="relative">
                                                <Avatar.Root size="sm">
                                                    <Avatar.Fallback>
                                                        {friend.name.charAt(0)}
                                                    </Avatar.Fallback>
                                                </Avatar.Root>
                                                <Box
                                                    position="absolute"
                                                    bottom="0"
                                                    right="0"
                                                    w="10px"
                                                    h="10px"
                                                    borderRadius="full"
                                                    bg={getStatusColor(friend.status)}
                                                    border="2px solid white"
                                                />
                                            </Box>
                                            <VStack align="start" gap={0}>
                                                <Text fontWeight="medium" fontSize="sm">
                                                    {friend.name}
                                                </Text>
                                                <Text fontSize="xs" color="gray.500">
                                                    {getStatusText(friend.status)}
                                                </Text>
                                            </VStack>
                                        </HStack>
                                        <Badge colorPalette="blue" size="sm">
                                            {friend.workoutsThisWeek} this week
                                        </Badge>
                                    </HStack>
                                ))}
                            </VStack>

                            <Button
                                variant="outline"
                                colorScheme="blue"
                                size="sm"
                                w="full"
                                mt={4}
                            >
                                Find More Friends
                            </Button>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>
        </Box>
    )
}

export default SocialFeatures
