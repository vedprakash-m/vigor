import axios from 'axios'
import type { VedUser } from '../types/auth'

interface UserProfile {
  id: string
  fitness_level?: string
  goals?: string[]
  equipment?: string
  injuries?: string[]
  preferences?: Record<string, unknown>
  subscription_tier: string
  monthly_budget: number
  current_month_usage: number
  created_at?: string
  updated_at?: string
}

// Use environment variable for API URL, with fallback to localhost for development
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'

/**
 * MSAL-compatible API service for Microsoft Entra ID authentication
 * Replaces legacy authService with standardized VedUser interface
 */
class VedApiService {
  private api = axios.create({
    baseURL: API_BASE_URL,
    headers: {
      'Content-Type': 'application/json',
    },
  })

  /**
   * Set the access token for API requests
   * Call this with the MSAL token from VedAuthContext
   */
  setAccessToken(token: string | null) {
    if (token) {
      this.api.defaults.headers.common['Authorization'] = `Bearer ${token}`
    } else {
      delete this.api.defaults.headers.common['Authorization']
    }
  }

  /**
   * Get current user profile from Microsoft Entra ID validation
   */
  async getCurrentUser(): Promise<VedUser> {
    try {
      const response = await this.api.get('/api/v1/entra-auth/me')
      return response.data.user
    } catch (error) {
      console.error('Failed to get current user:', error)
      throw new Error('Failed to fetch user profile')
    }
  }

  /**
   * Get detailed user profile with fitness data
   */
  async getUserProfile(): Promise<{ user: VedUser; profile: UserProfile }> {
    try {
      const response = await this.api.get('/api/v1/entra-auth/profile')
      return response.data
    } catch (error) {
      console.error('Failed to get user profile:', error)
      throw new Error('Failed to fetch user profile')
    }
  }

  /**
   * Validate the current token
   */
  async validateToken(): Promise<{ valid: boolean; user: VedUser }> {
    try {
      const response = await this.api.post('/api/v1/entra-auth/validate-token')
      return response.data
    } catch (error) {
      console.error('Token validation failed:', error)
      throw new Error('Token validation failed')
    }
  }

  /**
   * Check authentication service health
   */
  async healthCheck(): Promise<{ status: string; service: string }> {
    try {
      const response = await this.api.get('/api/v1/entra-auth/health')
      return response.data
    } catch (error) {
      console.error('Health check failed:', error)
      throw new Error('Health check failed')
    }
  }

  /**
   * Generic API request method with automatic token handling
   */
  async request<T>(method: 'GET' | 'POST' | 'PUT' | 'DELETE', url: string, data?: unknown): Promise<T> {
    try {
      const response = await this.api.request({
        method,
        url,
        data,
      })
      return response.data
    } catch (error) {
      console.error(`API request failed (${method} ${url}):`, error)
      throw error
    }
  }

  // Convenience methods for common HTTP verbs
  async get<T>(url: string): Promise<T> {
    return this.request<T>('GET', url)
  }

  async post<T>(url: string, data?: unknown): Promise<T> {
    return this.request<T>('POST', url, data)
  }

  async put<T>(url: string, data?: unknown): Promise<T> {
    return this.request<T>('PUT', url, data)
  }

  async delete<T>(url: string): Promise<T> {
    return this.request<T>('DELETE', url)
  }
}

// Export singleton instance
export const vedApiService = new VedApiService()

// Export class for testing
export { VedApiService }
