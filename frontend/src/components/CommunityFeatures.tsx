/**
 * Community Features Component
 * Social community features for fitness enthusiasts
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

interface CommunityPost {
    id: string
    author: {
        name: string
        avatar?: string
        tier: 'free' | 'premium' | 'enterprise'
    }
    content: string
    likes: number
    comments: number
    timestamp: string
    type: 'achievement' | 'workout' | 'tip' | 'question'
}

interface Challenge {
    id: string
    title: string
    description: string
    participants: number
    daysRemaining: number
    progress: number
}

const mockPosts: CommunityPost[] = [
    {
        id: '1',
        author: { name: 'Sarah M.', tier: 'premium' },
        content: '🎉 Just completed my 30-day workout streak! The AI coach really helped me stay consistent.',
        likes: 24,
        comments: 5,
        timestamp: '2 hours ago',
        type: 'achievement',
    },
    {
        id: '2',
        author: { name: 'Mike T.', tier: 'free' },
        content: 'Looking for workout buddies in the Seattle area! Anyone interested in morning runs?',
        likes: 8,
        comments: 12,
        timestamp: '4 hours ago',
        type: 'question',
    },
    {
        id: '3',
        author: { name: 'Emma L.', tier: 'enterprise' },
        content: 'Pro tip: The AI coach suggests doing dynamic stretches before HIIT workouts. Game changer! 🔥',
        likes: 45,
        comments: 8,
        timestamp: '6 hours ago',
        type: 'tip',
    },
]

const mockChallenges: Challenge[] = [
    {
        id: '1',
        title: '30-Day Push-up Challenge',
        description: 'Build upper body strength with progressive push-up goals',
        participants: 1234,
        daysRemaining: 12,
        progress: 60,
    },
    {
        id: '2',
        title: 'Summer Shred 2024',
        description: 'Complete 20 workouts in 30 days',
        participants: 856,
        daysRemaining: 18,
        progress: 35,
    },
]

const CommunityFeatures = () => {
    const [posts] = useState<CommunityPost[]>(mockPosts)
    const [newPost, setNewPost] = useState('')

    const getTypeColor = (type: CommunityPost['type']) => {
        switch (type) {
            case 'achievement':
                return 'green'
            case 'workout':
                return 'blue'
            case 'tip':
                return 'purple'
            case 'question':
                return 'orange'
        }
    }

    const getTierBadge = (tier: 'free' | 'premium' | 'enterprise') => {
        if (tier === 'free') return null
        return (
            <Badge colorPalette={tier === 'premium' ? 'blue' : 'purple'} size="sm">
                {tier}
            </Badge>
        )
    }

    const handlePostSubmit = () => {
        if (newPost.trim()) {
            // In production, this would call the API
            alert('Post submitted! (Demo)')
            setNewPost('')
        }
    }

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">Community</Heading>
                <Text color="gray.600">
                    Connect with fellow fitness enthusiasts
                </Text>
            </VStack>

            <Grid templateColumns={{ base: '1fr', lg: '2fr 1fr' }} gap={6}>
                {/* Feed */}
                <GridItem>
                    {/* New Post */}
                    <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={6}>
                        <Card.Body p={4}>
                            <HStack gap={4}>
                                <Avatar.Root size="md">
                                    <Avatar.Fallback>U</Avatar.Fallback>
                                </Avatar.Root>
                                <Input
                                    placeholder="Share your fitness journey..."
                                    value={newPost}
                                    onChange={(e) => setNewPost(e.target.value)}
                                    flex="1"
                                />
                                <Button
                                    colorScheme="blue"
                                    onClick={handlePostSubmit}
                                    disabled={!newPost.trim()}
                                >
                                    Post
                                </Button>
                            </HStack>
                        </Card.Body>
                    </Card.Root>

                    {/* Posts Feed */}
                    <VStack align="stretch" gap={4}>
                        {posts.map((post) => (
                            <Card.Root key={post.id} bg="white" shadow="sm" borderRadius="lg">
                                <Card.Body p={4}>
                                    <VStack align="stretch" gap={4}>
                                        <HStack justify="space-between">
                                            <HStack gap={3}>
                                                <Avatar.Root size="md">
                                                    <Avatar.Fallback>
                                                        {post.author.name.charAt(0)}
                                                    </Avatar.Fallback>
                                                </Avatar.Root>
                                                <VStack align="start" gap={0}>
                                                    <HStack gap={2}>
                                                        <Text fontWeight="bold">
                                                            {post.author.name}
                                                        </Text>
                                                        {getTierBadge(post.author.tier)}
                                                    </HStack>
                                                    <Text fontSize="sm" color="gray.500">
                                                        {post.timestamp}
                                                    </Text>
                                                </VStack>
                                            </HStack>
                                            <Badge colorPalette={getTypeColor(post.type)}>
                                                {post.type}
                                            </Badge>
                                        </HStack>

                                        <Text>{post.content}</Text>

                                        <HStack gap={4} pt={2} borderTop="1px" borderColor="gray.100">
                                            <Button variant="ghost" size="sm">
                                                ❤️ {post.likes}
                                            </Button>
                                            <Button variant="ghost" size="sm">
                                                💬 {post.comments}
                                            </Button>
                                            <Button variant="ghost" size="sm">
                                                🔗 Share
                                            </Button>
                                        </HStack>
                                    </VStack>
                                </Card.Body>
                            </Card.Root>
                        ))}
                    </VStack>
                </GridItem>

                {/* Sidebar */}
                <GridItem>
                    {/* Active Challenges */}
                    <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={6}>
                        <Card.Body p={4}>
                            <Heading size="md" mb={4}>
                                Active Challenges
                            </Heading>
                            <VStack align="stretch" gap={4}>
                                {mockChallenges.map((challenge) => (
                                    <Box
                                        key={challenge.id}
                                        p={4}
                                        bg="gray.50"
                                        borderRadius="md"
                                    >
                                        <Text fontWeight="bold" mb={1}>
                                            {challenge.title}
                                        </Text>
                                        <Text fontSize="sm" color="gray.600" mb={2}>
                                            {challenge.description}
                                        </Text>
                                        <HStack justify="space-between" fontSize="sm">
                                            <Text color="gray.500">
                                                {challenge.participants.toLocaleString()} participants
                                            </Text>
                                            <Text color="blue.500">
                                                {challenge.daysRemaining} days left
                                            </Text>
                                        </HStack>
                                        <Box
                                            mt={2}
                                            h="4px"
                                            bg="gray.200"
                                            borderRadius="full"
                                            overflow="hidden"
                                        >
                                            <Box
                                                h="full"
                                                w={`${challenge.progress}%`}
                                                bg="blue.500"
                                                borderRadius="full"
                                            />
                                        </Box>
                                    </Box>
                                ))}
                                <Button variant="outline" size="sm" colorScheme="blue">
                                    View All Challenges
                                </Button>
                            </VStack>
                        </Card.Body>
                    </Card.Root>

                    {/* Leaderboard */}
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={4}>
                            <Heading size="md" mb={4}>
                                Weekly Leaderboard
                            </Heading>
                            <VStack align="stretch" gap={3}>
                                {[
                                    { name: 'Alex K.', workouts: 7, rank: 1 },
                                    { name: 'Jamie L.', workouts: 6, rank: 2 },
                                    { name: 'Chris P.', workouts: 6, rank: 3 },
                                    { name: 'You', workouts: 4, rank: 12 },
                                ].map((user) => (
                                    <HStack
                                        key={user.name}
                                        justify="space-between"
                                        p={2}
                                        bg={user.name === 'You' ? 'blue.50' : undefined}
                                        borderRadius="md"
                                    >
                                        <HStack gap={3}>
                                            <Text
                                                fontWeight="bold"
                                                color={
                                                    user.rank === 1
                                                        ? 'yellow.500'
                                                        : user.rank === 2
                                                        ? 'gray.400'
                                                        : user.rank === 3
                                                        ? 'orange.400'
                                                        : 'gray.600'
                                                }
                                            >
                                                #{user.rank}
                                            </Text>
                                            <Text fontWeight={user.name === 'You' ? 'bold' : 'normal'}>
                                                {user.name}
                                            </Text>
                                        </HStack>
                                        <Text color="gray.600">{user.workouts} workouts</Text>
                                    </HStack>
                                ))}
                            </VStack>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>
        </Box>
    )
}

export default CommunityFeatures
