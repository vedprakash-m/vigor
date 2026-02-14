/**
 * Admin API Service
 *
 * Provides API calls for admin dashboard functionality.
 * Per Tech Spec §2.4 and Tasks.md §4.8
 *
 * All endpoints require admin authorization (checked on backend).
 */

import axios from 'axios';
import {
    DecisionOutcome,
    DecisionType,
    type GhostMode,
    type PhenomeStoreStatus,
    type TrustPhase,
    type WatchStatus,
} from '../config/adminConfig';

// API base URL
const API_BASE_URL = import.meta.env.VITE_API_URL || '';

// Create axios instance for admin API
const adminClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Token management
let accessToken: string | null = null;

export function setAdminAccessToken(token: string | null) {
  accessToken = token;
}

// Add auth interceptor
adminClient.interceptors.request.use((config) => {
  if (accessToken) {
    config.headers.Authorization = `Bearer ${accessToken}`;
  }
  return config;
});

// Handle 401 responses — mirror api.ts behaviour so expired tokens
// trigger the same re-auth flow regardless of which client sent the request.
adminClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (axios.isAxiosError(error) && error.response?.status === 401) {
      window.dispatchEvent(new CustomEvent('auth:expired'));
    }
    return Promise.reject(error);
  }
);

// ============================================================================
// Types
// ============================================================================

/**
 * Ghost system health status
 */
export interface GhostHealth {
  mode: GhostMode;
  lastUpdated: string;
  components: ComponentHealth[];
  phenomeStores: PhenomeStoreHealth[];
  metrics: GhostMetrics;
  // Top-level convenience fields used by health monitoring views
  modelHealth: 'healthy' | 'degraded' | 'unhealthy';
  avgLatencyMs: number;
  successRate: number;
  decisionsToday: number;
  mutationsToday: number;
  safetyBreakersTriggered: number;
}

export interface ComponentHealth {
  name: string;
  status: 'healthy' | 'degraded' | 'unhealthy';
  latency: number;
  errorRate: number;
  details: string;
}

export interface PhenomeStoreHealth {
  store: 'RawSignal' | 'DerivedState' | 'BehavioralMemory';
  status: PhenomeStoreStatus;
  size: string;
  syncRate: number;
  avgStaleness: string;
}

export interface GhostMetrics {
  decisionsToday: number;
  mutationsToday: number;
  acceptRate: number;
  safetyBreakersTriggered: number;
}

/**
 * Trust distribution across users
 */
export interface TrustDistribution {
  phases: TrustPhaseCount[];
  avgTimeToPhase2: number; // days
  avgTimeToPhase5: number; // days
}

export interface TrustPhaseCount {
  phase: TrustPhase;
  count: number;
  percentage: number;
}

/**
 * Decision Receipt for audit
 */
export interface DecisionReceipt {
  id: string;
  timestamp: string;
  userId: string;
  userEmail: string;
  trustPhase: TrustPhase;
  type: DecisionType;
  /** Alias for `type` used by audit views */
  decisionType: DecisionType;
  outcome: DecisionOutcome;
  confidence: number;
  trustImpact: {
    ifAccepted: number;
    ifRejected: number;
  };
  inputs: Record<string, string | number>;
  decision: string;
  /** Count of alternatives considered (derived from details) */
  alternativesConsidered: number;
  /** Detailed alternative options */
  alternativesDetails: Array<{
    option: string;
    rejected: string;
  }>;
  /** JSON-serialised context snapshot for audit trail */
  contextSnapshot: string;
}

/**
 * Safety Breaker event
 */
export interface SafetyBreakerEvent {
  id: string;
  timestamp: string;
  userId: string;
  userEmail: string;
  trigger: string;
  /** Breaker category label used by UI views */
  breakerType: string;
  previousPhase: TrustPhase;
  newPhase: TrustPhase;
  reason: string;
  /** Whether the breaker was automatically resolved */
  autoResolved: boolean;
}

/**
 * Admin user with Ghost-specific fields
 */
