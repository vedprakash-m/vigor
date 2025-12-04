import {
    Badge,
    Box,
    Button,
    HStack,
    Icon,
    Text,
    VStack,
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import { FiDownload, FiSmartphone, FiWifi, FiZap } from 'react-icons/fi';
import { Modal, ModalBody, ModalContent, ModalFooter, ModalHeader, ModalOverlay, useDisclosure, useToast } from './compat';

interface BeforeInstallPromptEvent extends Event {
  readonly platforms: string[];
  readonly userChoice: Promise<{
    outcome: 'accepted' | 'dismissed';
    platform: string;
  }>;
  prompt(): Promise<void>;
}

interface PWAInstallPromptProps {
  onInstall?: () => void;
  onDismiss?: () => void;
}

const PWAInstallPrompt: React.FC<PWAInstallPromptProps> = ({
  onInstall,
  onDismiss,
}) => {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isInstallable, setIsInstallable] = useState(false);
  const [isInstalled, setIsInstalled] = useState(false);
  const [showManualInstructions, setShowManualInstructions] = useState(false);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const toast = useToast();

  useEffect(() => {
    // Check if app is already installed
    const checkInstallation = () => {
      const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
      const isInWebapp = 'standalone' in window.navigator && (window.navigator as { standalone?: boolean }).standalone === true;
      setIsInstalled(isStandalone || isInWebapp);
    };

    // Listen for beforeinstallprompt event
    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
      setIsInstallable(true);

      // Show install prompt after user has completed first workout
      const hasCompletedWorkout = localStorage.getItem('vigor_first_workout_completed');
      if (hasCompletedWorkout && !isInstalled) {
        setTimeout(() => {
          onOpen();
        }, 2000); // Delay to avoid interrupting user flow
      }
    };

    // Listen for app installation
    const handleAppInstalled = () => {
      setIsInstalled(true);
      setIsInstallable(false);
      setDeferredPrompt(null);
      onClose();

      toast({
        title: 'Vigor Installed! 🎉',
        description: 'You can now access Vigor from your home screen.',
        status: 'success',
        duration: 5000,
        isClosable: true,
      });

      onInstall?.();
    };

    checkInstallation();

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    window.addEventListener('appinstalled', handleAppInstalled);

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
      window.removeEventListener('appinstalled', handleAppInstalled);
    };
  }, [isInstalled, onOpen, onClose, toast, onInstall]);

  const handleInstallClick = async () => {
    if (!deferredPrompt) {
      // Show manual instructions for browsers without native prompt
      setShowManualInstructions(true);
      return;
    }

    try {
      await deferredPrompt.prompt();
      const { outcome } = await deferredPrompt.userChoice;

      if (outcome === 'accepted') {
        setIsInstallable(false);
        setDeferredPrompt(null);
        onClose();
      } else {
        onDismiss?.();
      }
    } catch (error) {
      console.error('Error showing install prompt:', error);
      setShowManualInstructions(true);
    }
  };

  const handleDismiss = () => {
    onClose();
    onDismiss?.();

    // Don't show again for 7 days
    const dismissUntil = Date.now() + (7 * 24 * 60 * 60 * 1000);
    localStorage.setItem('vigor_install_dismissed_until', dismissUntil.toString());
  };

  // Don't show if dismissed recently
  const dismissedUntil = localStorage.getItem('vigor_install_dismissed_until');
  if (dismissedUntil && Date.now() < parseInt(dismissedUntil)) {
    return null;
  }

  // Don't show if already installed or not installable
  if (isInstalled || !isInstallable) {
    return null;
  }

  const InstallFeatures = () => (
    <VStack spacing={4} align="start">
      <HStack>
        <Icon as={FiSmartphone} color="blue.400" />
        <Box>
          <Text fontWeight="semibold">Native App Experience</Text>
          <Text fontSize="sm" color="gray.600">
            Full-screen experience without browser UI
          </Text>
        </Box>
      </HStack>

      <HStack>
        <Icon as={FiWifi} color="green.400" />
        <Box>
          <Text fontWeight="semibold">Offline Workouts</Text>
          <Text fontSize="sm" color="gray.600">
            Access workouts and track progress without internet
          </Text>
        </Box>
      </HStack>

      <HStack>
        <Icon as={FiZap} color="yellow.400" />
        <Box>
          <Text fontWeight="semibold">Push Notifications</Text>
          <Text fontSize="sm" color="gray.600">
            Get workout reminders and motivation
          </Text>
        </Box>
      </HStack>
    </VStack>
  );

  const ManualInstructions = () => {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isAndroid = /Android/.test(navigator.userAgent);

    return (
      <VStack spacing={4} align="start">
        <Text fontWeight="semibold">Install Vigor manually:</Text>

        {isIOS && (
          <Box p={4} bg="blue.50" borderRadius="md" borderWidth="1px" borderColor="blue.200">
            <Text fontSize="sm" fontWeight="semibold" mb={2}>On iOS Safari:</Text>
            <Text fontSize="sm">
              1. Tap the Share button (□↗) at the bottom<br/>
              2. Scroll down and tap "Add to Home Screen"<br/>
              3. Tap "Add" to install Vigor
            </Text>
          </Box>
        )}

        {isAndroid && (
          <Box p={4} bg="green.50" borderRadius="md" borderWidth="1px" borderColor="green.200">
            <Text fontSize="sm" fontWeight="semibold" mb={2}>On Android Chrome:</Text>
            <Text fontSize="sm">
              1. Tap the three dots menu (⋮) at the top right<br/>
              2. Tap "Add to Home screen"<br/>
              3. Tap "Add" to install Vigor
            </Text>
          </Box>
        )}

        {!isIOS && !isAndroid && (
          <Box p={4} bg="purple.50" borderRadius="md" borderWidth="1px" borderColor="purple.200">
            <Text fontSize="sm" fontWeight="semibold" mb={2}>On Desktop:</Text>
            <Text fontSize="sm">
              Look for an install icon in your browser's address bar,<br/>
              or check the browser menu for "Install Vigor" option.
            </Text>
          </Box>
        )}
      </VStack>
    );
  };

  return (
    <>
      {/* Install button in app header */}
      {isInstallable && !isOpen && (
        <Button
          size="sm"
          leftIcon={<FiDownload />}
          colorScheme="blue"
          variant="outline"
          onClick={onOpen}
          position="fixed"
          top={4}
          right={4}
          zIndex="banner"
          display={{ base: 'none', md: 'flex' }}
        >
          Install App
        </Button>
      )}

      {/* Install prompt modal */}
      <Modal isOpen={isOpen} onClose={handleDismiss} size="md" isCentered>
        <ModalOverlay bg="blackAlpha.300" backdropFilter="blur(10px)" />
        <ModalContent mx={4}>
          <ModalHeader>
            <HStack>
              <Icon as={FiDownload} color="blue.500" />
              <Box>
                <Text>Install Vigor App</Text>
                <Badge colorScheme="blue" variant="subtle">
                  Enhanced Experience
                </Badge>
              </Box>
            </HStack>
          </ModalHeader>

          <ModalBody>
            <VStack spacing={6}>
              <Text color="gray.600">
                Get the full Vigor experience with offline workouts, push notifications,
                and faster access to your fitness journey.
              </Text>

              {showManualInstructions ? <ManualInstructions /> : <InstallFeatures />}
            </VStack>
          </ModalBody>

          <ModalFooter>
            <HStack spacing={3}>
              <Button variant="ghost" onClick={handleDismiss}>
                Not Now
              </Button>
              {!showManualInstructions ? (
                <Button
                  colorScheme="blue"
                  leftIcon={<FiDownload />}
                  onClick={handleInstallClick}
                >
                  Install Now
                </Button>
              ) : (
                <Button colorScheme="blue" onClick={handleDismiss}>
                  Got It
                </Button>
              )}
            </HStack>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
};

export default PWAInstallPrompt;
