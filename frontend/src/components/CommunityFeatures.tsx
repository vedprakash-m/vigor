import {
    Avatar,
    Badge,
    Box,
    Button,
    Card,
    Container,
    Grid,
    Heading,
    HStack,
    IconButton,
    Input,
    Text,
    Textarea,
    VStack,
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import {
    FiAward,
    FiHeart,
    FiMessageCircle,
    FiSearch,
    FiShare2,
    FiTarget,
    FiUserPlus,
    FiUsers
} from 'react-icons/fi';
import { useVedAuth } from '../contexts/useVedAuth';

interface LeaderboardEntry {
  id: string;
  username: string;
  avatar?: string;
  streak: number;
  level: number;
  totalWorkouts: number;
  weeklyPoints: number;
  badges: string[];
  isFollowed?: boolean;
}

interface CommunityPost {
  id: string;
  userId: string;
  username: string;
  avatar?: string;
  content: string;
  workoutType?: string;
  achievements?: string[];
  likes: number;
  comments: number;
  isLiked: boolean;
  timestamp: Date;
}

interface Challenge {
  id: string;
  title: string;
  description: string;
  type: 'streak' | 'total' | 'consistency';
  target: number;
  duration: string;
  participants: number;
  reward: string;
  isJoined: boolean;
  progress?: number;
}

export const CommunityFeatures: React.FC = () => {
  const { user } = useVedAuth();
  const [activeTab, setActiveTab] = useState<'feed' | 'leaderboard' | 'challenges'>('feed');
  const [posts, setPosts] = useState<CommunityPost[]>([]);
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [challenges, setChallenges] = useState<Challenge[]>([]);
  const [newPost, setNewPost] = useState('');
  const [searchQuery, setSearchQuery] = useState('');

  // Mock data - in real app this would come from API
  useEffect(() => {
    const mockPosts: CommunityPost[] = [
      {
        id: '1',
        userId: 'user1',
        username: 'FitnessFan',
        avatar: '/api/placeholder/40/40',
        content: 'Just completed my 30-day streak! 🔥 The push-up challenge really pushed me to my limits.',
        workoutType: 'Strength Training',
        achievements: ['30-Day Streak', 'Push-up Master'],
        likes: 24,
        comments: 8,
        isLiked: false,
        timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000) // 2 hours ago
      },
      {
        id: '2',
        userId: 'user2',
        username: 'YogaWarrior',
        avatar: '/api/placeholder/40/40',
        content: 'Morning yoga session complete! Starting the day with intention and mindfulness. 🧘‍♀️',
        workoutType: 'Yoga',
        achievements: ['Early Bird'],
        likes: 15,
        comments: 3,
        isLiked: true,
        timestamp: new Date(Date.now() - 4 * 60 * 60 * 1000) // 4 hours ago
      },
      {
        id: '3',
        userId: 'user3',
        username: 'CardioKing',
        avatar: '/api/placeholder/40/40',
        content: 'Beat my personal record on the 5K run today! 🏃‍♂️ Thanks to everyone who cheered me on.',
        workoutType: 'Cardio',
        achievements: ['Personal Best', 'Speed Demon'],
        likes: 31,
        comments: 12,
        isLiked: false,
        timestamp: new Date(Date.now() - 6 * 60 * 60 * 1000) // 6 hours ago
      }
    ];

    const mockLeaderboard: LeaderboardEntry[] = [
      {
        id: 'user1',
        username: 'FitnessFan',
        avatar: '/api/placeholder/40/40',
        streak: 32,
        level: 8,
        totalWorkouts: 156,
        weeklyPoints: 420,
        badges: ['Consistency King', 'Strength Master', 'Community Champion'],
        isFollowed: true
      },
      {
        id: 'user2',
        username: 'YogaWarrior',
        avatar: '/api/placeholder/40/40',
        streak: 28,
        level: 7,
        totalWorkouts: 134,
        weeklyPoints: 385,
        badges: ['Flexibility Expert', 'Mindfulness Master'],
        isFollowed: false
      },
      {
        id: 'user3',
        username: 'CardioKing',
        avatar: '/api/placeholder/40/40',
        streak: 25,
        level: 6,
        totalWorkouts: 98,
        weeklyPoints: 350,
        badges: ['Speed Demon', 'Endurance Elite'],
        isFollowed: true
      },
      {
        id: 'user4',
        username: 'StrengthSeeker',
        avatar: '/api/placeholder/40/40',
        streak: 22,
        level: 6,
        totalWorkouts: 112,
        weeklyPoints: 320,
        badges: ['Iron Will', 'Progressive Overload'],
        isFollowed: false
      },
      {
        id: 'user5',
        username: 'FlexibilityFocus',
        avatar: '/api/placeholder/40/40',
        streak: 18,
        level: 5,
        totalWorkouts: 89,
        weeklyPoints: 280,
        badges: ['Stretch Master', 'Balance Expert'],
        isFollowed: false
      }
    ];

    const mockChallenges: Challenge[] = [
      {
        id: '1',
        title: '30-Day Consistency Challenge',
        description: 'Complete a workout every day for 30 days',
        type: 'streak',
        target: 30,
        duration: '30 days',
        participants: 1247,
        reward: 'Consistency Master Badge + 500 points',
        isJoined: true,
        progress: 12
      },
      {
        id: '2',
        title: 'November Push-Up Challenge',
        description: 'Complete 1000 push-ups this month',
        type: 'total',
        target: 1000,
        duration: 'This month',
        participants: 856,
        reward: 'Push-Up Master Badge + 300 points',
        isJoined: false,
        progress: 0
      },
      {
        id: '3',
        title: 'Weekend Warrior',
        description: 'Complete 8 weekend workouts in November',
        type: 'consistency',
        target: 8,
        duration: 'This month',
        participants: 432,
        reward: 'Weekend Warrior Badge + 250 points',
        isJoined: true,
        progress: 3
      }
    ];

    setPosts(mockPosts);
    setLeaderboard(mockLeaderboard);
    setChallenges(mockChallenges);
  }, []);

  const handleLike = (postId: string) => {
    setPosts(posts.map(post =>
      post.id === postId
        ? { ...post, isLiked: !post.isLiked, likes: post.isLiked ? post.likes - 1 : post.likes + 1 }
        : post
    ));
  };

  const handleFollow = (userId: string) => {
    setLeaderboard(leaderboard.map(entry =>
      entry.id === userId
        ? { ...entry, isFollowed: !entry.isFollowed }
        : entry
    ));
  };

  const handleJoinChallenge = (challengeId: string) => {
    setChallenges(challenges.map(challenge =>
      challenge.id === challengeId
        ? {
            ...challenge,
            isJoined: !challenge.isJoined,
            participants: challenge.isJoined ? challenge.participants - 1 : challenge.participants + 1
          }
        : challenge
    ));
  };

  const handlePostSubmit = () => {
    if (!newPost.trim()) return;

    const post: CommunityPost = {
      id: Date.now().toString(),
      userId: user?.id || 'current-user',
      username: user?.email?.split('@')[0] || 'You',
      content: newPost,
      likes: 0,
      comments: 0,
      isLiked: false,
      timestamp: new Date()
    };

    setPosts([post, ...posts]);
    setNewPost('');
  };

  const formatTimeAgo = (date: Date) => {
    const now = new Date();
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));

    if (diffInHours < 1) return 'Just now';
    if (diffInHours < 24) return `${diffInHours}h ago`;
    return `${Math.floor(diffInHours / 24)}d ago`;
  };

  const TabButton = ({ tab, label }: { tab: typeof activeTab; label: string }) => (
    <Button
      variant={activeTab === tab ? 'solid' : 'ghost'}
      colorScheme={activeTab === tab ? 'blue' : 'gray'}
      onClick={() => setActiveTab(tab)}
      size="sm"
    >
      {label}
    </Button>
  );

  return (
    <Container maxW="6xl" py={6}>
      <VStack gap={6} alignItems="stretch">
        {/* Header */}
        <Box>
          <Heading size="lg" mb={2}>Community</Heading>
          <Text color="gray.600">Connect, share, and get motivated with fellow fitness enthusiasts</Text>
        </Box>

        {/* Navigation Tabs */}
        <HStack gap={2}>
          <TabButton tab="feed" label="Activity Feed" />
          <TabButton tab="leaderboard" label="Leaderboard" />
          <TabButton tab="challenges" label="Challenges" />
        </HStack>

        {/* Search Bar */}
        <Box>
          <Input
            placeholder="Search community..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            leftElement={<FiSearch />}
          />
        </Box>

        {/* Content based on active tab */}
        {activeTab === 'feed' && (
          <VStack gap={4} alignItems="stretch">
            {/* Create Post */}
            <Card>
              <Box p={4}>
                <VStack gap={3} alignItems="stretch">
                  <Textarea
                    placeholder="Share your fitness journey..."
                    value={newPost}
                    onChange={(e) => setNewPost(e.target.value)}
                    resize="none"
                    minH="100px"
                  />
                  <HStack justifyContent="space-between">
                    <Text fontSize="sm" color="gray.500">
                      Share your achievements, progress, or motivation!
                    </Text>
                    <Button
                      colorScheme="blue"
                      size="sm"
                      onClick={handlePostSubmit}
                      isDisabled={!newPost.trim()}
                    >
                      Share
                    </Button>
                  </HStack>
                </VStack>
              </Box>
            </Card>

            {/* Posts Feed */}
            {posts.map((post) => (
              <Card key={post.id}>
                <Box p={4}>
                  <VStack gap={3} alignItems="stretch">
                    {/* Post Header */}
                    <HStack justifyContent="space-between">
                      <HStack gap={3}>
                        <Avatar size="sm" src={post.avatar} name={post.username} />
                        <VStack alignItems="start" gap={0}>
                          <Text fontWeight="bold" fontSize="sm">{post.username}</Text>
                          <Text fontSize="xs" color="gray.500">{formatTimeAgo(post.timestamp)}</Text>
                        </VStack>
                      </HStack>
                      <IconButton
                        aria-label="More options"
                        icon={<FiShare2 />}
                        variant="ghost"
                        size="sm"
                      />
                    </HStack>

                    {/* Post Content */}
                    <Text>{post.content}</Text>

                    {/* Workout Type & Achievements */}
                    {(post.workoutType || post.achievements) && (
                      <HStack gap={2} flexWrap="wrap">
                        {post.workoutType && (
                          <Badge colorScheme="blue" variant="subtle">
                            {post.workoutType}
                          </Badge>
                        )}
                        {post.achievements?.map((achievement, index) => (
                          <Badge key={index} colorScheme="gold" variant="subtle">
                            <FiAward style={{ marginRight: '4px' }} />
                            {achievement}
                          </Badge>
                        ))}
                      </HStack>
                    )}

                    {/* Post Actions */}
                    <HStack justifyContent="space-between" pt={2} borderTop="1px solid" borderColor="gray.100">
                      <HStack gap={4}>
                        <Button
                          variant="ghost"
                          size="sm"
                          leftIcon={<FiHeart />}
                          colorScheme={post.isLiked ? 'red' : 'gray'}
                          onClick={() => handleLike(post.id)}
                        >
                          {post.likes}
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          leftIcon={<FiMessageCircle />}
                          colorScheme="gray"
                        >
                          {post.comments}
                        </Button>
                      </HStack>
                      <Button
                        variant="ghost"
                        size="sm"
                        leftIcon={<FiShare2 />}
                        colorScheme="gray"
                      >
                        Share
                      </Button>
                    </HStack>
                  </VStack>
                </Box>
              </Card>
            ))}
          </VStack>
        )}

        {activeTab === 'leaderboard' && (
          <VStack gap={4} alignItems="stretch">
            {/* Current User Rank */}
            <Card bg="blue.50" borderColor="blue.200">
              <Box p={4}>
                <HStack justifyContent="space-between">
                  <VStack alignItems="start" gap={1}>
                    <Text fontSize="sm" color="blue.600" fontWeight="bold">Your Rank</Text>
                    <Text fontSize="2xl" fontWeight="bold" color="blue.700">#12</Text>
                  </VStack>
                  <VStack alignItems="end" gap={1}>
                    <Text fontSize="sm" color="blue.600">Weekly Points</Text>
                    <Text fontSize="xl" fontWeight="bold" color="blue.700">185</Text>
                  </VStack>
                </HStack>
              </Box>
            </Card>

            {/* Leaderboard */}
            {leaderboard.map((entry, index) => (
              <Card key={entry.id}>
                <Box p={4}>
                  <HStack justifyContent="space-between">
                    <HStack gap={3}>
                      <Box
                        minW="32px"
                        h="32px"
                        bg={index < 3 ? 'gold.100' : 'gray.100'}
                        color={index < 3 ? 'gold.700' : 'gray.600'}
                        borderRadius="full"
                        display="flex"
                        alignItems="center"
                        justifyContent="center"
                        fontWeight="bold"
                        fontSize="sm"
                      >
                        #{index + 1}
                      </Box>
                      <Avatar size="md" src={entry.avatar} name={entry.username} />
                      <VStack alignItems="start" gap={0}>
                        <Text fontWeight="bold">{entry.username}</Text>
                        <HStack gap={2}>
                          <Text fontSize="sm" color="gray.600">
                            Level {entry.level} • {entry.streak} day streak
                          </Text>
                        </HStack>
                        <HStack gap={1} mt={1}>
                          {entry.badges.slice(0, 2).map((badge, badgeIndex) => (
                            <Badge key={badgeIndex} size="sm" colorScheme="purple" variant="subtle">
                              {badge}
                            </Badge>
                          ))}
                          {entry.badges.length > 2 && (
                            <Badge size="sm" colorScheme="gray" variant="subtle">
                              +{entry.badges.length - 2}
                            </Badge>
                          )}
                        </HStack>
                      </VStack>
                    </HStack>
                    <VStack alignItems="end" gap={2}>
                      <Text fontWeight="bold" color="blue.600">
                        {entry.weeklyPoints} pts
                      </Text>
                      <Button
                        size="sm"
                        variant={entry.isFollowed ? 'solid' : 'outline'}
                        colorScheme="blue"
                        leftIcon={<FiUserPlus />}
                        onClick={() => handleFollow(entry.id)}
                      >
                        {entry.isFollowed ? 'Following' : 'Follow'}
                      </Button>
                    </VStack>
                  </HStack>
                </Box>
              </Card>
            ))}
          </VStack>
        )}

        {activeTab === 'challenges' && (
          <VStack gap={4} alignItems="stretch">
            {challenges.map((challenge) => (
              <Card key={challenge.id}>
                <Box p={4}>
                  <VStack gap={4} alignItems="stretch">
                    {/* Challenge Header */}
                    <HStack justifyContent="space-between">
                      <VStack alignItems="start" gap={1}>
                        <Text fontWeight="bold" fontSize="lg">{challenge.title}</Text>
                        <Text color="gray.600">{challenge.description}</Text>
                      </VStack>
                      <Badge
                        colorScheme={challenge.isJoined ? 'green' : 'blue'}
                        variant="subtle"
                        fontSize="xs"
                      >
                        {challenge.isJoined ? 'Joined' : 'Available'}
                      </Badge>
                    </HStack>

                    {/* Challenge Details */}
                    <Grid templateColumns="repeat(auto-fit, minmax(120px, 1fr))" gap={4}>
                      <VStack alignItems="start" gap={1}>
                        <Text fontSize="sm" color="gray.500">Target</Text>
                        <Text fontWeight="bold">{challenge.target}</Text>
                      </VStack>
                      <VStack alignItems="start" gap={1}>
                        <Text fontSize="sm" color="gray.500">Duration</Text>
                        <Text fontWeight="bold">{challenge.duration}</Text>
                      </VStack>
                      <VStack alignItems="start" gap={1}>
                        <Text fontSize="sm" color="gray.500">Participants</Text>
                        <HStack>
                          <FiUsers />
                          <Text fontWeight="bold">{challenge.participants.toLocaleString()}</Text>
                        </HStack>
                      </VStack>
                    </Grid>

                    {/* Progress (if joined) */}
                    {challenge.isJoined && challenge.progress !== undefined && (
                      <VStack alignItems="stretch" gap={2}>
                        <HStack justifyContent="space-between">
                          <Text fontSize="sm" fontWeight="medium">Your Progress</Text>
                          <Text fontSize="sm" color="gray.600">
                            {challenge.progress} / {challenge.target}
                          </Text>
                        </HStack>
                        <Box
                          w="full"
                          bg="gray.200"
                          borderRadius="full"
                          h="8px"
                          overflow="hidden"
                        >
                          <Box
                            bg="blue.400"
                            h="full"
                            w={`${Math.min((challenge.progress / challenge.target) * 100, 100)}%`}
                            transition="width 0.3s ease"
                          />
                        </Box>
                      </VStack>
                    )}

                    {/* Reward */}
                    <Box p={3} bg="gray.50" borderRadius="md">
                      <HStack>
                        <FiTarget />
                        <Text fontSize="sm" color="gray.700">
                          <Text as="span" fontWeight="medium">Reward:</Text> {challenge.reward}
                        </Text>
                      </HStack>
                    </Box>

                    {/* Join/Leave Button */}
                    <Button
                      colorScheme={challenge.isJoined ? 'red' : 'blue'}
                      variant={challenge.isJoined ? 'outline' : 'solid'}
                      onClick={() => handleJoinChallenge(challenge.id)}
                    >
                      {challenge.isJoined ? 'Leave Challenge' : 'Join Challenge'}
                    </Button>
                  </VStack>
                </Box>
              </Card>
            ))}
          </VStack>
        )}
      </VStack>
    </Container>
  );
};

export default CommunityFeatures;
