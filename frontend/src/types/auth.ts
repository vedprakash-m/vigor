export interface User {
  id: string
  email: string
  username: string
  name: string // Added name property
  is_active: boolean
  created_at: string
  updated_at: string
  fitness_level?: string; // Added fitness_level property
  oauth_provider?: string; // OAuth provider (microsoft, google, github)
  tier: string; // User tier (FREE, PREMIUM, ADMIN)
}

export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  email: string
  username: string
  password: string
}

export interface AuthResponse {
  user: User
  access_token: string
  refresh_token: string
  token_type: string
  expires_in?: number
}

export interface TokenRefreshRequest {
  refresh_token: string
}

export interface TokenRefreshResponse {
  access_token: string
  token_type: string
}

// OAuth2 types
export interface OAuthProvider {
  name: string
  displayName: string
  iconUrl?: string
}

export interface OAuthAuthorizationResponse {
  authorization_url: string
  state: string
}

export interface OAuthProvidersResponse {
  providers: string[]
  configuration: Record<string, string>
}

// Enhanced error types
export interface AuthError {
  message: string
  code?: string
  provider?: string
}
