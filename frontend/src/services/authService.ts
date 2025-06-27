import axios from 'axios'
import type {
    AuthResponse,
    OAuthAuthorizationResponse,
    OAuthProvidersResponse,
    TokenRefreshResponse,
    User
} from '../types/auth'

const API_BASE_URL = 'http://localhost:8000'

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle token refresh on 401 responses
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      const refreshToken = localStorage.getItem('refreshToken')
      if (refreshToken) {
        try {
          const response = await axios.post<TokenRefreshResponse>(`${API_BASE_URL}/auth/refresh`, {
            refresh_token: refreshToken,
          })

          const { access_token } = response.data
          localStorage.setItem('accessToken', access_token)

          // Retry the original request
          error.config.headers.Authorization = `Bearer ${access_token}`
          return api.request(error.config)
        } catch {
          // Refresh failed, redirect to login
          localStorage.removeItem('accessToken')
          localStorage.removeItem('refreshToken')
          window.location.href = '/login'
        }
      } else {
        // No refresh token, redirect to login
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

export const authService = {
  async login(email: string, password: string): Promise<AuthResponse> {
    const response = await api.post<AuthResponse>('/auth/login', {
      email,
      password,
    })
    return response.data
  },

  async register(email: string, username: string, password: string): Promise<AuthResponse> {
    const response = await api.post<AuthResponse>('/auth/register', {
      email,
      username,
      password,
    })
    return response.data
  },

  async getCurrentUser(): Promise<User> {
    const response = await api.get<User>('/auth/me')
    return response.data
  },

  async refreshToken(refreshToken: string): Promise<TokenRefreshResponse> {
    const response = await api.post<TokenRefreshResponse>('/auth/refresh', {
      refresh_token: refreshToken,
    })
    return response.data
  },

  async logout(): Promise<void> {
    await api.post('/auth/logout')
  },

  // OAuth2 Methods
  async getOAuthProviders(): Promise<OAuthProvidersResponse> {
    const response = await api.get<OAuthProvidersResponse>('/auth/oauth/providers')
    return response.data
  },

  async getOAuthAuthorizationUrl(provider: string): Promise<OAuthAuthorizationResponse> {
    const response = await api.get<OAuthAuthorizationResponse>(`/auth/oauth/${provider}`)
    return response.data
  },

  async handleOAuthCallback(provider: string, code: string, state: string): Promise<AuthResponse> {
    const response = await api.post<AuthResponse>(`/auth/oauth/${provider}/token`, {
      code,
      state,
    })
    return response.data
  },

  initiateOAuthLogin(provider: string): void {
    // Store current URL for redirect after OAuth
    localStorage.setItem('oauth_redirect_url', window.location.pathname)

    // Get authorization URL and redirect
    this.getOAuthAuthorizationUrl(provider)
      .then(({ authorization_url }) => {
        window.location.href = authorization_url
      })
      .catch((error) => {
        console.error(`OAuth login failed for ${provider}:`, error)
        throw new Error(`Failed to initiate ${provider} login`)
      })
  },

  // Token storage and management
  storeTokens(authResponse: AuthResponse): void {
    localStorage.setItem('accessToken', authResponse.access_token)
    localStorage.setItem('refreshToken', authResponse.refresh_token)
    localStorage.setItem('user', JSON.stringify(authResponse.user))
  },

  clearTokens(): void {
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    localStorage.removeItem('user')
    localStorage.removeItem('oauth_redirect_url')
  },

  getStoredUser(): User | null {
    const userJson = localStorage.getItem('user')
    return userJson ? JSON.parse(userJson) : null
  },

  isAuthenticated(): boolean {
    return !!localStorage.getItem('accessToken')
  },
}
