/**
 * User Engagement Tracking Service
 * Tracks user interactions, time spent, and engagement patterns for analytics and UX optimization
 * Aligned with PRD analytics requirements and User Experience document
 */

export interface EngagementEvent {
  id: string;
  userId: string;
  eventType: 'page_view' | 'workout_start' | 'workout_complete' | 'ai_interaction' | 'feature_use' | 'session_start' | 'session_end' | 'session_pause' | 'session_resume';
  eventData: Record<string, any>;
  timestamp: string;
  sessionId: string;
  deviceType: 'mobile' | 'desktop' | 'tablet';
  userAgent: string;
}

export interface SessionData {
  sessionId: string;
  userId: string;
  startTime: string;
  endTime?: string;
  duration?: number;
  pageViews: number;
  interactions: number;
  workoutsStarted: number;
  workoutsCompleted: number;
  aiInteractions: number;
  deviceInfo: {
    type: 'mobile' | 'desktop' | 'tablet';
    userAgent: string;
    screenSize: { width: number; height: number };
  };
}

export interface EngagementMetrics {
  dailyActiveUsers: number;
  weeklyActiveUsers: number;
  monthlyActiveUsers: number;
  averageSessionDuration: number;
  bounceRate: number;
  workoutCompletionRate: number;
  featureAdoptionRates: Record<string, number>;
  userRetentionRates: {
    day1: number;
    day7: number;
    day30: number;
  };
}

export interface UserEngagementProfile {
  userId: string;
  totalSessions: number;
  totalTimeSpent: number; // minutes
  averageSessionDuration: number; // minutes
  workoutsStarted: number;
  workoutsCompleted: number;
  aiInteractions: number;
  favoriteFeatures: string[];
  lastActiveDate: string;
  engagementScore: number; // 0-100
  riskLevel: 'low' | 'medium' | 'high'; // churn risk
  personalizedRecommendations: string[];
}

class EngagementTrackingService {
  private currentSession: SessionData | null = null;
  private eventQueue: EngagementEvent[] = [];
  private isOnline = navigator.onLine;
  private syncInterval: NodeJS.Timeout | null = null;

  constructor() {
    this.setupEventListeners();
    this.startSession();
    this.setupAutoSync();
  }