export interface AdminUser {
  id: string;
  email: string;
  name: string;
  tier: 'free' | 'premium' | 'enterprise';
  status: 'active' | 'inactive' | 'suspended';
  trustPhase: TrustPhase;
  trustScore: number;
  watchStatus: WatchStatus;
  phenomeFreshness: {
    status: PhenomeStoreStatus;
    lastSync: string;
  };
  lastGhostDecision: {
    timestamp: string;
    type: DecisionType;
  } | null;
  createdAt: string;
  lastLogin: string;
  workoutCount: number;
}

/**
 * AI Pipeline stats
 */
export interface AIPipelineStats {
  activeModel: string;
  modelProvider: string;
  ragLatency: number;
  generationLatency: number;
  contractValidatorLatency: number;
  workoutsGenerated24h: number;
  contractViolations24h: number;
  violationBreakdown: Record<string, number>;
  // Fields used by the LLM Configuration view
  modelStatus: 'healthy' | 'degraded' | 'unhealthy';
  avgLatencyMs: number;
  successRate: number;
  totalRequests24h: number;
  contractValidations: number;
  schemaRejections: number;
}

/**
 * Ghost operations analytics
 */
export interface GhostAnalytics {
  period: string;
  // Summary stats
  totalDecisions: number;
  totalMutations: number;
  acceptRate: number;
  modifyRate: number;
  rejectRate: number;
  safetyBreakers: number;
  // Performance
  avgLatencyMs: number;
  successRate: number;
  phenomeQueriesPerDecision: number;
  avgConfidence: number;
  // Weekly breakdown
  weeklyStats: Array<{
    day: string;
    decisions: number;
    mutations: number;
    acceptRate: number;
  }>;
  // Distribution
  trustDistribution: Array<{
    phase: string;
    count: number;
  }>;
  // Legacy fields
  dailyDecisions: Array<{
    date: string;
    count: number;
  }>;
  dailyMutations: Array<{
    date: string;
    created: number;
    transformed: number;
    removed: number;
  }>;
  decisionsByType: Record<DecisionType, number>;
  outcomesByType: Record<DecisionOutcome, number>;
  trustPhaseTransitions: Array<{
    from: TrustPhase;
    to: TrustPhase;
    count: number;
  }>;
}

// ============================================================================
// API Functions
// ============================================================================

/**
 * Admin API client
 */
