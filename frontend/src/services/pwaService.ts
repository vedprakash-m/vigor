// PWA Service Utilities
// Manages service worker registration, push notifications, and offline capabilities

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '';

interface NotificationOptions {
  title: string;
  body: string;
  icon?: string;
  badge?: string;
  tag?: string;
  url?: string;
  actions?: Array<{
    action: string;
    title: string;
    icon?: string;
  }>;
  requireInteraction?: boolean;
  timestamp?: number;
}

interface PWAServiceConfig {
  vapidPublicKey?: string;
  swPath?: string;
  enablePushNotifications?: boolean;
  enableBackgroundSync?: boolean;
}

class PWAService {
  private registration: ServiceWorkerRegistration | null = null;
  private subscription: PushSubscription | null = null;
  private config: PWAServiceConfig;

  constructor(config: PWAServiceConfig = {}) {
    this.config = {
      swPath: '/sw.js',
      enablePushNotifications: true,
      enableBackgroundSync: true,
      ...config,
    };
  }

  /**
   * Initialize PWA service - register service worker and set up notifications
   */
  async initialize(): Promise<boolean> {
    if (!('serviceWorker' in navigator)) {
      console.warn('Service Workers not supported');
      return false;
    }

    try {
      // Register service worker
      this.registration = await navigator.serviceWorker.register(this.config.swPath!);
      console.log('✅ Service Worker registered successfully');

      // Handle service worker updates
      this.handleServiceWorkerUpdates();

      // Request notification permission if enabled
      if (this.config.enablePushNotifications) {
        await this.requestNotificationPermission();
      }

      // Set up message listener for service worker communication
      this.setupMessageListener();

      return true;
    } catch (error) {
      console.error('❌ Service Worker registration failed:', error);
      return false;
    }
  }

