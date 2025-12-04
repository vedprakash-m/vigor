import {
    Badge,
    Box,
    Button,
    Container,
    Grid,
    Heading,
    HStack,
    IconButton,
    Text,
    Textarea,
    VStack
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import {
    FiAward,
    FiHeart,
    FiMoreHorizontal,
    FiShare2,
    FiUsers
} from 'react-icons/fi';
import { useVedAuth } from '../contexts/useVedAuth';
import {
    Avatar,
    Card,
    CardBody,
    FormControl,
    FormLabel,
    Menu,
    MenuButton,
    MenuItem,
    MenuList,
    Modal,
    ModalBody,
    ModalCloseButton,
    ModalContent,
    ModalFooter,
    ModalHeader,
    ModalOverlay,
    Select,
    Stat,
    StatHelpText,
    StatLabel,
    StatNumber,
    Tab,
    TabList,
    TabPanel,
    TabPanels,
    Tabs,
    useDisclosure,
    useToast,
} from './chakra-compat';

interface LeaderboardEntry {
  id: string;
  username: string;
  avatar?: string;
  streak: number;
  weeklyWorkouts: number;
  totalPoints: number;
  level: number;
  isCurrentUser?: boolean;
}

interface SharedWorkout {
  id: string;
  user: {
    username: string;
    avatar?: string;
    level: number;
  };
  workoutType: string;
  duration: number;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  completedAt: string;
  notes?: string;
  likes: number;
  isLiked: boolean;
}

interface CommunityStats {
  totalActiveUsers: number;
  weeklyWorkouts: number;
  averageStreak: number;
  topWorkoutType: string;
}

export const SocialFeatures: React.FC = () => {
  const { user } = useVedAuth();
  const toast = useToast();
  const { isOpen, onOpen, onClose } = useDisclosure();

  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [sharedWorkouts, setSharedWorkouts] = useState<SharedWorkout[]>([]);
  const [communityStats, setCommunityStats] = useState<CommunityStats | null>(null);
  const [shareWorkoutData, setShareWorkoutData] = useState<{
    workoutType: string;
    duration: string;
    difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
    notes: string;
  }>({
    workoutType: '',
    duration: '',
    difficulty: 'Intermediate',
    notes: '',
  });

  useEffect(() => {
    // Simulate fetching social data
    const fetchSocialData = async () => {
      // Mock leaderboard data
      const mockLeaderboard: LeaderboardEntry[] = [
        {
          id: '1',
          username: 'FitnessPro',
          streak: 45,
          weeklyWorkouts: 6,
          totalPoints: 2250,
          level: 12,
        },
        {
          id: '2',
          username: 'HealthyHabits',
          streak: 32,
          weeklyWorkouts: 5,
          totalPoints: 1890,
          level: 10,
        },
        {
          id: '3',
          username: user?.username || 'You',
          streak: 15,
          weeklyWorkouts: 4,
          totalPoints: 890,
          level: 6,
          isCurrentUser: true,
        },
        {
          id: '4',
          username: 'GymWarrior',
          streak: 28,
          weeklyWorkouts: 7,
          totalPoints: 1650,
          level: 9,
        },
        {
          id: '5',
          username: 'CardioQueen',
          streak: 21,
          weeklyWorkouts: 5,
          totalPoints: 1340,
          level: 8,
        },
      ].sort((a, b) => b.totalPoints - a.totalPoints);

      // Mock shared workouts
      const mockSharedWorkouts: SharedWorkout[] = [
        {
          id: '1',
          user: { username: 'FitnessPro', level: 12 },
          workoutType: 'HIIT Circuit',
          duration: 45,
          difficulty: 'Advanced',
          completedAt: '2025-01-22T10:30:00Z',
          notes: 'Crushed this morning session! 💪 The burpee-to-squat combo was intense.',
          likes: 23,
          isLiked: false,
        },
        {
          id: '2',
          user: { username: 'HealthyHabits', level: 10 },
          workoutType: 'Strength Training',
          duration: 60,
          difficulty: 'Intermediate',
          completedAt: '2025-01-22T08:15:00Z',
          notes: 'New PR on deadlifts! The AI coach suggestions really helped my form.',
          likes: 18,
          isLiked: true,
        },
        {
          id: '3',
          user: { username: 'CardioQueen', level: 8 },
          workoutType: 'Running',
          duration: 30,
          difficulty: 'Beginner',
          completedAt: '2025-01-21T18:45:00Z',
          notes: 'Beautiful sunset run! Perfect way to end the day.',
          likes: 15,
          isLiked: false,
        },
      ];

      // Mock community stats
      const mockCommunityStats: CommunityStats = {
        totalActiveUsers: 1247,
        weeklyWorkouts: 8934,
        averageStreak: 12,
        topWorkoutType: 'Strength Training',
      };

      setLeaderboard(mockLeaderboard);
      setSharedWorkouts(mockSharedWorkouts);
      setCommunityStats(mockCommunityStats);
    };

    fetchSocialData();
  }, [user]);

  const handleLikeWorkout = async (workoutId: string) => {
    setSharedWorkouts(prev =>
      prev.map(workout => {
        if (workout.id === workoutId) {
          return {
            ...workout,
            isLiked: !workout.isLiked,
            likes: workout.isLiked ? workout.likes - 1 : workout.likes + 1,
          };
        }
        return workout;
      })
    );

    toast({
      title: 'Workout liked!',
      description: 'Your support helps motivate the community.',
      status: 'success',
      duration: 2000,

    });
  };

  const handleShareWorkout = async () => {
    try {
      // Simulate sharing workout
      const newSharedWorkout: SharedWorkout = {
        id: Date.now().toString(),
        user: {
          username: user?.username || 'You',
          level: 6, // Mock level
        },
        workoutType: shareWorkoutData.workoutType,
        duration: parseInt(shareWorkoutData.duration),
        difficulty: shareWorkoutData.difficulty,
        completedAt: new Date().toISOString(),
        notes: shareWorkoutData.notes,
        likes: 0,
        isLiked: false,
      };

      setSharedWorkouts(prev => [newSharedWorkout, ...prev]);

      toast({
        title: 'Workout shared!',
        description: 'Your workout has been shared with the community.',
        status: 'success',
        duration: 3000,

      });

      // Reset form
      setShareWorkoutData({
        workoutType: '',
        duration: '',
        difficulty: 'Intermediate',
        notes: '',
      });

      onClose();
    } catch {
      toast({
        title: 'Sharing failed',
        description: 'Could not share your workout. Please try again.',
        status: 'error',
        duration: 3000,

      });
    }
  };

  const formatTimeAgo = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));

    if (diffInHours < 1) return 'Just now';
    if (diffInHours < 24) return `${diffInHours}h ago`;
    return `${Math.floor(diffInHours / 24)}d ago`;
  };

  const getRankIcon = (position: number) => {
    switch (position) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '🏃';
    }
  };

  return (
    <Container maxW="container.xl" py={6}>
      <VStack gap={6} align="stretch">
        <Box>
          <Heading size="lg" mb={2}>Community</Heading>
          <Text color="gray.600">
            Connect with fellow fitness enthusiasts and share your progress.
          </Text>
        </Box>

        {/* Community Stats */}
        {communityStats && (
          <Grid templateColumns={{ base: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }} gap={4}>
            <Stat bg="white" p={4} borderRadius="lg" boxShadow="sm">
              <StatLabel><FiUsers style={{ display: 'inline', marginRight: '8px' }} />Active Users</StatLabel>
              <StatNumber>{communityStats.totalActiveUsers.toLocaleString()}</StatNumber>
              <StatHelpText>This month</StatHelpText>
            </Stat>

            <Stat bg="white" p={4} borderRadius="lg" boxShadow="sm">
              <StatLabel><FiAward style={{ display: 'inline', marginRight: '8px' }} />Weekly Workouts</StatLabel>
              <StatNumber>{communityStats.weeklyWorkouts.toLocaleString()}</StatNumber>
              <StatHelpText>Community total</StatHelpText>
            </Stat>

            <Stat bg="white" p={4} borderRadius="lg" boxShadow="sm">
              <StatLabel>Average Streak</StatLabel>
              <StatNumber>{communityStats.averageStreak} days</StatNumber>
              <StatHelpText>Community average</StatHelpText>
            </Stat>

            <Stat bg="white" p={4} borderRadius="lg" boxShadow="sm">
              <StatLabel>Popular Workout</StatLabel>
              <StatNumber fontSize="md">{communityStats.topWorkoutType}</StatNumber>
              <StatHelpText>Most completed</StatHelpText>
            </Stat>
          </Grid>
        )}

        {/* Share Workout Button */}
        <Box>
          <Button
            colorScheme="blue"
            onClick={onOpen}
            size="lg"
          >
            <FiShare2 style={{ marginRight: '8px' }} />
            Share Your Workout
          </Button>
        </Box>

        {/* Tabs for different social features */}
        <Tabs variant="soft-rounded" colorScheme="blue">
          <TabList>
            <Tab>Leaderboard</Tab>
            <Tab>Shared Workouts</Tab>
          </TabList>

          <TabPanels>
            {/* Leaderboard Tab */}
            <TabPanel px={0}>
              <Card>
                <CardBody>
                  <Heading size="md" mb={4}>Weekly Leaderboard</Heading>
                  <VStack gap={3} align="stretch">
                    {leaderboard.map((entry, index) => (
                      <Box
                        key={entry.id}
                        p={4}
                        bg={entry.isCurrentUser ? 'blue.50' : 'gray.50'}
                        borderRadius="lg"
                        border={entry.isCurrentUser ? '2px solid' : '1px solid'}
                        borderColor={entry.isCurrentUser ? 'blue.200' : 'gray.200'}
                      >
                        <HStack justifyContent="space-between">
                          <HStack gap={3}>
                            <Text fontSize="lg" minW="40px">
                              {getRankIcon(index + 1)} #{index + 1}
                            </Text>
                            <Avatar
                              size="sm"
                              name={entry.username}
                              src={entry.avatar}
                            />
                            <VStack align="start" gap={0}>
                              <HStack>
                                <Text fontWeight="bold">
                                  {entry.username}
                                  {entry.isCurrentUser && (
                                    <Badge ml={2} colorScheme="blue" variant="subtle">You</Badge>
                                  )}
                                </Text>
                                <Badge colorScheme="purple" variant="outline">
                                  Level {entry.level}
                                </Badge>
                              </HStack>
                              <Text fontSize="sm" color="gray.600">
                                {entry.streak} day streak • {entry.weeklyWorkouts} workouts this week
                              </Text>
                            </VStack>
                          </HStack>
                          <Text fontWeight="bold" color="blue.600">
                            {entry.totalPoints.toLocaleString()} pts
                          </Text>
                        </HStack>
                      </Box>
                    ))}
                  </VStack>
                </CardBody>
              </Card>
            </TabPanel>

            {/* Shared Workouts Tab */}
            <TabPanel px={0}>
              <VStack gap={4} align="stretch">
                {sharedWorkouts.map((workout) => (
                  <Card key={workout.id}>
                    <CardBody>
                      <VStack gap={3} align="stretch">
                        {/* User Info */}
                        <HStack justifyContent="space-between">
                          <HStack gap={3}>
                            <Avatar size="sm" name={workout.user.username} />
                            <VStack align="start" gap={0}>
                              <HStack>
                                <Text fontWeight="bold">{workout.user.username}</Text>
                                <Badge colorScheme="purple" variant="outline" size="sm">
                                  Level {workout.user.level}
                                </Badge>
                              </HStack>
                              <Text fontSize="sm" color="gray.600">
                                {formatTimeAgo(workout.completedAt)}
                              </Text>
                            </VStack>
                          </HStack>

                          <Menu>
                            <MenuButton>
                              <IconButton
                                aria-label="More options"
                                variant="ghost"
                                size="sm"
                              >
                                <FiMoreHorizontal />
                              </IconButton>
                            </MenuButton>
                            <MenuList>
                              <MenuItem>Report</MenuItem>
                              <MenuItem>Hide</MenuItem>
                            </MenuList>
                          </Menu>
                        </HStack>

                        {/* Workout Details */}
                        <Box>
                          <HStack gap={4} mb={2}>
                            <Badge colorScheme="blue" variant="subtle">
                              {workout.workoutType}
                            </Badge>
                            <Badge colorScheme="green" variant="subtle">
                              {workout.duration} min
                            </Badge>
                            <Badge colorScheme="orange" variant="subtle">
                              {workout.difficulty}
                            </Badge>
                          </HStack>

                          {workout.notes && (
                            <Text color="gray.700" fontSize="sm">
                              {workout.notes}
                            </Text>
                          )}
                        </Box>

                        {/* Actions */}
                        <HStack justifyContent="space-between">
                          <Button
                            variant={workout.isLiked ? 'solid' : 'ghost'}
                            colorScheme={workout.isLiked ? 'red' : 'gray'}
                            size="sm"
                            onClick={() => handleLikeWorkout(workout.id)}
                          >
                            <FiHeart style={{ marginRight: '4px' }} />
                            {workout.likes} {workout.likes === 1 ? 'Like' : 'Likes'}
                          </Button>

                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              // Copy workout link to clipboard
                              navigator.clipboard.writeText(`Check out this workout by ${workout.user.username}!`);
                              toast({
                                title: 'Link copied!',
                                status: 'success',
                                duration: 2000,
                              });
                            }}
                          >
                            <FiShare2 style={{ marginRight: '4px' }} />
                            Share
                          </Button>
                        </HStack>
                      </VStack>
                    </CardBody>
                  </Card>
                ))}
              </VStack>
            </TabPanel>
          </TabPanels>
        </Tabs>

        {/* Share Workout Modal */}
        <Modal isOpen={isOpen} onClose={onClose} size="md">
          <ModalOverlay />
          <ModalContent>
            <ModalHeader>Share Your Workout</ModalHeader>
            <ModalCloseButton />
            <ModalBody>
              <VStack gap={4}>
                <FormControl>
                  <FormLabel>Workout Type</FormLabel>
                  <Select
                    placeholder="Select workout type"
                    value={shareWorkoutData.workoutType}
                    onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setShareWorkoutData(prev => ({
                      ...prev,
                      workoutType: e.target.value
                    }))}
                  >
                    <option value="Strength Training">Strength Training</option>
                    <option value="Cardio">Cardio</option>
                    <option value="HIIT">HIIT</option>
                    <option value="Yoga">Yoga</option>
                    <option value="Running">Running</option>
                    <option value="Cycling">Cycling</option>
                    <option value="Swimming">Swimming</option>
                  </Select>
                </FormControl>

                <FormControl>
                  <FormLabel>Duration (minutes)</FormLabel>
                  <Select
                    placeholder="Select duration"
                    value={shareWorkoutData.duration}
                    onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setShareWorkoutData(prev => ({
                      ...prev,
                      duration: e.target.value
                    }))}
                  >
                    <option value="15">15 minutes</option>
                    <option value="30">30 minutes</option>
                    <option value="45">45 minutes</option>
                    <option value="60">60 minutes</option>
                    <option value="90">90 minutes</option>
                  </Select>
                </FormControl>

                <FormControl>
                  <FormLabel>Difficulty</FormLabel>
                  <Select
                    value={shareWorkoutData.difficulty}
                    onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setShareWorkoutData(prev => ({
                      ...prev,
                      difficulty: e.target.value as 'Beginner' | 'Intermediate' | 'Advanced'
                    }))}
                  >
                    <option value="Beginner">Beginner</option>
                    <option value="Intermediate">Intermediate</option>
                    <option value="Advanced">Advanced</option>
                  </Select>
                </FormControl>

                <FormControl>
                  <FormLabel>Notes (optional)</FormLabel>
                  <Textarea
                    placeholder="Share how it went, any achievements, or motivational message..."
                    value={shareWorkoutData.notes}
                    onChange={(e) => setShareWorkoutData(prev => ({
                      ...prev,
                      notes: e.target.value
                    }))}
                    maxLength={200}
                  />
                  <Text fontSize="xs" color="gray.500" textAlign="right">
                    {shareWorkoutData.notes.length}/200
                  </Text>
                </FormControl>
              </VStack>
            </ModalBody>

            <ModalFooter>
              <Button variant="ghost" mr={3} onClick={onClose}>
                Cancel
              </Button>
              <Button
                colorScheme="blue"
                onClick={handleShareWorkout}
                disabled={!shareWorkoutData.workoutType || !shareWorkoutData.duration}
              >
                Share Workout
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>
      </VStack>
    </Container>
  );
};

export default SocialFeatures;
