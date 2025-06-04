export interface User {
  id: string
  email: string
  username: string
  name: string // Added name property
  is_active: boolean
  created_at: string
  updated_at: string
  fitness_level?: string; // Added fitness_level property
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
}

export interface TokenRefreshRequest {
  refresh_token: string
}

export interface TokenRefreshResponse {
  access_token: string
  token_type: string
}