import {
    Badge,
    Box,
    Button,
    Container,
    Grid,
    Heading,
    HStack,
    Text,
    VStack,
} from '@chakra-ui/react';
import React, { useState } from 'react';
import {
    FiCalendar,
    FiCamera,
    FiHeart,
    FiMessageSquare,
    FiMusic,
    FiTarget,
    FiTrendingUp,
    FiUsers,
    FiZap
} from 'react-icons/fi';

interface PremiumFeature {
  id: string;
  title: string;
  description: string;
  icon: React.ElementType;
  tier: 'basic' | 'premium' | 'elite';
  available: boolean;
}

const premiumFeatures: PremiumFeature[] = [
  {
    id: 'ai-nutrition',
    title: 'AI Nutrition Coaching',
    description: 'Personalized meal plans and nutrition guidance tailored to your goals',
    icon: FiTarget,
    tier: 'premium',
    available: false,
  },
  {
    id: 'advanced-analytics',
    title: 'Advanced Analytics',
    description: 'Deep insights into your performance trends and optimization suggestions',
    icon: FiTrendingUp,
    tier: 'premium',
    available: false,
  },
  {
    id: 'personal-trainer',
    title: '1-on-1 Virtual Trainer',
    description: 'Weekly video calls with certified personal trainers',
    icon: FiUsers,
    tier: 'elite',
    available: false,
  },
  {
    id: 'custom-music',
    title: 'Workout Playlist Creator',
    description: 'AI-curated music playlists that match your workout intensity',
    icon: FiMusic,
    tier: 'premium',
    available: false,
  },
  {
    id: 'form-analysis',
    title: 'AI Form Analysis',
    description: 'Real-time exercise form feedback using computer vision',
    icon: FiCamera,
    tier: 'elite',
    available: false,
  },
  {
    id: 'meal-planning',
    title: 'Smart Meal Planning',
    description: 'Automated grocery lists and meal prep schedules',
    icon: FiCalendar,
    tier: 'premium',
    available: false,
  },
  {
    id: 'community-plus',
    title: 'Premium Community',
    description: 'Access to exclusive challenges and expert-led groups',
    icon: FiMessageSquare,
    tier: 'premium',
    available: false,
  },
  {
    id: 'recovery-tracking',
    title: 'Advanced Recovery Metrics',
    description: 'Heart rate variability and sleep quality integration',
    icon: FiHeart,
    tier: 'elite',
    available: false,
  },
];

