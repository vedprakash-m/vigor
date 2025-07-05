/**
 * VedUser Interface - Vedprakash Domain Standard
 * Compliant with Apps_Auth_Requirement.md
 */
export interface VedUser {
  id: string;           // Entra ID subject claim (primary user identifier)
  email: string;        // User's email address
  name: string;         // Full display name
  username: string;     // Username derived from email for backward compatibility
  givenName: string;    // First name
  familyName: string;   // Last name
  tier?: 'free' | 'premium' | 'enterprise';    // Backward compatibility
  permissions: string[]; // App-specific permissions from JWT claims
  vedProfile: {
    profileId: string;                           // Vedprakash domain profile ID
    subscriptionTier: 'free' | 'premium' | 'enterprise';
    appsEnrolled: string[];                      // List of enrolled apps
    preferences: Record<string, string | number | boolean>; // User preferences
  };
}

// Legacy User interface - to be deprecated
export interface User {
  id: string
  email: string
  username: string
  name: string
  is_active: boolean
  created_at: string
  updated_at: string
  fitness_level?: string
  oauth_provider?: string
  tier: string
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
  user: VedUser
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