  private setupEventListeners() {
    // Track online/offline status
    window.addEventListener('online', () => {
      this.isOnline = true;
      this.syncQueuedEvents();
    });

    window.addEventListener('offline', () => {
      this.isOnline = false;
    });

    // Track page visibility for session management
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        this.pauseSession();
      } else {
        this.resumeSession();
      }
    });

    // Track page unload for session end
    window.addEventListener('beforeunload', () => {
      this.endSession();
    });
  }

  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private generateEventId(): string {
    return `event_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private getDeviceType(): 'mobile' | 'desktop' | 'tablet' {
    const userAgent = navigator.userAgent.toLowerCase();
    const width = window.innerWidth;

    if (/mobile|android|iphone|ipod|blackberry|iemobile|opera mini/.test(userAgent)) {
      return 'mobile';
    } else if (width >= 768 && width <= 1024) {
      return 'tablet';
    } else {
      return 'desktop';
    }
  }

  private startSession() {
    const sessionId = this.generateSessionId();
    const userId = this.getCurrentUserId();

    this.currentSession = {
      sessionId,
      userId,
      startTime: new Date().toISOString(),
      pageViews: 0,
      interactions: 0,
      workoutsStarted: 0,
      workoutsCompleted: 0,
      aiInteractions: 0,
      deviceInfo: {
        type: this.getDeviceType(),
        userAgent: navigator.userAgent,
        screenSize: {
          width: window.innerWidth,
          height: window.innerHeight,
        },
      },
    };

    this.trackEvent('session_start', {
      deviceType: this.currentSession.deviceInfo.type,
      screenSize: this.currentSession.deviceInfo.screenSize,
    });
  }

  private pauseSession() {
    if (this.currentSession && !this.currentSession.endTime) {
      this.trackEvent('session_pause', {
        sessionDuration: Date.now() - new Date(this.currentSession.startTime).getTime(),
      });
    }
  }

  private resumeSession() {
    if (this.currentSession) {
      this.trackEvent('session_resume', {
        sessionId: this.currentSession.sessionId,
      });
    }
  }

  private endSession() {
    if (!this.currentSession) return;

    const endTime = new Date().toISOString();
    const duration = new Date(endTime).getTime() - new Date(this.currentSession.startTime).getTime();

    this.currentSession.endTime = endTime;
    this.currentSession.duration = Math.round(duration / 1000 / 60); // minutes

    this.trackEvent('session_end', {
      sessionDuration: this.currentSession.duration,
      totalPageViews: this.currentSession.pageViews,
      totalInteractions: this.currentSession.interactions,
      workoutsStarted: this.currentSession.workoutsStarted,
      workoutsCompleted: this.currentSession.workoutsCompleted,
      aiInteractions: this.currentSession.aiInteractions,
    });

    // Store session data locally
    this.storeSessionData(this.currentSession);
    this.currentSession = null;
  }

  private getCurrentUserId(): string {
    // Get user ID from auth context or localStorage
    const userData = localStorage.getItem('auth_user');
    if (userData) {
      try {
        const user = JSON.parse(userData);
        return user.id || 'anonymous';
      } catch {
        return 'anonymous';
      }
    }
    return 'anonymous';
  }

  private storeSessionData(session: SessionData) {
    try {
      const sessions = JSON.parse(localStorage.getItem('engagement_sessions') || '[]');
      sessions.push(session);

      // Keep only last 30 sessions to prevent storage bloat
      if (sessions.length > 30) {
        sessions.splice(0, sessions.length - 30);
      }

      localStorage.setItem('engagement_sessions', JSON.stringify(sessions));
    } catch (error) {
      console.warn('Failed to store session data:', error);
    }
  }

  private setupAutoSync() {
    // Sync every 5 minutes
    this.syncInterval = setInterval(() => {
      if (this.isOnline && this.eventQueue.length > 0) {
        this.syncQueuedEvents();
      }
    }, 5 * 60 * 1000);
  }

  public trackEvent(eventType: EngagementEvent['eventType'], eventData: Record<string, any> = {}) {
    if (!this.currentSession) return;

    const event: EngagementEvent = {
      id: this.generateEventId(),
      userId: this.currentSession.userId,
      eventType,
      eventData,
      timestamp: new Date().toISOString(),
      sessionId: this.currentSession.sessionId,
      deviceType: this.currentSession.deviceInfo.type,
      userAgent: this.currentSession.deviceInfo.userAgent,
    };

    // Update session counters
    switch (eventType) {
      case 'page_view':
        this.currentSession.pageViews++;
        break;
      case 'workout_start':
        this.currentSession.workoutsStarted++;
        break;
      case 'workout_complete':
        this.currentSession.workoutsCompleted++;
        break;
      case 'ai_interaction':
        this.currentSession.aiInteractions++;
        break;
      default:
        this.currentSession.interactions++;
    }

    // Queue event for sync
    this.eventQueue.push(event);

    // Store locally for offline capability
    this.storeEventLocally(event);

    // Try immediate sync if online and queue is getting large
    if (this.isOnline && this.eventQueue.length >= 10) {
      this.syncQueuedEvents();
    }
  }

  private storeEventLocally(event: EngagementEvent) {
    try {
      const events = JSON.parse(localStorage.getItem('engagement_events') || '[]');
      events.push(event);

      // Keep only last 100 events to prevent storage bloat
      if (events.length > 100) {
        events.splice(0, events.length - 100);
      }

      localStorage.setItem('engagement_events', JSON.stringify(events));
    } catch (error) {
      console.warn('Failed to store event locally:', error);
    }
  }

  private async syncQueuedEvents() {
    if (this.eventQueue.length === 0) return;

    try {
      const eventsToSync = [...this.eventQueue];

      // In a real implementation, this would send to analytics API
      console.log('Syncing engagement events:', eventsToSync);

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 100));

      // Clear synced events from queue
      this.eventQueue = [];

      console.log(`Successfully synced ${eventsToSync.length} engagement events`);
    } catch (error) {
      console.warn('Failed to sync engagement events:', error);
      // Events remain in queue for retry
    }
  }

  // Public methods for tracking specific events

  public trackPageView(pageName: string, additionalData: Record<string, any> = {}) {
    this.trackEvent('page_view', {
      pageName,
      path: window.location.pathname,
      referrer: document.referrer,
      ...additionalData,
    });
  }

  public trackWorkoutStart(workoutType: string, duration: number, difficulty: string) {
    this.trackEvent('workout_start', {
      workoutType,
      plannedDuration: duration,
      difficulty,
      timestamp: new Date().toISOString(),
    });
  }

  public trackWorkoutComplete(workoutType: string, actualDuration: number, completed: boolean) {
    this.trackEvent('workout_complete', {
      workoutType,
      actualDuration,
      completed,
      completionRate: completed ? 100 : Math.round((actualDuration / (actualDuration + 10)) * 100),
      timestamp: new Date().toISOString(),
    });
  }

  public trackAIInteraction(interactionType: 'workout_generation' | 'chat' | 'feedback', provider?: string) {
    this.trackEvent('ai_interaction', {
      interactionType,
      provider,
      timestamp: new Date().toISOString(),
    });
  }

  public trackFeatureUse(featureName: string, context: string, additionalData: Record<string, any> = {}) {
    this.trackEvent('feature_use', {
      featureName,
      context,
      ...additionalData,
    });
  }

  // Analytics methods

  public async getUserEngagementProfile(): Promise<UserEngagementProfile | null> {
    try {
      const sessions = JSON.parse(localStorage.getItem('engagement_sessions') || '[]');
      const events = JSON.parse(localStorage.getItem('engagement_events') || '[]');
      const userId = this.getCurrentUserId();

      if (userId === 'anonymous' || sessions.length === 0) return null;

      const userSessions = sessions.filter((s: SessionData) => s.userId === userId);
      const userEvents = events.filter((e: EngagementEvent) => e.userId === userId);

      const totalSessions = userSessions.length;
      const totalTimeSpent = userSessions.reduce((sum: number, s: SessionData) => sum + (s.duration || 0), 0);
      const averageSessionDuration = totalTimeSpent / totalSessions;

      const workoutsStarted = userEvents.filter(e => e.eventType === 'workout_start').length;
      const workoutsCompleted = userEvents.filter(e => e.eventType === 'workout_complete').length;
      const aiInteractions = userEvents.filter(e => e.eventType === 'ai_interaction').length;

      // Calculate engagement score (0-100)
      const engagementScore = this.calculateEngagementScore({
        totalSessions,
        averageSessionDuration,
        workoutCompletionRate: workoutsStarted > 0 ? workoutsCompleted / workoutsStarted : 0,
        aiInteractions,
        recentActivity: userSessions.filter(s =>
          new Date(s.startTime) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
        ).length,
      });

      // Determine risk level
      const riskLevel = this.calculateChurnRisk(engagementScore, userSessions);

      // Generate personalized recommendations
      const personalizedRecommendations = this.generateRecommendations({
        workoutCompletionRate: workoutsStarted > 0 ? workoutsCompleted / workoutsStarted : 0,
        averageSessionDuration,
        aiInteractions,
        recentActivity: userSessions.filter(s =>
          new Date(s.startTime) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
        ).length,
      });

      return {
        userId,
        totalSessions,
        totalTimeSpent,
        averageSessionDuration,
        workoutsStarted,
        workoutsCompleted,
        aiInteractions,
        favoriteFeatures: this.extractFavoriteFeatures(userEvents),
        lastActiveDate: userSessions[userSessions.length - 1]?.startTime || '',
        engagementScore,
        riskLevel,
        personalizedRecommendations,
      };
    } catch (error) {
      console.warn('Failed to generate user engagement profile:', error);
      return null;
    }
  }

  private calculateEngagementScore(metrics: {
    totalSessions: number;
    averageSessionDuration: number;
    workoutCompletionRate: number;
    aiInteractions: number;
    recentActivity: number;
  }): number {
    const weights = {
      sessions: 0.2,
      duration: 0.25,
      completion: 0.3,
      ai: 0.15,
      recent: 0.1,
    };

    const scores = {
      sessions: Math.min(100, (metrics.totalSessions / 20) * 100), // 20 sessions = 100%
      duration: Math.min(100, (metrics.averageSessionDuration / 30) * 100), // 30 min = 100%
      completion: metrics.workoutCompletionRate * 100,
      ai: Math.min(100, (metrics.aiInteractions / 50) * 100), // 50 interactions = 100%
      recent: Math.min(100, (metrics.recentActivity / 7) * 100), // 7 recent sessions = 100%
    };

    return Math.round(
      scores.sessions * weights.sessions +
      scores.duration * weights.duration +
      scores.completion * weights.completion +
      scores.ai * weights.ai +
      scores.recent * weights.recent
    );
  }

  private calculateChurnRisk(engagementScore: number, sessions: SessionData[]): 'low' | 'medium' | 'high' {
    const lastSession = sessions[sessions.length - 1];
    const daysSinceLastActive = lastSession
      ? Math.floor((Date.now() - new Date(lastSession.startTime).getTime()) / (1000 * 60 * 60 * 24))
      : 999;

    if (engagementScore >= 70 && daysSinceLastActive <= 3) return 'low';
    if (engagementScore >= 40 && daysSinceLastActive <= 7) return 'medium';
    return 'high';
  }

  private generateRecommendations(metrics: {
    workoutCompletionRate: number;
    averageSessionDuration: number;
    aiInteractions: number;
    recentActivity: number;
  }): string[] {
    const recommendations: string[] = [];

    if (metrics.workoutCompletionRate < 0.6) {
      recommendations.push('Try shorter 15-20 minute workouts to build consistency');
    }

    if (metrics.averageSessionDuration < 10) {
      recommendations.push('Explore the AI coach feature for personalized guidance');
    }

    if (metrics.aiInteractions < 5) {
      recommendations.push('Chat with your AI coach for workout tips and motivation');
    }

    if (metrics.recentActivity < 3) {
      recommendations.push('Set workout reminders to build a consistent routine');
    }

    if (recommendations.length === 0) {
      recommendations.push('Great job! Consider challenging yourself with new workout types');
    }

    return recommendations;
  }

  private extractFavoriteFeatures(events: EngagementEvent[]): string[] {
    const featureUsage: Record<string, number> = {};

    events
      .filter(e => e.eventType === 'feature_use')
      .forEach(e => {
        const feature = e.eventData.featureName || 'unknown';
        featureUsage[feature] = (featureUsage[feature] || 0) + 1;
      });

    return Object.entries(featureUsage)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 3)
      .map(([feature]) => feature);
  }

  public cleanup() {
    if (this.syncInterval) {
      clearInterval(this.syncInterval);
    }
    this.endSession();
  }
}

// Singleton instance
export const engagementTracker = new EngagementTrackingService();

export default engagementTracker;
