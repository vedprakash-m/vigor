import {
    Box,
    Badge as ChakraBadge,
    HStack,
    Progress,
    SimpleGrid,
    Text,
    Tooltip,
    VStack,
} from '@chakra-ui/react';
import React from 'react';
import { Badge, Streak } from '../services/gamificationService';

interface StreakDisplayProps {
  streak: Streak;
  title: string;
  color?: string;
}

export const StreakDisplay: React.FC<StreakDisplayProps> = ({
  streak,
  title,
  color = 'blue'
}) => {
  const getStreakEmoji = (current: number) => {
    if (current >= 30) return '🔥'
    if (current >= 14) return '⚡'
    if (current >= 7) return '💪'
    if (current >= 3) return '🌟'
    if (current >= 1) return '✨'
    return '💤'
  }

  const getStreakMessage = (current: number) => {
    if (current >= 30) return 'Legendary streak!'
    if (current >= 14) return 'On fire!'
    if (current >= 7) return 'Strong momentum!'
    if (current >= 3) return 'Building habits!'
    if (current >= 1) return 'Getting started!'
    return 'Ready to start?'
  }

  return (
    <Box
      p={4}
      bg={streak.isActive ? `${color}.50` : 'gray.50'}
      borderRadius="lg"
      border="1px solid"
      borderColor={streak.isActive ? `${color}.200` : 'gray.200'}
    >
      <VStack spacing={2} align="start">
        <HStack justify="space-between" w="full">
          <Text fontWeight="bold" color={`${color}.600`}>
            {title}
          </Text>
          <Text fontSize="2xl">
            {getStreakEmoji(streak.current)}
          </Text>
        </HStack>

        <HStack spacing={4} w="full">
          <VStack spacing={0} align="start">
            <Text fontSize="2xl" fontWeight="bold" color={`${color}.600`}>
              {streak.current}
            </Text>
            <Text fontSize="xs" color="gray.500">
              Current
            </Text>
          </VStack>

          <Box w="2px" h={8} bg="gray.200" />

          <VStack spacing={0} align="start">
            <Text fontSize="lg" fontWeight="semibold" color="gray.600">
              {streak.best}
            </Text>
            <Text fontSize="xs" color="gray.500">
              Best
            </Text>
          </VStack>
        </HStack>

        <Text fontSize="sm" color={`${color}.600`} fontWeight="medium">
          {getStreakMessage(streak.current)}
        </Text>

        {streak.current > 0 && (
          <Progress
            value={(streak.current / Math.max(streak.best, streak.current + 1)) * 100}
            colorScheme={color}
            size="sm"
            w="full"
            borderRadius="full"
          />
        )}
      </VStack>
    </Box>
  );
};

interface BadgeGridProps {
  badges: Badge[];
  maxDisplay?: number;
}

export const BadgeGrid: React.FC<BadgeGridProps> = ({ badges, maxDisplay = 6 }) => {
  const displayBadges = badges.slice(0, maxDisplay);

  return (
    <SimpleGrid columns={{ base: 2, md: 3 }} spacing={3}>
      {displayBadges.map((badge) => (
        <BadgeCard key={badge.id} badge={badge} />
      ))}
    </SimpleGrid>
  );
};

interface BadgeCardProps {
  badge: Badge;
  size?: 'sm' | 'md' | 'lg';
}

