import {
    Box,
    Button,
    Heading,
    HStack,
    IconButton,
    Portal,
    Text,
    VStack,
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import { FiChevronLeft, FiChevronRight, FiHelpCircle, FiX } from 'react-icons/fi';

interface TourStep {
  id: string;
  target: string; // CSS selector for the element to highlight
  title: string;
  content: string;
  placement?: 'top' | 'bottom' | 'left' | 'right';
  action?: () => void;
}

interface GuidedTourProps {
  steps: TourStep[];
  isActive: boolean;
  onComplete: () => void;
  onSkip: () => void;
}

export const GuidedTour: React.FC<GuidedTourProps> = ({
  steps,
  isActive,
  onComplete,
  onSkip
}) => {
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [targetElement, setTargetElement] = useState<HTMLElement | null>(null);

  const currentStep = steps[currentStepIndex];

  useEffect(() => {
    if (!isActive || !currentStep) return;

    const element = document.querySelector(currentStep.target) as HTMLElement;
    if (element) {
      setTargetElement(element);
      // Scroll element into view
      element.scrollIntoView({ behavior: 'smooth', block: 'center' });
      // Add highlight class
      element.classList.add('tour-highlight');
    }

    return () => {
      if (element) {
        element.classList.remove('tour-highlight');
      }
    };
  }, [currentStep, isActive]);

  const handleNext = () => {
    if (currentStep.action) {
      currentStep.action();
    }

    if (currentStepIndex < steps.length - 1) {
      setCurrentStepIndex(currentStepIndex + 1);
    } else {
      onComplete();
    }
  };

  const handlePrevious = () => {
    if (currentStepIndex > 0) {
      setCurrentStepIndex(currentStepIndex - 1);
    }
  };

  const getTooltipPosition = () => {
    if (!targetElement) return { top: 0, left: 0 };

    const rect = targetElement.getBoundingClientRect();
    const placement = currentStep.placement || 'bottom';

    switch (placement) {
      case 'top':
        return {
          top: rect.top - 10,
          left: rect.left + rect.width / 2,
          transform: 'translate(-50%, -100%)'
        };
      case 'bottom':
        return {
          top: rect.bottom + 10,
          left: rect.left + rect.width / 2,
          transform: 'translate(-50%, 0)'
        };
      case 'left':
        return {
          top: rect.top + rect.height / 2,
          left: rect.left - 10,
          transform: 'translate(-100%, -50%)'
        };
      case 'right':
        return {
          top: rect.top + rect.height / 2,
          left: rect.right + 10,
          transform: 'translate(0, -50%)'
        };
      default:
        return {
          top: rect.bottom + 10,
          left: rect.left + rect.width / 2,
          transform: 'translate(-50%, 0)'
        };
    }
  };

  if (!isActive || !currentStep) return null;

  return (
    <>
      {/* Overlay */}
      <Box
        position="fixed"
        top={0}
        left={0}
        right={0}
        bottom={0}
        bg="rgba(0, 0, 0, 0.5)"
        zIndex={9998}
        pointerEvents="auto"
      />

      {/* Tooltip */}
      <Portal>
        <Box
          position="fixed"
          {...getTooltipPosition()}
          zIndex={9999}
          bg="white"
          borderRadius="lg"
          boxShadow="xl"
          border="1px solid"
          borderColor="gray.200"
          p={4}
          maxW="320px"
          minW="280px"
        >
          <VStack alignItems="stretch" gap={3}>
            {/* Header */}
            <HStack justifyContent="space-between">
              <Heading size="sm">{currentStep.title}</Heading>
              <IconButton
                aria-label="Close tour"
                size="sm"
                variant="ghost"
                onClick={onSkip}
              >
                <FiX />
              </IconButton>
            </HStack>

            {/* Content */}
            <Text fontSize="sm" color="gray.600">
              {currentStep.content}
            </Text>

            {/* Progress */}
            <Box>
              <Text fontSize="xs" color="gray.500" mb={2}>
                Step {currentStepIndex + 1} of {steps.length}
              </Text>
              <Box
                w="full"
                h="2px"
                bg="gray.200"
                borderRadius="full"
                overflow="hidden"
              >
                <Box
                  h="full"
                  bg="blue.400"
                  w={`${((currentStepIndex + 1) / steps.length) * 100}%`}
                  transition="width 0.3s ease"
                />
              </Box>
            </Box>

            {/* Actions */}
            <HStack justifyContent="space-between">
              <Button
                size="sm"
                variant="ghost"
                onClick={handlePrevious}
                disabled={currentStepIndex === 0}
              >
                <FiChevronLeft style={{ marginRight: '4px' }} />
                Previous
              </Button>
              <HStack gap={2}>
                <Button size="sm" variant="ghost" onClick={onSkip}>
                  Skip Tour
                </Button>
                <Button
                  size="sm"
                  colorScheme="blue"
                  onClick={handleNext}
                >
                  {currentStepIndex === steps.length - 1 ? 'Finish' : 'Next'}
                  {currentStepIndex !== steps.length - 1 && <FiChevronRight style={{ marginLeft: '4px' }} />}
                </Button>
              </HStack>
            </HStack>
          </VStack>
        </Box>
      </Portal>

      <style>{`
        .tour-highlight {
          position: relative;
          z-index: 9999;
          box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.3);
          border-radius: 8px;
        }
      `}</style>
    </>
  );
};

// Contextual Help Component
interface HelpTriggerProps {
  title: string;
  content: string;
  placement?: 'top' | 'bottom' | 'left' | 'right';
  children?: React.ReactNode;
}

export const ContextualHelp: React.FC<HelpTriggerProps> = ({
  title,
  content,
  placement = 'top',
  children
}) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <Box position="relative" display="inline-block">
      <Box
        onClick={() => setIsOpen(!isOpen)}
        cursor="pointer"
        aria-label={`Help: ${title}`}
      >
        {children || (
          <IconButton
            aria-label="Help"
            size="sm"
            variant="ghost"
            colorScheme="gray"
          >
            <FiHelpCircle />
          </IconButton>
        )}
      </Box>

      {isOpen && (
        <>
          {/* Backdrop */}
          <Box
            position="fixed"
            top={0}
            left={0}
            right={0}
            bottom={0}
            zIndex={1000}
            onClick={() => setIsOpen(false)}
          />

          {/* Tooltip */}
          <Box
            position="absolute"
            top={placement === 'bottom' ? '100%' : placement === 'top' ? 'auto' : '50%'}
            bottom={placement === 'top' ? '100%' : 'auto'}
            left={placement === 'right' ? '100%' : placement === 'left' ? 'auto' : '50%'}
            right={placement === 'left' ? '100%' : 'auto'}
            transform={
              placement === 'top' || placement === 'bottom'
                ? 'translateX(-50%)'
                : 'translateY(-50%)'
            }
            mt={placement === 'bottom' ? 2 : 0}
            mb={placement === 'top' ? 2 : 0}
            ml={placement === 'right' ? 2 : 0}
            mr={placement === 'left' ? 2 : 0}
            zIndex={1001}
            bg="gray.800"
            color="white"
            borderRadius="md"
            p={3}
            boxShadow="lg"
            maxW="280px"
            minW="200px"
          >
            <VStack alignItems="start" gap={2}>
              <Text fontSize="sm" fontWeight="semibold">
                {title}
              </Text>
              <Text fontSize="xs" lineHeight="1.4">
                {content}
              </Text>
            </VStack>

            {/* Arrow */}
            <Box
              position="absolute"
              w={0}
              h={0}
              borderStyle="solid"
              {...{
                [placement === 'top' ? 'top' : placement === 'bottom' ? 'bottom' : placement === 'left' ? 'left' : 'right']: '100%',
                [placement === 'top' || placement === 'bottom' ? 'left' : 'top']: '50%',
                transform: placement === 'top' || placement === 'bottom'
                  ? 'translateX(-50%)'
                  : 'translateY(-50%)',
                borderWidth: placement === 'top'
                  ? '0 8px 8px 8px'
                  : placement === 'bottom'
                  ? '8px 8px 0 8px'
                  : placement === 'left'
                  ? '8px 8px 8px 0'
                  : '8px 0 8px 8px',
                borderColor: placement === 'top'
                  ? 'transparent transparent #2D3748 transparent'
                  : placement === 'bottom'
                  ? '#2D3748 transparent transparent transparent'
                  : placement === 'left'
                  ? 'transparent #2D3748 transparent transparent'
                  : 'transparent transparent transparent #2D3748'
              }}
            />
          </Box>
        </>
      )}
    </Box>
  );
};

