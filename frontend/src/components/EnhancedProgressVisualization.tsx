import {
    Box,
    Container,
    Grid,
    Heading,
    HStack,
    Text,
    VStack,
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import {
    FiActivity,
    FiAward,
    FiCalendar,
    FiTarget,
    FiTrendingUp,
    FiZap,
} from 'react-icons/fi';

interface ProgressMetric {
  id: string;
  label: string;
  value: number;
  maxValue: number;
  unit: string;
  trend: 'up' | 'down' | 'stable';
  change: number;
  color: string;
  icon: React.ElementType;
}

interface ChartData {
  date: string;
  value: number;
  label: string;
}

const EnhancedProgressVisualization: React.FC = () => {
  const [metrics, setMetrics] = useState<ProgressMetric[]>([]);
  const [weeklyData, setWeeklyData] = useState<ChartData[]>([]);
  const [monthlyGoals, setMonthlyGoals] = useState<ProgressMetric[]>([]);

  useEffect(() => {
    // Mock data - in real app, this would come from API
    const mockMetrics: ProgressMetric[] = [
      {
        id: 'workouts',
        label: 'Workouts This Week',
        value: 4,
        maxValue: 5,
        unit: 'sessions',
        trend: 'up',
        change: 25,
        color: 'blue.500',
        icon: FiActivity,
      },
      {
        id: 'streak',
        label: 'Current Streak',
        value: 12,
        maxValue: 30,
        unit: 'days',
        trend: 'up',
        change: 20,
        color: 'orange.500',
        icon: FiZap,
      },
      {
        id: 'calories',
        label: 'Calories Burned',
        value: 2845,
        maxValue: 3500,
        unit: 'kcal',
        trend: 'up',
        change: 15,
        color: 'red.500',
        icon: FiTrendingUp,
      },
      {
        id: 'duration',
        label: 'Total Duration',
        value: 185,
        maxValue: 250,
        unit: 'minutes',
        trend: 'stable',
        change: 0,
        color: 'green.500',
        icon: FiCalendar,
      },
    ];

    const mockWeeklyData: ChartData[] = [
      { date: 'Mon', value: 45, label: '45 min' },
      { date: 'Tue', value: 60, label: '60 min' },
      { date: 'Wed', value: 30, label: '30 min' },
      { date: 'Thu', value: 50, label: '50 min' },
      { date: 'Fri', value: 0, label: 'Rest' },
      { date: 'Sat', value: 75, label: '75 min' },
      { date: 'Sun', value: 40, label: '40 min' },
    ];

    const mockMonthlyGoals: ProgressMetric[] = [
      {
        id: 'monthly-workouts',
        label: 'Monthly Workout Goal',
        value: 16,
        maxValue: 20,
        unit: 'sessions',
        trend: 'up',
        change: 10,
        color: 'purple.500',
        icon: FiTarget,
      },
      {
        id: 'monthly-badges',
        label: 'Badges Earned',
        value: 3,
        maxValue: 5,
        unit: 'badges',
        trend: 'up',
        change: 50,
        color: 'yellow.500',
        icon: FiAward,
      },
    ];

    setMetrics(mockMetrics);
    setWeeklyData(mockWeeklyData);
    setMonthlyGoals(mockMonthlyGoals);
  }, []);

  const CircularProgress: React.FC<{
    value: number;
    maxValue: number;
    size: number;
    strokeWidth: number;
    color: string;
    children?: React.ReactNode;
  }> = ({ value, maxValue, size, strokeWidth, color, children }) => {
    const percentage = Math.min((value / maxValue) * 100, 100);
    const radius = (size - strokeWidth) / 2;
    const circumference = radius * 2 * Math.PI;
    const strokeDasharray = circumference;
    const strokeDashoffset = circumference - (percentage / 100) * circumference;

    return (
      <Box position="relative" display="inline-flex">
        <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
          {/* Background circle */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="#E2E8F0"
            strokeWidth={strokeWidth}
            fill="transparent"
          />
          {/* Progress circle */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={color}
            strokeWidth={strokeWidth}
            fill="transparent"
            strokeDasharray={strokeDasharray}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            style={{
              transition: 'stroke-dashoffset 0.8s ease-out',
            }}
          />
        </svg>
        {children && (
          <Box
            position="absolute"
            top="50%"
            left="50%"
            transform="translate(-50%, -50%)"
            textAlign="center"
          >
            {children}
          </Box>
        )}
      </Box>
    );
  };

  const BarChart: React.FC<{ data: ChartData[] }> = ({ data }) => {
    const maxValue = Math.max(...data.map(d => d.value));

    return (
      <HStack alignItems="end" gap={2} h="120px" px={4}>
        {data.map((item, index) => (
          <VStack key={index} gap={2} flex={1}>
            <Box
              bg={item.value > 0 ? 'blue.500' : 'gray.200'}
              h={item.value > 0 ? `${(item.value / maxValue) * 80}px` : '4px'}
              w="full"
              borderRadius="sm"
              position="relative"
              transition="height 0.8s ease-out"
              _hover={{
                bg: item.value > 0 ? 'blue.600' : 'gray.300',
                transform: 'scale(1.05)',
              }}
            >
              {item.value > 0 && (
                <Text
                  position="absolute"
                  top="-25px"
                  left="50%"
                  transform="translateX(-50%)"
                  fontSize="xs"
                  fontWeight="bold"
                  color="gray.600"
                >
                  {item.label}
                </Text>
              )}
            </Box>
            <Text fontSize="xs" fontWeight="medium" color="gray.600">
              {item.date}
            </Text>
          </VStack>
        ))}
      </HStack>
    );
  };

  const MetricCard: React.FC<{ metric: ProgressMetric }> = ({ metric }) => {
    const percentage = (metric.value / metric.maxValue) * 100;

    return (
      <Box
        p={6}
        bg="white"
        borderRadius="lg"
        border="1px solid"
        borderColor="gray.200"
        transition="all 0.2s ease"
        _hover={{
          transform: 'translateY(-2px)',
          boxShadow: 'lg',
        }}
      >
        <VStack alignItems="stretch" gap={4}>
          <HStack justifyContent="space-between">
            <VStack alignItems="start" gap={1}>
              <HStack>
                <Box color={metric.color}>
                  <metric.icon size={20} />
                </Box>
                <Text fontSize="sm" color="gray.600" fontWeight="medium">
                  {metric.label}
                </Text>
              </HStack>
              <HStack alignItems="baseline">
                <Text fontSize="2xl" fontWeight="bold">
                  {metric.value.toLocaleString()}
                </Text>
                <Text fontSize="sm" color="gray.500">
                  / {metric.maxValue.toLocaleString()} {metric.unit}
                </Text>
              </HStack>
            </VStack>

            <CircularProgress
              value={metric.value}
              maxValue={metric.maxValue}
              size={60}
              strokeWidth={6}
              color={metric.color}
            >
              <Text fontSize="xs" fontWeight="bold" color={metric.color}>
                {Math.round(percentage)}%
              </Text>
            </CircularProgress>
          </HStack>

          {/* Trend indicator */}
          {metric.change !== 0 && (
            <HStack fontSize="sm">
              <FiTrendingUp
                size={16}
                color={metric.trend === 'up' ? '#38A169' : '#E53E3E'}
                style={{
                  transform: metric.trend === 'down' ? 'rotate(180deg)' : 'none',
                }}
              />
              <Text
                color={metric.trend === 'up' ? 'green.500' : 'red.500'}
                fontWeight="medium"
              >
                {metric.change > 0 ? '+' : ''}{metric.change}% from last week
              </Text>
            </HStack>
          )}
        </VStack>
      </Box>
    );
  };

  return (
    <Container maxW="6xl" py={8}>
      <VStack gap={8} alignItems="stretch">
        {/* Header */}
        <Box>
          <Heading size="lg" mb={2}>Progress Overview</Heading>
          <Text color="gray.600">
            Track your fitness journey with detailed insights and trends
          </Text>
        </Box>

        {/* Weekly Metrics */}
        <Box>
          <Heading size="md" mb={4}>This Week</Heading>
          <Grid templateColumns="repeat(auto-fit, minmax(280px, 1fr))" gap={6}>
            {metrics.map((metric) => (
              <MetricCard key={metric.id} metric={metric} />
            ))}
          </Grid>
        </Box>

        {/* Weekly Activity Chart */}
        <Box
          p={6}
          bg="white"
          borderRadius="lg"
          border="1px solid"
          borderColor="gray.200"
        >
          <VStack alignItems="stretch" gap={4}>
            <HStack justifyContent="space-between">
              <Heading size="md">Weekly Activity</Heading>
              <Text fontSize="sm" color="gray.600">
                Workout duration (minutes)
              </Text>
            </HStack>
            <BarChart data={weeklyData} />
          </VStack>
        </Box>

        {/* Monthly Goals */}
        <Box>
          <Heading size="md" mb={4}>Monthly Goals</Heading>
          <Grid templateColumns="repeat(auto-fit, minmax(280px, 1fr))" gap={6}>
            {monthlyGoals.map((goal) => (
              <MetricCard key={goal.id} metric={goal} />
            ))}
          </Grid>
        </Box>

        {/* Achievement Progress */}
        <Box
          p={6}
          bg="gradient-to-r"
          borderRadius="lg"
          border="1px solid"
          borderColor="purple.200"
          position="relative"
          overflow="hidden"
        >
          <Box
            position="absolute"
            top={0}
            left={0}
            right={0}
            bottom={0}
            bg="linear-gradient(135deg, purple.500, blue.500)"
            opacity={0.1}
          />

          <VStack gap={4} position="relative" zIndex={1}>
            <Heading size="md" color="purple.700">
              Achievement Progress
            </Heading>

            <Grid templateColumns="repeat(auto-fit, minmax(200px, 1fr))" gap={4} w="full">
              <VStack>
                <CircularProgress
                  value={75}
                  maxValue={100}
                  size={80}
                  strokeWidth={8}
                  color="purple.500"
                >
                  <Text fontSize="lg" fontWeight="bold" color="purple.600">
                    75%
                  </Text>
                </CircularProgress>
                <Text textAlign="center" fontWeight="medium">
                  Form Master Badge
                </Text>
                <Text fontSize="sm" color="gray.600" textAlign="center">
                  15 more perfect form workouts needed
                </Text>
              </VStack>

              <VStack>
                <CircularProgress
                  value={12}
                  maxValue={30}
                  size={80}
                  strokeWidth={8}
                  color="orange.500"
                >
                  <Text fontSize="lg" fontWeight="bold" color="orange.600">
                    40%
                  </Text>
                </CircularProgress>
                <Text textAlign="center" fontWeight="medium">
                  Consistency Champion
                </Text>
                <Text fontSize="sm" color="gray.600" textAlign="center">
                  18 more consecutive days
                </Text>
              </VStack>

              <VStack>
                <CircularProgress
                  value={8}
                  maxValue={10}
                  size={80}
                  strokeWidth={8}
                  color="green.500"
                >
                  <Text fontSize="lg" fontWeight="bold" color="green.600">
                    80%
                  </Text>
                </CircularProgress>
                <Text textAlign="center" fontWeight="medium">
                  Equipment Explorer
                </Text>
                <Text fontSize="sm" color="gray.600" textAlign="center">
                  Try 2 more equipment types
                </Text>
              </VStack>
            </Grid>
          </VStack>
        </Box>
      </VStack>
    </Container>
  );
};

export default EnhancedProgressVisualization;