export const BadgeCard: React.FC<BadgeCardProps> = ({ badge, size = 'md' }) => {
  const isUnlocked = !!badge.unlockedAt;
  const hasProgress = !!badge.progress;

  const sizeProps = {
    sm: { iconSize: '24px', padding: 3 },
    md: { iconSize: '32px', padding: 4 },
    lg: { iconSize: '48px', padding: 6 },
  };

  return (
    <Tooltip
      label={
        <VStack spacing={1} align="start">
          <Text fontWeight="bold">{badge.name}</Text>
          <Text fontSize="sm">{badge.description}</Text>
          {hasProgress && (
            <Text fontSize="xs">
              Progress: {badge.progress!.current}/{badge.progress!.target}
            </Text>
          )}
          {isUnlocked && (
            <Text fontSize="xs" color="green.300">
              Unlocked: {new Date(badge.unlockedAt!).toLocaleDateString()}
            </Text>
          )}
        </VStack>
      }
      hasArrow
      placement="top"
    >
      <Box
        p={sizeProps[size].padding}
        bg={isUnlocked ? 'white' : 'gray.100'}
        borderRadius="lg"
        border="2px solid"
        borderColor={isUnlocked ? getBadgeColor(badge.category) : 'gray.300'}
        cursor="pointer"
        textAlign="center"
        opacity={isUnlocked ? 1 : 0.6}
        transform={isUnlocked ? 'scale(1)' : 'scale(0.95)'}
        transition="all 0.2s"
        _hover={{
          transform: isUnlocked ? 'scale(1.05)' : 'scale(1)',
          borderColor: isUnlocked ? `${getBadgeColor(badge.category)}.500` : 'gray.400',
        }}
      >
        <VStack spacing={2}>
          <Text fontSize={sizeProps[size].iconSize}>
            {badge.icon}
          </Text>

          <VStack spacing={1}>
            <Text fontSize="xs" fontWeight="bold" noOfLines={1}>
              {badge.name}
            </Text>

            <ChakraBadge
              size="sm"
              colorScheme={getBadgeColorScheme(badge.category)}
              variant={isUnlocked ? 'solid' : 'outline'}
            >
              {badge.category}
            </ChakraBadge>
          </VStack>

          {hasProgress && !isUnlocked && (
            <Progress
              value={(badge.progress!.current / badge.progress!.target) * 100}
              colorScheme={getBadgeColorScheme(badge.category)}
              size="xs"
              w="full"
              borderRadius="full"
            />
          )}
        </VStack>
      </Box>
    </Tooltip>
  );
};

interface QuickStatsProps {
  level: number;
  totalPoints: number;
  nextLevelPoints: number;
}

export const QuickStats: React.FC<QuickStatsProps> = ({
  level,
  totalPoints,
  nextLevelPoints
}) => {
  const pointsForNextLevel = nextLevelPoints - totalPoints;
  const progressToNextLevel = ((totalPoints % 100) / 100) * 100;

  return (
    <Box
      p={4}
      bg="gradient.to.r.from.blue.500.to.purple.600"
      bgGradient="linear(to-r, blue.500, purple.600)"
      borderRadius="lg"
      color="white"
    >
      <VStack spacing={3} align="start">
        <HStack justify="space-between" w="full">
          <VStack spacing={0} align="start">
            <Text fontSize="xs" opacity={0.8}>
              LEVEL
            </Text>
            <Text fontSize="2xl" fontWeight="bold">
              {level}
            </Text>
          </VStack>

          <VStack spacing={0} align="end">
            <Text fontSize="xs" opacity={0.8}>
              TOTAL POINTS
            </Text>
            <Text fontSize="lg" fontWeight="semibold">
              {totalPoints.toLocaleString()}
            </Text>
          </VStack>
        </HStack>

        <Box w="full">
          <HStack justify="space-between" mb={1}>
            <Text fontSize="xs" opacity={0.8}>
              NEXT LEVEL
            </Text>
            <Text fontSize="xs" opacity={0.8}>
              {pointsForNextLevel} points to go
            </Text>
          </HStack>

          <Progress
            value={progressToNextLevel}
            colorScheme="whiteAlpha"
            size="sm"
            borderRadius="full"
            bg="whiteAlpha.300"
          />
        </Box>
      </VStack>
    </Box>
  );
};

// Helper functions
const getBadgeColor = (category: Badge['category']): string => {
  switch (category) {
    case 'streak': return 'orange'
    case 'achievement': return 'green'
    case 'milestone': return 'purple'
    case 'exploration': return 'blue'
    default: return 'gray'
  }
}

const getBadgeColorScheme = (category: Badge['category']): string => {
  return getBadgeColor(category)
}

export default { StreakDisplay, BadgeGrid, BadgeCard, QuickStats };