// Predefined tour configurations
export const workoutGenerationTour: TourStep[] = [
  {
    id: 'workout-form',
    target: '[data-tour="workout-form"]',
    title: 'Create Your Workout',
    content: 'Use this form to customize your workout. Set duration, choose focus areas, and specify equipment.',
    placement: 'right'
  },
  {
    id: 'duration-slider',
    target: '[data-tour="duration-slider"]',
    title: 'Set Workout Duration',
    content: 'Adjust the slider to set how long you want your workout to be (15-90 minutes).',
    placement: 'top'
  },
  {
    id: 'focus-areas',
    target: '[data-tour="focus-areas"]',
    title: 'Choose Focus Areas',
    content: 'Select which muscle groups or workout types you want to target today.',
    placement: 'top'
  },
  {
    id: 'generate-button',
    target: '[data-tour="generate-button"]',
    title: 'Generate Workout',
    content: 'Click here to let our AI create a personalized workout plan for you!',
    placement: 'top'
  }
];

export const dashboardTour: TourStep[] = [
  {
    id: 'welcome',
    target: '[data-tour="dashboard-header"]',
    title: 'Welcome to Vigor!',
    content: 'This is your fitness dashboard. Here you can track progress, start workouts, and chat with your AI coach.',
    placement: 'bottom'
  },
  {
    id: 'streak',
    target: '[data-tour="streak-display"]',
    title: 'Track Your Streak',
    content: 'Your workout streak helps you stay motivated. Keep it going by completing workouts consistently!',
    placement: 'bottom'
  },
  {
    id: 'quick-actions',
    target: '[data-tour="quick-actions"]',
    title: 'Quick Actions',
    content: 'Use these buttons to quickly start a workout or chat with your AI coach.',
    placement: 'top'
  },
  {
    id: 'progress',
    target: '[data-tour="progress-overview"]',
    title: 'Progress Overview',
    content: 'Monitor your fitness journey with weekly stats and achievement badges.',
    placement: 'top'
  }
];

export const aiCoachTour: TourStep[] = [
  {
    id: 'chat-interface',
    target: '[data-tour="chat-interface"]',
    title: 'AI Coach Chat',
    content: 'Ask your AI coach anything about fitness, form, nutrition, or motivation.',
    placement: 'top'
  },
  {
    id: 'quick-replies',
    target: '[data-tour="quick-replies"]',
    title: 'Quick Replies',
    content: 'Use these common questions to get started, or type your own custom question.',
    placement: 'top'
  },
  {
    id: 'ai-provider',
    target: '[data-tour="ai-provider"]',
    title: 'AI Provider Info',
    content: 'See which AI model is powering your conversation for transparency and quality.',
    placement: 'left'
  }
];
