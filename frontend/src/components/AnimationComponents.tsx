import { Box } from '@chakra-ui/react';
import React from 'react';

// Enhanced Button with micro-interactions
interface AnimatedButtonProps {
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'success' | 'warning';
  size?: 'sm' | 'md' | 'lg';
  onClick?: () => void;
  disabled?: boolean;
  loading?: boolean;
}

export const AnimatedButton: React.FC<AnimatedButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  onClick,
  disabled = false,
  loading = false,
}) => {
  const getVariantStyles = () => {
    switch (variant) {
      case 'primary':
        return {
          bg: 'blue.500',
          color: 'white',
          _hover: { bg: 'blue.600', transform: 'translateY(-1px)' },
        };
      case 'secondary':
        return {
          bg: 'gray.200',
          color: 'gray.700',
          _hover: { bg: 'gray.300', transform: 'translateY(-1px)' },
        };
      case 'success':
        return {
          bg: 'green.500',
          color: 'white',
          _hover: { bg: 'green.600', transform: 'translateY(-1px)' },
        };
      case 'warning':
        return {
          bg: 'orange.500',
          color: 'white',
          _hover: { bg: 'orange.600', transform: 'translateY(-1px)' },
        };
      default:
        return {
          bg: 'blue.500',
          color: 'white',
          _hover: { bg: 'blue.600', transform: 'translateY(-1px)' },
        };
    }
  };

  const getSizeStyles = () => {
    switch (size) {
      case 'sm':
        return { px: 3, py: 2, fontSize: 'sm' };
      case 'lg':
        return { px: 6, py: 4, fontSize: 'lg' };
      default:
        return { px: 4, py: 3, fontSize: 'md' };
    }
  };

  return (
    <Box
      as="button"
      {...getVariantStyles()}
      {...getSizeStyles()}
      borderRadius="md"
      border="none"
      cursor={disabled ? 'not-allowed' : 'pointer'}
      opacity={disabled ? 0.6 : 1}
      position="relative"
      overflow="hidden"
      onClick={disabled ? undefined : onClick}
      fontWeight="medium"
      transition="all 0.2s ease"
      _active={{ transform: disabled ? 'none' : 'translateY(0) scale(0.98)' }}
      boxShadow="sm"
      _hover={{
        ...getVariantStyles()._hover,
        boxShadow: disabled ? 'sm' : 'md',
      }}
    >
      {loading && (
        <Box
          position="absolute"
          top={0}
          left={0}
          right={0}
          bottom={0}
          bg="rgba(255,255,255,0.2)"
          display="flex"
          alignItems="center"
          justifyContent="center"
        >
          <Box
            w={4}
            h={4}
            border="2px solid"
            borderColor="transparent"
            borderTopColor="currentColor"
            borderRadius="full"
            animation="spin 1s linear infinite"
          />
        </Box>
      )}
      {children}
    </Box>
  );
};

// Card with hover effects
interface AnimatedCardProps {
  children: React.ReactNode;
  onClick?: () => void;
  elevation?: 'low' | 'medium' | 'high';
}

export const AnimatedCard: React.FC<AnimatedCardProps> = ({
  children,
  onClick,
  elevation = 'medium',
}) => {
  const getElevationStyles = () => {
    switch (elevation) {
      case 'low':
        return {
          boxShadow: 'sm',
          _hover: { boxShadow: 'md', transform: 'translateY(-2px)' },
        };
      case 'high':
        return {
          boxShadow: 'lg',
          _hover: { boxShadow: 'xl', transform: 'translateY(-2px)' },
        };
      default:
        return {
          boxShadow: 'md',
          _hover: { boxShadow: 'lg', transform: 'translateY(-2px)' },
        };
    }
  };

  return (
    <Box
      bg="white"
      borderRadius="lg"
      p={6}
      cursor={onClick ? 'pointer' : 'default'}
      onClick={onClick}
      transition="all 0.2s ease"
      {...getElevationStyles()}
    >
      {children}
    </Box>
  );
};

// Progress indicator with animation
interface AnimatedProgressProps {
  value: number;
  max: number;
  color?: string;
  showValue?: boolean;
}

export const AnimatedProgress: React.FC<AnimatedProgressProps> = ({
  value,
  max,
  color = 'blue.500',
  showValue = true,
}) => {
  const percentage = Math.min((value / max) * 100, 100);

  return (
    <Box>
      <Box
        h="8px"
        bg="gray.200"
        borderRadius="full"
        overflow="hidden"
        position="relative"
      >
        <Box
          h="full"
          bg={color}
          borderRadius="full"
          width={`${percentage}%`}
          transition="width 0.8s ease-out"
          position="relative"
        />
      </Box>
      {showValue && (
        <Box
          textAlign="center"
          mt={2}
          fontSize="sm"
          fontWeight="medium"
          opacity={0}
          animation="fadeIn 0.5s ease 0.5s forwards"
        >
          {value} / {max}
        </Box>
      )}
    </Box>
  );
};