  /**
   * Handle service worker updates and prompt user
   */
  private handleServiceWorkerUpdates(): void {
    if (!this.registration) return;

    this.registration.addEventListener('updatefound', () => {
      const newWorker = this.registration!.installing;
      if (!newWorker) return;

      newWorker.addEventListener('statechange', () => {
        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
          // New version available
          this.showUpdateNotification();
        }
      });
    });
  }

  /**
   * Show update notification to user
   */
  private showUpdateNotification(): void {
    if ('Notification' in window && Notification.permission === 'granted') {
      const notification = new Notification('Vigor Update Available! 🚀', {
        body: 'A new version of Vigor is ready. Restart to update.',
        icon: '/icons/vigor-icon-192x192.png',
        badge: '/icons/vigor-badge-72x72.png',
        tag: 'app-update',
        requireInteraction: true,
      });

      notification.onclick = () => {
        this.updateServiceWorker();
        notification.close();
      };
    }
  }

  /**
   * Update service worker and reload app
   */
  async updateServiceWorker(): Promise<void> {
    if (!this.registration || !this.registration.waiting) return;

    this.registration.waiting.postMessage({ type: 'SKIP_WAITING' });

    // Reload the page after service worker takes control
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      window.location.reload();
    });
  }

  /**
   * Request notification permission from user
   */
  async requestNotificationPermission(): Promise<boolean> {
    if (!('Notification' in window)) {
      console.warn('Notifications not supported');
      return false;
    }

    if (Notification.permission === 'granted') {
      return true;
    }

    if (Notification.permission === 'denied') {
      return false;
    }

    const permission = await Notification.requestPermission();
    return permission === 'granted';
  }

  /**
   * Subscribe to push notifications
   */
  async subscribeToPushNotifications(): Promise<PushSubscription | null> {
    if (!this.registration || !this.config.vapidPublicKey) {
      console.warn('Service Worker not registered or VAPID key missing');
      return null;
    }

    try {
      this.subscription = await this.registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.config.vapidPublicKey) as BufferSource,
      });

      console.log('✅ Push notification subscription successful');

      // Send subscription to backend
      await this.sendSubscriptionToBackend(this.subscription);

      return this.subscription;
    } catch (error) {
      console.error('❌ Push subscription failed:', error);
      return null;
    }
  }

  /**
   * Send push subscription to backend
   */
  async sendSubscriptionToBackend(subscription: PushSubscription): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/push/subscribe`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
        body: JSON.stringify({
          subscription: subscription.toJSON(),
          user_agent: navigator.userAgent,
          timestamp: new Date().toISOString(),
        }),
      });

      if (!response.ok) {
        throw new Error(`Failed to save subscription: ${response.statusText}`);
      }

      console.log('Push subscription saved to backend');
      return true;
    } catch (error) {
      console.error('Failed to send subscription to backend:', error);
      return false;
    }
  }

  /**
   * Show local notification
   */
  async showNotification(options: NotificationOptions): Promise<void> {
    if (!this.registration) {
      console.warn('Service Worker not registered');
      return;
    }

    const notificationOptions: NotificationOptions & {
      icon: string;
      badge: string;
      requireInteraction: boolean;
      timestamp: number;
    } = {
      icon: '/icons/vigor-icon-192x192.png',
      badge: '/icons/vigor-badge-72x72.png',
      requireInteraction: false,
      timestamp: Date.now(),
      ...options,
    };

    await this.registration.showNotification(options.title, notificationOptions);
  }

  /**
   * Schedule workout reminder notification
   */
  async scheduleWorkoutReminder(scheduledTime: Date, workoutType: string): Promise<void> {
    const now = new Date();
    const delay = scheduledTime.getTime() - now.getTime();

    if (delay <= 0) {
      console.warn('Cannot schedule notification in the past');
      return;
    }

    // Use setTimeout for near-term reminders (< 1 hour)
    if (delay < 60 * 60 * 1000) {
      setTimeout(() => {
        this.showNotification({
          title: 'Time for Your Workout! 💪',
          body: `Your ${workoutType} workout is ready. Let's get moving!`,
          tag: 'workout-reminder',
          url: '/workouts/generate',
          actions: [
            {
              action: 'start-workout',
              title: 'Start Workout',
            },
            {
              action: 'snooze',
              title: 'Remind me in 15 min',
            },
          ],
        });
      }, delay);
    } else {
      // For longer delays, store in IndexedDB and handle via service worker
      await this.storeScheduledNotification({
        scheduledTime,
        workoutType,
        type: 'workout-reminder',
      });
    }
  }

  /**
   * Cache workout for offline access
   */
  async cacheWorkoutForOffline(workoutId: string, workoutData: object): Promise<void> {
    if (!this.registration || !this.registration.active) return;

    this.registration.active.postMessage({
      type: 'CACHE_WORKOUT',
      data: {
        workoutId,
        workout: workoutData,
      },
    });
  }

  /**
   * Check if app is running offline
   */
  isOffline(): boolean {
    return !navigator.onLine;
  }

  /**
   * Get cached workouts for offline mode
   */
  async getCachedWorkouts(): Promise<unknown[]> {
    return new Promise((resolve) => {
      if (!this.registration || !this.registration.active) {
        resolve([]);
        return;
      }

      const messageChannel = new MessageChannel();
      messageChannel.port1.onmessage = (event) => {
        if (event.data.type === 'CACHED_WORKOUTS') {
          resolve(event.data.data);
        }
      };

      this.registration.active.postMessage(
        { type: 'GET_CACHED_WORKOUTS' },
        [messageChannel.port2]
      );
    });
  }

  /**
   * Set up message listener for service worker communication
   */
  private setupMessageListener(): void {
    navigator.serviceWorker.addEventListener('message', (event) => {
      const { type, data } = event.data;

      switch (type) {
        case 'NAVIGATE':
          // Handle navigation requests from service worker
          if (data?.url && window.location.pathname !== data.url) {
            window.history.pushState(null, '', data.url);
            window.dispatchEvent(new PopStateEvent('popstate'));
          }
          break;

        case 'WORKOUT_SYNCED':
          // Handle successful workout sync
          this.showNotification({
            title: 'Workout Synced! ✅',
            body: 'Your offline workout has been saved successfully.',
            tag: 'sync-success',
          });
          break;

        case 'SYNC_FAILED':
          // Handle sync failure
          console.error('Background sync failed:', data);
          break;
      }
    });
  }

  /**
   * Store scheduled notification in IndexedDB
   */
  private async storeScheduledNotification(notificationData: {
    scheduledTime: Date;
    workoutType: string;
    type: string;
  }): Promise<void> {
    // Implementation would use IndexedDB to store notifications
    // for service worker to process later
    console.log('Storing scheduled notification:', notificationData);
  }

  /**
   * Convert VAPID key to Uint8Array
   */
  private urlBase64ToUint8Array(base64String: string): Uint8Array {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }

    return outputArray;
  }

  /**
   * Get installation status
   */
  getInstallationStatus(): {
    isInstallable: boolean;
    isInstalled: boolean;
    canPrompt: boolean;
  } {
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
    const isInWebapp = 'standalone' in window.navigator &&
      (window.navigator as { standalone?: boolean }).standalone === true;

    return {
      isInstallable: 'beforeinstallprompt' in window,
      isInstalled: isStandalone || isInWebapp,
      canPrompt: !isStandalone && !isInWebapp,
    };
  }
}

// Export singleton instance
export const pwaService = new PWAService({
  vapidPublicKey: process.env.REACT_APP_VAPID_PUBLIC_KEY,
  enablePushNotifications: true,
  enableBackgroundSync: true,
});

// Helper functions for convenience
export const registerServiceWorker = () => pwaService.initialize();
export const setupPushNotifications = () => pwaService.subscribeToPushNotifications();
export const isPushNotificationSupported = () => 'PushManager' in window && 'serviceWorker' in navigator;
export const getInstallStatus = () => pwaService.getInstallationStatus();

export default PWAService;