export const AdminAPI = {
  /**
   * Get Ghost system health
   */
  async getGhostHealth(): Promise<GhostHealth> {
    try {
      const response = await adminClient.get('/api/admin/ghost/health');
      return response.data;
    } catch (error) {
      console.error('Failed to fetch Ghost health:', error);
      if (import.meta.env.DEV) return getMockGhostHealth();
      throw error;
    }
  },

  /**
   * Get trust distribution across all users
   */
  async getTrustDistribution(): Promise<TrustDistribution> {
    try {
      const response = await adminClient.get('/api/admin/ghost/trust-distribution');
      return response.data;
    } catch (error) {
      console.error('Failed to fetch trust distribution:', error);
      if (import.meta.env.DEV) return getMockTrustDistribution();
      throw error;
    }
  },

  /**
   * Get decision receipts for audit
   */
  async getDecisionReceipts(params?: {
    days?: number;
    userId?: string;
    type?: DecisionType;
    outcome?: DecisionOutcome;
  }): Promise<DecisionReceipt[]> {
    try {
      const searchParams = new URLSearchParams();
      if (params?.days) searchParams.append('days', String(params.days));
      if (params?.userId) searchParams.append('user_id', params.userId);
      if (params?.type) searchParams.append('type', params.type);
      if (params?.outcome) searchParams.append('outcome', params.outcome);

      const response = await adminClient.get(`/api/admin/ghost/decision-receipts?${searchParams}`);
      return response.data.receipts;
    } catch (error) {
      console.error('Failed to fetch decision receipts:', error);
      if (import.meta.env.DEV) return getMockDecisionReceipts();
      throw error;
    }
  },

  /**
   * Get safety breaker events
   */
  async getSafetyBreakerEvents(daysBack = 30): Promise<SafetyBreakerEvent[]> {
    try {
      const response = await adminClient.get(`/api/admin/ghost/safety-breakers?days=${daysBack}`);
      return response.data.events;
    } catch (error) {
      console.error('Failed to fetch safety breaker events:', error);
      if (import.meta.env.DEV) return getMockSafetyBreakerEvents();
      throw error;
    }
  },

  /**
   * Get users with Ghost-specific data
   */
  async getUsers(params?: {
    tier?: string;
    status?: string;
    trustPhase?: TrustPhase;
    search?: string;
  }): Promise<AdminUser[]> {
    try {
      const searchParams = new URLSearchParams();
      if (params?.tier) searchParams.append('tier', params.tier);
      if (params?.status) searchParams.append('status', params.status);
      if (params?.trustPhase) searchParams.append('trust_phase', params.trustPhase);
      if (params?.search) searchParams.append('search', params.search);

      const response = await adminClient.get(`/api/admin/ghost/users?${searchParams}`);
      return response.data.users;
    } catch (error) {
      console.error('Failed to fetch users:', error);
      if (import.meta.env.DEV) return getMockAdminUsers();
      throw error;
    }
  },

  /**
   * Get AI pipeline statistics
   */
  async getAIPipelineStats(): Promise<AIPipelineStats> {
    try {
      const response = await adminClient.get('/api/admin/ai/cost-metrics');
      return response.data;
    } catch (error) {
      console.error('Failed to fetch AI pipeline stats:', error);
      if (import.meta.env.DEV) return getMockAIPipelineStats();
      throw error;
    }
  },

  /**
   * Get Ghost operations analytics
   */
  async getGhostAnalytics(days = 7): Promise<GhostAnalytics> {
    try {
      const period = days <= 1 ? '24h' : days <= 7 ? '7d' : '30d';
      const response = await adminClient.get(`/api/admin/ghost/analytics?period=${period}`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch Ghost analytics:', error);
      if (import.meta.env.DEV) return getMockGhostAnalytics();
      throw error;
    }
  },

  /**
   * Update AI pipeline configuration
   */
  async updateAIPipelineConfig(config: {
    maxExercisesPerWorkout?: number;
    maxWorkoutDuration?: number;
    requestTimeout?: number;
  }): Promise<void> {
    await adminClient.put('/api/admin/ai-pipeline-config', config);
  },
};

// ============================================================================
// Mock Data (used when backend endpoints don't exist yet)
// ============================================================================

function getMockGhostHealth(): GhostHealth {
  return {
    mode: 'NORMAL',
    lastUpdated: new Date().toISOString(),
    modelHealth: 'healthy',
    avgLatencyMs: 180,
    successRate: 99.2,
    decisionsToday: 2847,
    mutationsToday: 1234,
    safetyBreakersTriggered: 3,
    components: [
      { name: 'RAG Retrieval', status: 'healthy', latency: 45, errorRate: 0.1, details: 'Exercise DB' },
      { name: 'gpt-5-mini', status: 'healthy', latency: 180, errorRate: 0.3, details: 'Structured outputs' },
      { name: 'Workout Contracts', status: 'healthy', latency: 12, errorRate: 0.0, details: 'Validator' },
      { name: 'Cosmos DB', status: 'healthy', latency: 23, errorRate: 0.0, details: 'Connected' },
      { name: 'APNs (Silent Push)', status: 'healthy', latency: 89, errorRate: 1.2, details: 'Morning orchestration' },
      { name: 'CloudKit Sync', status: 'healthy', latency: 156, errorRate: 0.8, details: 'Phenome sync' },
    ],
    phenomeStores: [
      { store: 'RawSignal', status: 'HEALTHY', size: '2.3GB', syncRate: 99.2, avgStaleness: '<2h' },
      { store: 'DerivedState', status: 'HEALTHY', size: '890MB', syncRate: 98.7, avgStaleness: '<4h' },
      { store: 'BehavioralMemory', status: 'HEALTHY', size: '1.1GB', syncRate: 99.4, avgStaleness: '<1h' },
    ],
    metrics: {
      decisionsToday: 2847,
      mutationsToday: 1234,
      acceptRate: 89.2,
      safetyBreakersTriggered: 3,
    },
  };
}

function getMockTrustDistribution(): TrustDistribution {
  return {
    phases: [
      { phase: 'Observer', count: 561, percentage: 45 },
      { phase: 'Scheduler', count: 387, percentage: 31 },
      { phase: 'Auto-Scheduler', count: 225, percentage: 18 },
      { phase: 'Transformer', count: 62, percentage: 5 },
      { phase: 'Full Ghost', count: 12, percentage: 1 },
    ],
    avgTimeToPhase2: 8.3,
    avgTimeToPhase5: 67,
  };
}

function getMockDecisionReceipts(): DecisionReceipt[] {
  return [
    {
      id: 'DR-2026-01-28-001',
      timestamp: new Date(Date.now() - 1000 * 60 * 30).toISOString(),
      userId: 'user-001',
      userEmail: 'john.doe@example.com',
      trustPhase: 'Scheduler',
      type: 'TRANSFORM',
      decisionType: 'TRANSFORM',
      outcome: 'ACCEPTED',
      confidence: 89,
      trustImpact: { ifAccepted: 2, ifRejected: -5 },
      inputs: {
        'Sleep last night': '5h 12m',
        'HRV': '32ms (-40% from baseline)',
        'Calendar gap': '6:00-7:30 PM',
        'Days since workout': 3,
        'Scheduled block': 'Heavy Lifts',
      },
      decision: 'Transform block from "Heavy Lifts" → "Recovery Walk"',
      alternativesConsidered: 3,
      alternativesDetails: [
        { option: 'Keep Heavy Lifts', rejected: 'Injury risk 78%' },
        { option: 'Cancel block', rejected: '3-day gap too long' },
        { option: 'Light mobility', rejected: 'User prefers walks' },
      ],
      contextSnapshot: '{"sleep":"5h 12m","hrv":"32ms","gap":"6:00-7:30 PM","block":"Heavy Lifts"}',
    },
    {
      id: 'DR-2026-01-28-002',
      timestamp: new Date(Date.now() - 1000 * 60 * 60).toISOString(),
      userId: 'user-002',
      userEmail: 'jane.smith@example.com',
      trustPhase: 'Observer',
      type: 'SCHEDULE',
      decisionType: 'SCHEDULE',
      outcome: 'REJECTED',
      confidence: 72,
      trustImpact: { ifAccepted: 3, ifRejected: -2 },
      inputs: {
        'Calendar gap': '5:00-6:00 PM',
        'Days since workout': 2,
        'Recovery score': '78%',
      },
      decision: 'Schedule Upper Body block at 5:00 PM',
      alternativesConsidered: 0,
      alternativesDetails: [],
      contextSnapshot: '{"gap":"5:00-6:00 PM","days_since":2,"recovery":"78%"}',
    },
  ];
}

function getMockSafetyBreakerEvents(): SafetyBreakerEvent[] {
  return [
    {
      id: 'SB-001',
      timestamp: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
      userId: 'user-042',
      userEmail: 'stress@example.com',
      trigger: '3 consecutive block deletions',
      breakerType: 'TRUST_REGRESSION',
      previousPhase: 'Auto-Scheduler',
      newPhase: 'Observer',
      reason: 'User rejected 3 Ghost-scheduled blocks in a row',
      autoResolved: false,
    },
  ];
}

function getMockAdminUsers(): AdminUser[] {
  return [
    {
      id: 'user-001',
      email: 'john.doe@example.com',
      name: 'John Doe',
      tier: 'premium',
      status: 'active',
      trustPhase: 'Auto-Scheduler',
      trustScore: 74,
      watchStatus: 'CONNECTED',
      phenomeFreshness: { status: 'HEALTHY', lastSync: new Date().toISOString() },
      lastGhostDecision: { timestamp: new Date().toISOString(), type: 'TRANSFORM' },
      createdAt: '2024-01-15',
      lastLogin: '2026-01-28',
      workoutCount: 45,
    },
    {
      id: 'user-002',
      email: 'jane.smith@example.com',
      name: 'Jane Smith',
      tier: 'free',
      status: 'active',
      trustPhase: 'Observer',
      trustScore: 23,
      watchStatus: 'DISCONNECTED',
      phenomeFreshness: { status: 'STALE', lastSync: new Date(Date.now() - 1000 * 60 * 60 * 96).toISOString() },
      lastGhostDecision: null,
      createdAt: '2024-02-20',
      lastLogin: '2026-01-25',
      workoutCount: 12,
    },
    {
      id: 'user-003',
      email: 'bob.wilson@example.com',
      name: 'Bob Wilson',
      tier: 'enterprise',
      status: 'active',
      trustPhase: 'Full Ghost',
      trustScore: 94,
      watchStatus: 'CONNECTED',
      phenomeFreshness: { status: 'HEALTHY', lastSync: new Date().toISOString() },
      lastGhostDecision: { timestamp: new Date().toISOString(), type: 'SCHEDULE' },
      createdAt: '2024-01-05',
      lastLogin: '2026-01-28',
      workoutCount: 89,
    },
  ];
}

function getMockAIPipelineStats(): AIPipelineStats {
  return {
    activeModel: 'gpt-5-mini',
    modelProvider: 'Azure OpenAI (vigor-openai)',
    ragLatency: 45,
    generationLatency: 180,
    contractValidatorLatency: 12,
    workoutsGenerated24h: 1245,
    contractViolations24h: 12,
    violationBreakdown: {
      duration_exceeded: 7,
      unsafe_exercise: 5,
      missing_warmup: 0,
    },
    modelStatus: 'healthy',
    avgLatencyMs: 180,
    successRate: 99.2,
    totalRequests24h: 1245,
    contractValidations: 1233,
    schemaRejections: 4,
  };
}

function getMockGhostAnalytics(): GhostAnalytics {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return {
    period: '7d',
    // Summary stats
    totalDecisions: 2847,
    totalMutations: 892,
    acceptRate: 78,
    modifyRate: 15,
    rejectRate: 7,
    safetyBreakers: 3,
    // Performance
    avgLatencyMs: 245,
    successRate: 99.2,
    phenomeQueriesPerDecision: 12,
    avgConfidence: 84,
    // Weekly breakdown
    weeklyStats: days.map((day) => ({
      day,
      decisions: Math.floor(Math.random() * 100) + 50,
      mutations: Math.floor(Math.random() * 40) + 15,
      acceptRate: Math.floor(Math.random() * 20) + 70,
    })),
    // Trust distribution
    trustDistribution: [
      { phase: 'Observer', count: 156 },
      { phase: 'Scheduler', count: 89 },
      { phase: 'Auto-Scheduler', count: 45 },
      { phase: 'Transformer', count: 23 },
      { phase: 'Full Ghost', count: 12 },
    ],
    // Legacy fields
    dailyDecisions: Array.from({ length: 7 }, (_, i) => ({
      date: new Date(Date.now() - (6 - i) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      count: Math.floor(Math.random() * 500) + 300,
    })),
    dailyMutations: Array.from({ length: 7 }, (_, i) => ({
      date: new Date(Date.now() - (6 - i) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      created: Math.floor(Math.random() * 200) + 100,
      transformed: Math.floor(Math.random() * 50) + 20,
      removed: Math.floor(Math.random() * 30) + 10,
    })),
    decisionsByType: {
      SCHEDULE: 1245,
      TRANSFORM: 456,
      REMOVE: 234,
      RESCHEDULE: 189,
      SKIP_PREDICT: 567,
      SAFETY_BREAKER: 12,
      WORKOUT_MUTATION: 89,
      SCHEDULE_CHANGE: 45,
      REST_DAY: 23,
      INTENSITY_ADJUSTMENT: 34,
    },
    outcomesByType: {
      ACCEPTED: 2103,
      REJECTED: 287,
      MODIFIED: 56,
      OVERRIDDEN: 156,
      PENDING: 45,
    },
    trustPhaseTransitions: [
      { from: 'Observer', to: 'Scheduler', count: 45 },
      { from: 'Scheduler', to: 'Auto-Scheduler', count: 23 },
      { from: 'Auto-Scheduler', to: 'Transformer', count: 8 },
      { from: 'Transformer', to: 'Full Ghost', count: 2 },
      { from: 'Auto-Scheduler', to: 'Observer', count: 5 }, // Downgrade
    ],
  };
}

export default AdminAPI;