// Achievement badge with celebration animation
interface AnimatedBadgeProps {
  title: string;
  description?: string;
  icon?: React.ReactNode;
  variant?: 'bronze' | 'silver' | 'gold' | 'platinum';
  isNew?: boolean;
}

export const AnimatedBadge: React.FC<AnimatedBadgeProps> = ({
  title,
  description,
  icon,
  variant = 'bronze',
  isNew = false,
}) => {
  const getVariantStyles = () => {
    switch (variant) {
      case 'silver':
        return {
          bg: 'linear-gradient(135deg, #C4C4C4, #E8E8E8)',
          color: 'gray.700',
          borderColor: 'gray.300',
        };
      case 'gold':
        return {
          bg: 'linear-gradient(135deg, #FFD700, #FFA500)',
          color: 'yellow.900',
          borderColor: 'yellow.400',
        };
      case 'platinum':
        return {
          bg: 'linear-gradient(135deg, #E5E4E2, #BCC6CC)',
          color: 'gray.800',
          borderColor: 'gray.400',
        };
      default:
        return {
          bg: 'linear-gradient(135deg, #CD7F32, #A0522D)',
          color: 'orange.100',
          borderColor: 'orange.400',
        };
    }
  };

  return (
    <Box
      p={4}
      borderRadius="lg"
      border="2px solid"
      position="relative"
      textAlign="center"
      minW="120px"
      transition="all 0.2s ease"
      _hover={{ transform: 'scale(1.05)' }}
      animation={isNew ? 'pulse 2s infinite' : 'bounceIn 0.5s ease-out'}
      {...getVariantStyles()}
    >
      {isNew && (
        <Box
          position="absolute"
          top="-8px"
          right="-8px"
          bg="red.500"
          color="white"
          borderRadius="full"
          fontSize="xs"
          px={2}
          py={1}
          fontWeight="bold"
          animation="bounceIn 0.5s ease-out"
        >
          NEW!
        </Box>
      )}

      {icon && (
        <Box mb={2} display="flex" justifyContent="center">
          {icon}
        </Box>
      )}

      <Box fontSize="sm" fontWeight="bold" mb={1}>
        {title}
      </Box>

      {description && (
        <Box fontSize="xs" opacity={0.8}>
          {description}
        </Box>
      )}
    </Box>
  );
};

// Loading skeleton with shimmer effect
interface SkeletonLoaderProps {
  height?: string;
  width?: string;
  borderRadius?: string;
  count?: number;
}

export const SkeletonLoader: React.FC<SkeletonLoaderProps> = ({
  height = '20px',
  width = '100%',
  borderRadius = 'md',
  count = 1,
}) => {
  return (
    <>
      {Array.from({ length: count }).map((_, index) => (
        <Box
          key={index}
          height={height}
          width={width}
          bg="gray.200"
          borderRadius={borderRadius}
          position="relative"
          overflow="hidden"
          mb={count > 1 ? 2 : 0}
          _before={{
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            bg: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.6), transparent)',
            animation: 'shimmer 1.5s infinite',
          }}
        />
      ))}
    </>
  );
};

// Success/Error notification with slide-in animation
interface NotificationProps {
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
  isVisible: boolean;
  onClose?: () => void;
}

export const AnimatedNotification: React.FC<NotificationProps> = ({
  type,
  message,
  isVisible,
  onClose,
}) => {
  const getTypeStyles = () => {
    switch (type) {
      case 'success':
        return { bg: 'green.500', color: 'white' };
      case 'error':
        return { bg: 'red.500', color: 'white' };
      case 'warning':
        return { bg: 'orange.500', color: 'white' };
      default:
        return { bg: 'blue.500', color: 'white' };
    }
  };

  if (!isVisible) return null;

  return (
    <Box
      position="fixed"
      top="20px"
      right="20px"
      zIndex={1000}
      p={4}
      borderRadius="md"
      minW="300px"
      boxShadow="lg"
      animation="slideInRight 0.3s ease-out"
      {...getTypeStyles()}
    >
      <Box display="flex" justifyContent="space-between" alignItems="center">
        <Box>{message}</Box>
        {onClose && (
          <Box
            as="button"
            onClick={onClose}
            ml={4}
            fontSize="lg"
            fontWeight="bold"
            cursor="pointer"
            _hover={{ opacity: 0.7 }}
          >
            ×
          </Box>
        )}
      </Box>
    </Box>
  );
};

export default {
  AnimatedButton,
  AnimatedCard,
  AnimatedProgress,
  AnimatedBadge,
  SkeletonLoader,
  AnimatedNotification,
};
