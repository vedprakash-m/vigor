import {
    Box,
    Card,
    CardBody,
    Container,
    Grid,
    Heading,
    HStack,
    Progress,
    SimpleGrid,
    Stat,
    StatArrow,
    StatHelpText,
    StatLabel,
    StatNumber,
    Tab,
    TabList,
    TabPanel,
    TabPanels,
    Tabs,
    Text,
    VStack,
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import { Bar, BarChart, CartesianGrid, Cell, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { type UserGamificationStats } from '../services/gamificationService';
import { workoutService } from '../services/workoutService';

interface AnalyticsData {
  weeklyProgress: Array<{
    week: string;
    workouts: number;
    duration: number;
    aiInteractions: number;
  }>;
  workoutTypeBreakdown: Array<{
    type: string;
    count: number;
    color: string;
  }>;
  performanceMetrics: {
    completionRate: number;
    averageDuration: number;
    consistencyScore: number;
    improvementTrend: number;
  };
  monthlyGoals: {
    workoutsTarget: number;
    workoutsCompleted: number;
    streakTarget: number;
    currentStreak: number;
  };
}

interface AnalyticsDashboardProps {
  gamificationStats?: UserGamificationStats;
}

const COLORS = ['#4299e1', '#38b2ac', '#ed8936', '#9f7aea', '#f56565', '#48bb78'];

export const AnalyticsDashboard: React.FC<AnalyticsDashboardProps> = ({ gamificationStats }) => {
  const [analyticsData, setAnalyticsData] = useState<AnalyticsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchAnalyticsData = async () => {
      try {
        setIsLoading(true);

        // Fetch workout data for analytics
        const workoutDays = await workoutService.getWorkoutDays();
        const recentWorkouts = workoutDays.slice(-12); // Last 12 weeks

        // Generate weekly progress data
        const weeklyProgress = [];
        for (let i = 0; i < 12; i++) {
          const weekStart = new Date();
          weekStart.setDate(weekStart.getDate() - (i * 7));
          const weekEnd = new Date(weekStart);
          weekEnd.setDate(weekEnd.getDate() + 6);

          const weekWorkouts = recentWorkouts.filter(date => {
            const workoutDate = new Date(date);
            return workoutDate >= weekStart && workoutDate <= weekEnd;
          });

          weeklyProgress.unshift({
            week: `Week ${12 - i}`,
            workouts: weekWorkouts.length,
            duration: weekWorkouts.length * 45, // Estimated average
            aiInteractions: Math.floor(weekWorkouts.length * 1.5), // Estimated
          });
        }

        // Workout type breakdown (simulated data)
        const workoutTypeBreakdown = [
          { type: 'Strength Training', count: Math.floor(recentWorkouts.length * 0.4), color: COLORS[0] },
          { type: 'Cardio', count: Math.floor(recentWorkouts.length * 0.3), color: COLORS[1] },
          { type: 'HIIT', count: Math.floor(recentWorkouts.length * 0.2), color: COLORS[2] },
          { type: 'Flexibility', count: Math.floor(recentWorkouts.length * 0.1), color: COLORS[3] },
        ];

        // Performance metrics calculation
        const totalWorkouts = recentWorkouts.length;
        const avgWorkoutsPerWeek = totalWorkouts / 12;
        const completionRate = Math.min(95, 75 + (avgWorkoutsPerWeek * 5)); // Simulated completion rate
        const averageDuration = 45; // minutes
        const consistencyScore = gamificationStats?.streaks.weekly.current || 0;
        const improvementTrend = avgWorkoutsPerWeek > 2 ? 12 : -5; // Positive if good frequency

        const performanceMetrics = {
          completionRate,
          averageDuration,
          consistencyScore,
          improvementTrend,
        };

        // Monthly goals
        const monthlyGoals = {
          workoutsTarget: 16, // 4 per week
          workoutsCompleted: Math.min(16, totalWorkouts),
          streakTarget: 7,
          currentStreak: gamificationStats?.streaks.daily.current || 0,
        };

        setAnalyticsData({
          weeklyProgress,
          workoutTypeBreakdown,
          performanceMetrics,
          monthlyGoals,
        });
      } catch (error) {
        console.error('Failed to fetch analytics data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchAnalyticsData();
  }, [gamificationStats]);

  if (isLoading || !analyticsData) {
    return (
      <Container maxW="container.xl" py={6}>
        <VStack gap={4}>
          <Heading size="lg">Analytics Dashboard</Heading>
          <Text>Loading your fitness insights...</Text>
        </VStack>
      </Container>
    );
  }

  const { weeklyProgress, workoutTypeBreakdown, performanceMetrics, monthlyGoals } = analyticsData;

  return (
    <Container maxW="container.xl" py={6}>
      <VStack gap={6} align="stretch">
        <Box>
          <Heading size="lg" mb={2}>Analytics Dashboard</Heading>
          <Text color="gray.600">
            Comprehensive insights into your fitness journey and progress patterns.
          </Text>
        </Box>

        {/* Key Performance Metrics */}
        <SimpleGrid columns={{ base: 2, md: 4 }} spacing={4}>
          <Stat bg="white" p={4} borderRadius="lg" boxShadow="sm">
            <StatLabel>Completion Rate</StatLabel>
            <StatNumber>{performanceMetrics.completionRate}%</StatNumber>
            <StatHelpText>
              <StatArrow type={performanceMetrics.completionRate > 80 ? 'increase' : 'decrease'} />
              {performanceMetrics.completionRate > 80 ? 'Excellent' : 'Improving'}
            </StatHelpText>
          </Stat>

          <Stat bg="white" p={4} borderRadius="lg" boxShadow="sm">
            <StatLabel>Avg Duration</StatLabel>
            <StatNumber>{performanceMetrics.averageDuration}min</StatNumber>
            <StatHelpText>
              <StatArrow type="increase" />
              Per workout
            </StatHelpText>
          </Stat>

          <Stat bg="white" p={4} borderRadius="lg" boxShadow="sm">
            <StatLabel>Consistency</StatLabel>
            <StatNumber>{performanceMetrics.consistencyScore}</StatNumber>
            <StatHelpText>
              <StatArrow type={performanceMetrics.consistencyScore > 3 ? 'increase' : 'decrease'} />
              Weekly streak
            </StatHelpText>
          </Stat>

          <Stat bg="white" p={4} borderRadius="lg" boxShadow="sm">
            <StatLabel>Improvement</StatLabel>
            <StatNumber>{performanceMetrics.improvementTrend > 0 ? '+' : ''}{performanceMetrics.improvementTrend}%</StatNumber>
            <StatHelpText>
              <StatArrow type={performanceMetrics.improvementTrend > 0 ? 'increase' : 'decrease'} />
              This month
            </StatHelpText>
          </Stat>
        </SimpleGrid>

        {/* Monthly Goals Progress */}
        <Card>
          <CardBody>
            <Heading size="md" mb={4}>Monthly Goals Progress</Heading>
            <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)' }} gap={6}>
              <Box>
                <HStack justifyContent="space-between" mb={2}>
                  <Text fontWeight="semibold">Workouts Completed</Text>
                  <Text fontSize="sm" color="gray.600">
                    {monthlyGoals.workoutsCompleted}/{monthlyGoals.workoutsTarget}
                  </Text>
                </HStack>
                <Progress
                  value={(monthlyGoals.workoutsCompleted / monthlyGoals.workoutsTarget) * 100}
                  colorScheme="blue"
                  borderRadius="full"
                />
              </Box>

              <Box>
                <HStack justifyContent="space-between" mb={2}>
                  <Text fontWeight="semibold">Streak Goal</Text>
                  <Text fontSize="sm" color="gray.600">
                    {Math.min(monthlyGoals.currentStreak, monthlyGoals.streakTarget)}/{monthlyGoals.streakTarget} days
                  </Text>
                </HStack>
                <Progress
                  value={(Math.min(monthlyGoals.currentStreak, monthlyGoals.streakTarget) / monthlyGoals.streakTarget) * 100}
                  colorScheme="orange"
                  borderRadius="full"
                />
              </Box>
            </Grid>
          </CardBody>
        </Card>

        {/* Analytics Tabs */}
        <Tabs variant="soft-rounded" colorScheme="blue">
          <TabList>
            <Tab>Progress Trends</Tab>
            <Tab>Workout Types</Tab>
            <Tab>Performance</Tab>
          </TabList>

          <TabPanels>
            {/* Progress Trends Tab */}
            <TabPanel>
              <Card>
                <CardBody>
                  <Heading size="md" mb={4}>12-Week Progress Trend</Heading>
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={weeklyProgress}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="week" />
                      <YAxis />
                      <Tooltip />
                      <Line
                        type="monotone"
                        dataKey="workouts"
                        stroke="#4299e1"
                        strokeWidth={2}
                        name="Workouts"
                      />
                      <Line
                        type="monotone"
                        dataKey="aiInteractions"
                        stroke="#38b2ac"
                        strokeWidth={2}
                        name="AI Interactions"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </CardBody>
              </Card>
            </TabPanel>

            {/* Workout Types Tab */}
            <TabPanel>
              <Grid templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)' }} gap={6}>
                <Card>
                  <CardBody>
                    <Heading size="md" mb={4}>Workout Type Distribution</Heading>
                    <ResponsiveContainer width="100%" height={250}>
                      <PieChart>
                        <Pie
                          data={workoutTypeBreakdown}
                          cx="50%"
                          cy="50%"
                          labelLine={false}
                          label={({ type, percent }) => `${type}: ${(percent * 100).toFixed(0)}%`}
                          outerRadius={80}
                          fill="#8884d8"
                          dataKey="count"
                        >
                          {workoutTypeBreakdown.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={entry.color} />
                          ))}
                        </Pie>
                        <Tooltip />
                      </PieChart>
                    </ResponsiveContainer>
                  </CardBody>
                </Card>

                <Card>
                  <CardBody>
                    <Heading size="md" mb={4}>Workout Type Frequency</Heading>
                    <ResponsiveContainer width="100%" height={250}>
                      <BarChart data={workoutTypeBreakdown}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="type" />
                        <YAxis />
                        <Tooltip />
                        <Bar dataKey="count" fill="#4299e1" />
                      </BarChart>
                    </ResponsiveContainer>
                  </CardBody>
                </Card>
              </Grid>
            </TabPanel>

            {/* Performance Tab */}
            <TabPanel>
              <Card>
                <CardBody>
                  <Heading size="md" mb={4}>Weekly Activity Overview</Heading>
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={weeklyProgress}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="week" />
                      <YAxis />
                      <Tooltip />
                      <Bar dataKey="duration" fill="#ed8936" name="Duration (min)" />
                    </BarChart>
                  </ResponsiveContainer>
                </CardBody>
              </Card>
            </TabPanel>
          </TabPanels>
        </Tabs>

        {/* Action Items */}
        <Card>
          <CardBody>
            <Heading size="md" mb={4}>Personalized Recommendations</Heading>
            <VStack gap={3} align="stretch">
              {performanceMetrics.consistencyScore < 3 && (
                <Box p={3} bg="orange.50" borderRadius="md" borderLeft="4px solid" borderColor="orange.400">
                  <Text fontWeight="semibold" color="orange.700">Improve Consistency</Text>
                  <Text color="orange.600" fontSize="sm">
                    Try setting workout reminders or scheduling shorter 20-minute sessions to build the habit.
                  </Text>
                </Box>
              )}

              {performanceMetrics.completionRate < 80 && (
                <Box p={3} bg="blue.50" borderRadius="md" borderLeft="4px solid" borderColor="blue.400">
                  <Text fontWeight="semibold" color="blue.700">Boost Completion Rate</Text>
                  <Text color="blue.600" fontSize="sm">
                    Consider adjusting workout difficulty or duration. Our AI coach can help customize your plans.
                  </Text>
                </Box>
              )}

              {monthlyGoals.workoutsCompleted >= monthlyGoals.workoutsTarget && (
                <Box p={3} bg="green.50" borderRadius="md" borderLeft="4px solid" borderColor="green.400">
                  <Text fontWeight="semibold" color="green.700">Outstanding Performance! 🎉</Text>
                  <Text color="green.600" fontSize="sm">
                    You've exceeded your monthly goal. Consider adding variety or intensity to keep progressing.
                  </Text>
                </Box>
              )}
            </VStack>
          </CardBody>
        </Card>
      </VStack>
    </Container>
  );
};

export default AnalyticsDashboard;