const PremiumFeatures: React.FC = () => {
  const [selectedTier, setSelectedTier] = useState<'basic' | 'premium' | 'elite'>('basic');

  const getTierColor = (tier: string) => {
    switch (tier) {
      case 'premium': return 'blue';
      case 'elite': return 'purple';
      default: return 'gray';
    }
  };

  const getTierPrice = (tier: string) => {
    switch (tier) {
      case 'premium': return '$9.99/month';
      case 'elite': return '$19.99/month';
      default: return 'Free';
    }
  };

  const getCurrentFeatures = () => {
    if (selectedTier === 'basic') {
      return ['Basic workout generation', 'AI coach chat', 'Progress tracking', 'Community access'];
    } else if (selectedTier === 'premium') {
      return [
        'Everything in Basic',
        'AI nutrition coaching',
        'Advanced analytics',
        'Custom music playlists',
        'Smart meal planning',
        'Premium community access',
      ];
    } else {
      return [
        'Everything in Premium',
        '1-on-1 virtual trainer sessions',
        'AI form analysis',
        'Advanced recovery metrics',
        'Priority support',
        'Beta feature access',
      ];
    }
  };

  return (
    <Container maxW="6xl" py={8}>
      <VStack gap={8} alignItems="stretch">
        {/* Header */}
        <Box textAlign="center">
          <HStack justifyContent="center" mb={4}>
            <FiTarget size={32} color="#FFD700" />
            <Heading size="xl">Vigor Premium</Heading>
          </HStack>
          <Text fontSize="lg" color="gray.600" maxW="2xl" mx="auto">
            Unlock advanced features and take your fitness journey to the next level with personalized coaching,
            detailed analytics, and exclusive community access.
          </Text>
        </Box>

        {/* Tier Selection */}
        <HStack justifyContent="center" gap={4}>
          {['basic', 'premium', 'elite'].map((tier) => (
            <Button
              key={tier}
              variant={selectedTier === tier ? 'solid' : 'outline'}
              colorScheme={getTierColor(tier)}
              onClick={() => setSelectedTier(tier as 'basic' | 'premium' | 'elite')}
              size="lg"
              minW="120px"
            >
              <VStack gap={1}>
                <Text fontWeight="bold" textTransform="capitalize">{tier}</Text>
                <Text fontSize="sm">{getTierPrice(tier)}</Text>
              </VStack>
            </Button>
          ))}
        </HStack>

        {/* Current Tier Features */}
        <Box
          p={6}
          bg={`${getTierColor(selectedTier)}.50`}
          borderRadius="xl"
          border="2px solid"
          borderColor={`${getTierColor(selectedTier)}.200`}
        >
          <VStack gap={4} alignItems="stretch">
            <HStack justifyContent="center">
              <Badge colorScheme={getTierColor(selectedTier)} size="lg" variant="solid">
                {selectedTier.toUpperCase()} PLAN
              </Badge>
            </HStack>

            <Text fontSize="3xl" fontWeight="bold" textAlign="center">
              {getTierPrice(selectedTier)}
            </Text>

            <VStack gap={2} alignItems="stretch">
              {getCurrentFeatures().map((feature, index) => (
                <HStack key={index}>
                  <FiZap color={getTierColor(selectedTier) === 'gray' ? '#68D391' : undefined} />
                  <Text>{feature}</Text>
                </HStack>
              ))}
            </VStack>

            {selectedTier !== 'basic' && (
              <Button
                colorScheme={getTierColor(selectedTier)}
                size="lg"
                w="full"
                disabled={true}
              >
                Coming Soon - Join Waitlist
              </Button>
            )}
          </VStack>
        </Box>

        {/* Premium Features Grid */}
        <Box>
          <Heading size="lg" mb={6} textAlign="center">
            Premium Features Preview
          </Heading>

          <Grid templateColumns="repeat(auto-fit, minmax(300px, 1fr))" gap={6}>
            {premiumFeatures.map((feature) => (
              <Box
                key={feature.id}
                p={6}
                borderRadius="lg"
                border="1px solid"
                borderColor="gray.200"
                position="relative"
                opacity={feature.available ? 1 : 0.7}
              >
                {/* Tier Badge */}
                <Badge
                  position="absolute"
                  top={3}
                  right={3}
                  colorScheme={getTierColor(feature.tier)}
                  variant="solid"
                  size="sm"
                >
                  {feature.tier.toUpperCase()}
                </Badge>

                <VStack alignItems="start" gap={4}>
                  <HStack>
                    <Box p={2} bg={`${getTierColor(feature.tier)}.100`} borderRadius="md">
                      <feature.icon size={24} />
                    </Box>
                    <Text fontWeight="bold" fontSize="lg">
                      {feature.title}
                    </Text>
                  </HStack>

                  <Text color="gray.600">
                    {feature.description}
                  </Text>

                  {!feature.available && (
                    <Badge colorScheme="orange" variant="outline">
                      Coming Soon
                    </Badge>
                  )}
                </VStack>
              </Box>
            ))}
          </Grid>
        </Box>

        {/* Upgrade CTA */}
        <Box
          p={8}
          bg="gradient-to-r"
          borderRadius="xl"
          textAlign="center"
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
            bg="linear-gradient(45deg, purple.500, blue.500)"
            opacity={0.1}
          />

          <VStack gap={4} position="relative" zIndex={1}>
            <HStack>
              <FiTarget size={32} />
              <Heading size="lg" color="purple.700">
                Ready to Transform Your Fitness?
              </Heading>
            </HStack>

            <Text fontSize="lg" maxW="2xl" mx="auto">
              Join thousands of users who have already unlocked their full potential with Vigor Premium.
              Start your free trial today and experience the difference.
            </Text>

            <HStack gap={4}>
              <Button colorScheme="purple" size="lg" disabled={true}>
                Start Free Trial
              </Button>
              <Button variant="outline" colorScheme="purple" size="lg">
                Learn More
              </Button>
            </HStack>

            <Text fontSize="sm" color="gray.500">
              Premium features coming Q2 2025
            </Text>
          </VStack>
        </Box>
      </VStack>
    </Container>
  );
};

export default PremiumFeatures;
