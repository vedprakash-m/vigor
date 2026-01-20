/**
 * Vigor API Service
 * Unified API client for all backend calls
 */

import axios, { AxiosError, AxiosInstance, InternalAxiosRequestConfig } from 'axios';

// API base URL from environment or default to Azure Functions
const API_BASE_URL = import.meta.env.VITE_API_URL || '';

/**
 * Vigor API Client
 * Handles all communication with the Azure Functions backend
 */
class VigorAPI {
  private client: AxiosInstance;
  private accessToken: string | null = null;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add auth token to all requests
    this.client.interceptors.request.use((config: InternalAxiosRequestConfig) => {
      if (this.accessToken) {
        config.headers.Authorization = `Bearer ${this.accessToken}`;
      }
      return config;
    });

    // Handle errors globally
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        if (error.response?.status === 401) {
          // Token expired - trigger re-auth event
          window.dispatchEvent(new CustomEvent('auth:expired'));
        }
        return Promise.reject(error);
      }
    );
  }

  /**
   * Set the access token for API authentication
   */
  setAccessToken(token: string | null) {
    this.accessToken = token;
  }

  /**
   * Get the current access token
   */
  getAccessToken(): string | null {
    return this.accessToken;
  }

  // ==========================================================================
  // AUTH ENDPOINTS
  // ==========================================================================

  auth = {
    /**
     * Get current user profile from token
     */
    me: () => this.client.get<User>('/api/auth/me'),
  };

  // ==========================================================================
  // USER ENDPOINTS
  // ==========================================================================

  users = {
    /**
     * Get user profile
     */
    getProfile: () => this.client.get<UserProfile>('/api/users/profile'),

    /**
     * Update user profile
     */
    updateProfile: (data: UserProfileUpdate) =>
      this.client.put<UserProfile>('/api/users/profile', data),
  };

  // ==========================================================================
  // WORKOUT ENDPOINTS
  // ==========================================================================

  workouts = {
    /**
     * Generate AI-powered workout
     */
    generate: (params: GenerateWorkoutParams) =>
      this.client.post<Workout>('/api/workouts/generate', params),

    /**
     * List user's workouts
     */
    list: (limit = 20) =>
      this.client.get<Workout[]>(`/api/workouts?limit=${limit}`),

    /**
     * Get a specific workout
     */
    get: (id: string) =>
      this.client.get<Workout>(`/api/workouts/${id}`),

    /**
     * Log completed workout
     */
    log: (data: WorkoutLogData) =>
      this.client.post<WorkoutLog>('/api/workouts/log', data),

    /**
     * Get workout history/logs
     */
    history: (limit = 20) =>
      this.client.get<WorkoutLog[]>(`/api/workouts/history?limit=${limit}`),
  };

  // ==========================================================================
  // COACH ENDPOINTS
  // ==========================================================================

  coach = {
    /**
     * Send message to AI coach
     */
    chat: (message: string) =>
      this.client.post<CoachChatResponse>('/api/coach/chat', { message }),

    /**
     * Get conversation history
     */
    history: (limit = 50) =>
      this.client.get<ChatMessage[]>(`/api/coach/history?limit=${limit}`),

    /**
     * Clear conversation history
     */
    clearHistory: () =>
      this.client.delete('/api/coach/history'),
  };

  // ==========================================================================
  // HEALTH ENDPOINTS
  // ==========================================================================

  health = {
    /**
     * Check API health status
     */
    check: () => this.client.get<HealthStatus>('/api/health'),
  };
}

// =============================================================================
// TYPE DEFINITIONS
// =============================================================================

export interface User {
  id: string;
  email: string;
  displayName?: string;
  profile?: UserProfileData;
  tier: 'free' | 'premium';
  stats?: UserStats;
  createdAt: string;
  updatedAt: string;
}

export interface UserProfile extends User {
  profile: UserProfileData;
}

export interface UserProfileData {
  fitnessLevel: 'beginner' | 'intermediate' | 'advanced';
  goals: string[];
  equipment: string[];
  preferredDuration: number;
}

export interface UserProfileUpdate {
  profile?: Partial<UserProfileData>;
  displayName?: string;
}

export interface UserStats {
  totalWorkouts: number;
  currentStreak: number;
  longestStreak: number;
}

export interface GenerateWorkoutParams {
  durationMinutes?: number;
  equipment?: string[];
  focusAreas?: string[];
  difficulty?: 'easy' | 'moderate' | 'hard';
}

export interface Workout {
  id: string;
  userId?: string;
  name: string;
  description: string;
  exercises: Exercise[];
  durationMinutes: number;
  difficulty: string;
  equipment: string[];
  warmup?: string;
  cooldown?: string;
  tips?: string[];
  aiGenerated: boolean;
  createdAt: string;
}

export interface Exercise {
  name: string;
  sets: number;
  reps: string;
  rest: string;
  notes?: string;
}

export interface WorkoutLogData {
  workoutId: string;
  actualDuration: number;
  rating?: number;
  notes?: string;
  exercisesCompleted?: ExerciseCompletion[];
}

export interface ExerciseCompletion {
  name: string;
  setsCompleted: number;
  repsAchieved: number[];
}

export interface WorkoutLog {
  id: string;
  userId: string;
  workoutId: string;
  completedAt: string;
  actualDuration: number;
  rating?: number;
  notes?: string;
  exercisesCompleted?: ExerciseCompletion[];
}

export interface CoachChatResponse {
  response: string;
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
}

export interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  version: string;
  timestamp: string;
}

// =============================================================================
// SINGLETON INSTANCE
// =============================================================================

export const api = new VigorAPI();

export default api;
