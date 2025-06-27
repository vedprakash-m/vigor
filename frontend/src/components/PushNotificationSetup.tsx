import {
    Box,
    Button,
    HStack,
    Text,
} from '@chakra-ui/react';
import React, { useEffect, useState } from 'react';
import { isPushNotificationSupported, pwaService, setupPushNotifications } from '../services/pwaService';

const PushNotificationSetup: React.FC = () => {
  const [showPrompt, setShowPrompt] = useState(false);
  const [permission, setPermission] = useState<NotificationPermission>('default');

  useEffect(() => {
    // Check if push notifications are supported and not already granted
    if (isPushNotificationSupported() && 'Notification' in window) {
      setPermission(Notification.permission);

      // Show prompt if permission is default and user has been active for 5 minutes
      if (Notification.permission === 'default') {
        const timer = setTimeout(() => {
          setShowPrompt(true);
        }, 5 * 60 * 1000); // 5 minutes

        return () => clearTimeout(timer);
      }
    }
  }, []);

  const handleEnableNotifications = async () => {
    try {
      const subscription = await setupPushNotifications();
      if (subscription) {
        setPermission('granted');
        setShowPrompt(false);

        // Send subscription to backend
        const backendSaved = await pwaService.sendSubscriptionToBackend(subscription);
        if (!backendSaved) {
          console.warn('Subscription not saved to backend, but notifications still work locally');
        }
      }
    } catch (error) {
      console.error('Failed to setup push notifications:', error);
    }
  };

  const handleDismiss = () => {
    setShowPrompt(false);
    // Don't show again for this session
    sessionStorage.setItem('notification-prompt-dismissed', 'true');
  };

  // Don't show if already dismissed this session
  if (sessionStorage.getItem('notification-prompt-dismissed')) {
    return null;
  }

  // Only show if supported, permission is default, and we should show prompt
  if (!isPushNotificationSupported() || permission !== 'default' || !showPrompt) {
    return null;
  }

  return (
    <Box
      bg="blue.50"
      border="1px solid"
      borderColor="blue.200"
      borderRadius="md"
      p={4}
      mb={4}
    >
      <HStack justifyContent="space-between" alignItems="center">
        <Text fontSize="sm" color="blue.800">
          Enable notifications to get workout reminders and celebrate your streaks!
        </Text>
        <HStack gap={2}>
          <Button size="sm" colorScheme="blue" onClick={handleEnableNotifications}>
            Enable
          </Button>
          <Button size="sm" variant="ghost" onClick={handleDismiss}>
            Dismiss
          </Button>
        </HStack>
      </HStack>
    </Box>
  );
};

export default PushNotificationSetup;
