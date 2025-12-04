import {
    Alert,
    AlertDescription,
    AlertTitle,
    Badge,
    Box,
    Button,
    Card,
    CardBody,
    Grid,
    Heading,
    HStack,
    Progress,
    SimpleGrid,
    Text,
    VStack,
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import { FiBarChart2, FiCalendar, FiClock, FiTarget, FiTrendingUp, FiUsers } from 'react-icons/fi';
import AnalyticsDashboard from '../components/AnalyticsDashboard';
import { AlertIcon, Tab, TabList, TabPanel, TabPanels, Tabs } from '../components/chakra-compat';
import { BadgeGrid, QuickStats, StreakDisplay } from '../components/GamificationComponentsV2';
import MobileLayout from '../components/MobileLayout';
import SocialFeatures from '../components/SocialFeatures';
import { useVedAuth } from '../contexts/useVedAuth';
import { engagementTracker, type UserEngagementProfile } from '../services/engagementTracker';
import { gamificationService, type UserGamificationStats } from '../services/gamificationService';
import { workoutService } from '../services/workoutService';

interface WeeklyGoal {
  type: 'workouts' | 'duration' | 'streak';
  target: number;
  current: number;
  unit: string;
  color: string;
}

interface PersonalizationData {
  recommendedWorkoutType: string;
  recommendedDuration: number;
  motivationalMessage: string;
  nextMilestone: string;
  riskLevel: 'low' | 'medium' | 'high';
  personalizedTips: string[];
}

const PersonalizedDashboardPage: React.FC = () => {
  const { user } = useVedAuth();
  const [gamificationStats, setGamificationStats] = useState<UserGamificationStats | null>(null);
  const [engagementProfile, setEngagementProfile] = useState<UserEngagementProfile | null>(null);
  const [weeklyGoals, setWeeklyGoals] = useState<WeeklyGoal[]>([]);
  const [personalization, setPersonalization] = useState<PersonalizationData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setIsLoading(true);

        // Track page view
        engagementTracker.trackPageView('dashboard', {
          userTier: user?.tier || 'FREE',
          timestamp: new Date().toISOString(),
        });

        // Fetch gamification stats
        const stats = await gamificationService.getUserStats();
        setGamificationStats(stats);

        // Fetch engagement profile
        const profile = await engagementTracker.getUserEngagementProfile();
        setEngagementProfile(profile);

        // Fetch weekly goals
        const goals = await generateWeeklyGoals(stats);
        setWeeklyGoals(goals);

        // Generate personalization data
        const personalData = await generatePersonalizationData(stats, profile);
        setPersonalization(personalData);

      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchDashboardData();
  }, [user]);

  const generateWeeklyGoals = async (stats: UserGamificationStats): Promise<WeeklyGoal[]> => {
    try {
      const workoutDays = await workoutService.getWorkoutDays();
      const thisWeekWorkouts = workoutDays.filter(date => {
        const workoutDate = new Date(date);
        const weekStart = new Date();
        weekStart.setDate(weekStart.getDate() - weekStart.getDay());
        return workoutDate >= weekStart;
      }).length;

      return [
        {
          type: 'workouts',
          target: 4,
          current: thisWeekWorkouts,
          unit: 'workouts',
          color: 'blue',
        },
        {
          type: 'duration',
          target: 180, // 3 hours per week
          current: thisWeekWorkouts * 45, // Estimated 45 min per workout
          unit: 'minutes',
          color: 'green',
        },
        {
          type: 'streak',
          target: 7,
          current: stats.streaks.daily.current,
          unit: 'days',
          color: 'orange',
        },
      ];
    } catch (error) {
      console.error('Failed to generate weekly goals:', error);
      return [];
    }
  };

  const generatePersonalizationData = async (
    stats: UserGamificationStats,
    profile: UserEngagementProfile | null
  ): Promise<PersonalizationData> => {
    // Analyze user patterns to provide personalized recommendations
    const completionRate = profile && profile.workoutsStarted > 0
      ? profile.workoutsCompleted / profile.workoutsStarted
      : 0;

    const averageSessionTime = profile?.averageSessionDuration || 30;
    const riskLevel = profile?.riskLevel || 'medium';

    // Determine recommended workout type based on history and completion rate
    let recommendedWorkoutType = 'Strength Training';
    let recommendedDuration = 45;

    if (completionRate < 0.6) {
      recommendedWorkoutType = 'HIIT';
      recommendedDuration = 20; // Shorter for better completion
    } else if (averageSessionTime > 60) {
      recommendedWorkoutType = 'Endurance';
      recommendedDuration = 60;
    }

    // Generate motivational message based on performance
    let motivationalMessage = "You're doing great! Keep up the momentum.";
    if (stats.streaks.daily.current > 7) {
      motivationalMessage = "🔥 You're on fire! This streak is incredible!";
    } else if (stats.streaks.daily.current === 0) {
      motivationalMessage = "Ready for a fresh start? Today's the perfect day!";
    }

    // Determine next milestone
    let nextMilestone = 'Complete 5 workouts this week';
    if (stats.totalPoints > 1000) {
      nextMilestone = 'Reach 2000 total points';
    } else if (stats.streaks.daily.current > 10) {
      nextMilestone = 'Achieve 30-day streak';
    }

    // Generate personalized tips
    const personalizedTips = profile?.personalizedRecommendations || [
      'Try morning workouts for better consistency',
      'Mix up your routine with different workout types',
      'Use the AI coach for form guidance',
    ];

    return {
      recommendedWorkoutType,
      recommendedDuration,
      motivationalMessage,
      nextMilestone,
      riskLevel,
      personalizedTips,
    };
  };

  const getGoalProgress = (goal: WeeklyGoal): number => {
    return Math.min(100, (goal.current / goal.target) * 100);
  };

  const getGoalStatus = (goal: WeeklyGoal): { color: string; message: string } => {
    const progress = getGoalProgress(goal);
    if (progress >= 100) return { color: 'green', message: 'Completed! 🎉' };
    if (progress >= 75) return { color: 'blue', message: 'Almost there!' };
    if (progress >= 50) return { color: 'orange', message: 'Good progress' };
    return { color: 'gray', message: 'Getting started' };
  };

  if (isLoading) {
    return (
      <MobileLayout gamificationStats={gamificationStats}>
        <VStack gap={6} align="center" py={20}>
          <Heading size="lg">Loading your personalized dashboard...</Heading>
          <Text color="gray.600">Analyzing your fitness journey</Text>
        </VStack>
      </MobileLayout>
    );
  }

  return (
    <MobileLayout gamificationStats={gamificationStats}>
      <VStack gap={6} align="stretch">
        {/* Personalized Welcome Section */}
        <Box>
          <Heading size="lg" mb={2}>
            Welcome back, {user?.username}! 👋
          </Heading>
          <Text color="gray.600" fontSize="lg">
            {personalization?.motivationalMessage || "Ready to achieve your fitness goals?"}
          </Text>
          {personalization?.riskLevel === 'high' && (
            <Alert status="warning" mt={3} borderRadius="md">
              <AlertIcon />
              <Box>
                <AlertTitle>We miss you!</AlertTitle>
                <AlertDescription>
                  Let's get back on track with a quick 15-minute workout today.
                </AlertDescription>
              </Box>
            </Alert>
          )}
        </Box>

        {/* Quick Action Recommendations */}
        {personalization && (
          <Card bg="gradient.blue" color="white">
            <CardBody>
              <VStack align="start" gap={3}>
                <HStack>
                  <FiTarget size={20} />
                  <Heading size="md">Recommended for You</Heading>
                </HStack>
                <Text>
                  Based on your patterns, try a <strong>{personalization.recommendedWorkoutType}</strong> session
                  for <strong>{personalization.recommendedDuration} minutes</strong> today.
                </Text>
                <Button colorScheme="whiteAlpha" size="sm">
                  Generate Recommended Workout
                </Button>
              </VStack>
            </CardBody>
          </Card>
        )}

        {/* Weekly Goals Progress */}
        <Card>
          <CardBody>
            <VStack align="stretch" gap={4}>
              <HStack>
                <FiCalendar />
                <Heading size="md">Weekly Goals</Heading>
              </HStack>
              <SimpleGrid columns={{ base: 1, md: 3 }} spacing={4}>
                {weeklyGoals.map((goal) => {
                  const status = getGoalStatus(goal);
                  return (
                    <Box key={goal.type} p={4} bg="gray.50" borderRadius="md">
                      <VStack align="start" gap={2}>
                        <HStack justifyContent="space-between" w="full">
                          <Text fontWeight="semibold" textTransform="capitalize">
                            {goal.type}
                          </Text>
                          <Badge colorScheme={status.color} variant="subtle">
                            {status.message}
                          </Badge>
                        </HStack>
                        <Text fontSize="sm" color="gray.600">
                          {goal.current} / {goal.target} {goal.unit}
                        </Text>
                        <Progress
                          value={getGoalProgress(goal)}
                          colorScheme={goal.color}
                          borderRadius="full"
                          w="full"
                        />
                      </VStack>
                    </Box>
                  );
                })}
              </SimpleGrid>
            </VStack>
          </CardBody>
        </Card>

        {/* Next Milestone */}
        {personalization && (
          <Card>
            <CardBody>
              <HStack gap={3}>
                <FiTrendingUp color="#4299e1" size={20} />
                <VStack align="start" gap={1}>
                  <Text fontWeight="semibold">Next Milestone</Text>
                  <Text color="gray.600">{personalization.nextMilestone}</Text>
                </VStack>
              </HStack>
            </CardBody>
          </Card>
        )}

        {/* Gamification Stats */}
        {gamificationStats && (
          <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }} gap={6}>
            <QuickStats
              level={gamificationStats.level}
              totalPoints={gamificationStats.totalPoints}
              nextLevelPoints={gamificationStats.level * 100}
            />
            <StreakDisplay
              streak={gamificationStats.streaks.daily}
              title="Daily Streak"
              color="orange"
            />
            <StreakDisplay
              streak={gamificationStats.streaks.weekly}
              title="Weekly Consistency"
              color="blue"
            />
          </Grid>
        )}

        {/* Personalized Tips */}
        {personalization && personalization.personalizedTips.length > 0 && (
          <Card>
            <CardBody>
              <VStack align="stretch" gap={3}>
                <Heading size="md">Personalized Tips</Heading>
                {personalization.personalizedTips.map((tip, index) => (
                  <Box key={index} p={3} bg="blue.50" borderRadius="md" borderLeft="4px solid" borderColor="blue.400">
                    <Text color="blue.700">{tip}</Text>
                  </Box>
                ))}
              </VStack>
            </CardBody>
          </Card>
        )}

        {/* Engagement Insights */}
        {engagementProfile && (
          <Card>
            <CardBody>
              <VStack align="stretch" gap={4}>
                <HStack>
                  <FiBarChart2 />
                  <Heading size="md">Your Progress</Heading>
                  <Badge colorScheme="purple" variant="outline">
                    Engagement Score: {engagementProfile.engagementScore}/100
                  </Badge>
                </HStack>

                <SimpleGrid columns={{ base: 2, md: 4 }} spacing={4}>
                  <Box textAlign="center">
                    <Text fontSize="2xl" fontWeight="bold" color="blue.600">
                      {engagementProfile.totalSessions}
                    </Text>
                    <Text fontSize="sm" color="gray.600">Total Sessions</Text>
                  </Box>

                  <Box textAlign="center">
                    <Text fontSize="2xl" fontWeight="bold" color="green.600">
                      {Math.round(engagementProfile.averageSessionDuration)}m
                    </Text>
                    <Text fontSize="sm" color="gray.600">Avg Session</Text>
                  </Box>

                  <Box textAlign="center">
                    <Text fontSize="2xl" fontWeight="bold" color="orange.600">
                      {engagementProfile.workoutsCompleted}
                    </Text>
                    <Text fontSize="sm" color="gray.600">Completed</Text>
                  </Box>

                  <Box textAlign="center">
                    <Text fontSize="2xl" fontWeight="bold" color="purple.600">
                      {engagementProfile.aiInteractions}
                    </Text>
                    <Text fontSize="sm" color="gray.600">AI Chats</Text>
                  </Box>
                </SimpleGrid>
              </VStack>
            </CardBody>
          </Card>
        )}

        {/* Enhanced Tabs for Different Views */}
        <Tabs variant="soft-rounded" colorScheme="blue">
          <TabList>
            <Tab><FiBarChart2 style={{ marginRight: '8px' }} />Analytics</Tab>
            <Tab><FiUsers style={{ marginRight: '8px' }} />Community</Tab>
          </TabList>

          <TabPanels>
            <TabPanel px={0}>
              <AnalyticsDashboard gamificationStats={gamificationStats} />
            </TabPanel>

            <TabPanel px={0}>
              <SocialFeatures />
            </TabPanel>
          </TabPanels>
        </Tabs>

        {/* Recent Badges */}
        {gamificationStats && gamificationStats.badges.length > 0 && (
          <Card>
            <CardBody>
              <VStack align="stretch" gap={4}>
                <Heading size="md">Recent Achievements</Heading>
                <BadgeGrid
                  badges={gamificationStats.badges.slice(0, 6)}
                  showProgress={true}
                />
                {gamificationStats.badges.length > 6 && (
                  <Button variant="outline" size="sm" alignSelf="center">
                    View All Achievements
                  </Button>
                )}
              </VStack>
            </CardBody>
          </Card>
        )}

        {/* Quick Actions */}
        <SimpleGrid columns={{ base: 2, md: 4 }} spacing={4}>
          <Button
            leftIcon={<FiTarget />}
            colorScheme="blue"
            variant="outline"
            onClick={() => engagementTracker.trackFeatureUse('generate_workout', 'dashboard')}
          >
            New Workout
          </Button>

          <Button
            leftIcon={<FiClock />}
            colorScheme="green"
            variant="outline"
            onClick={() => engagementTracker.trackFeatureUse('quick_workout', 'dashboard')}
          >
            Quick 15min
          </Button>

          <Button
            leftIcon={<FiBarChart2 />}
            colorScheme="purple"
            variant="outline"
            onClick={() => engagementTracker.trackFeatureUse('view_progress', 'dashboard')}
          >
            Progress
          </Button>

          <Button
            leftIcon={<FiUsers />}
            colorScheme="orange"
            variant="outline"
            onClick={() => engagementTracker.trackFeatureUse('community', 'dashboard')}
          >
            Community
          </Button>
        </SimpleGrid>
      </VStack>
    </MobileLayout>
  );
};

export default PersonalizedDashboardPage;
