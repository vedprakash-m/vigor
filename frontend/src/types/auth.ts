/**
 * User Interface - Standard Auth Types
 * For Microsoft Entra ID authentication
 */

/**
 * Primary User interface for authenticated users
 */
export interface User {
  id: string;           // Entra ID subject claim (primary user identifier)
  email: string;        // User's email address
  name: string;         // Full display name
  username: string;     // Username derived from email for backward compatibility
  givenName: string;    // First name
  familyName: string;   // Last name
  tier?: 'free' | 'premium' | 'enterprise';    // Subscription tier
  permissions: string[]; // App-specific permissions from JWT claims
  createdAt?: string;   // Account creation timestamp
  profile: {
    profileId: string;                           // Profile ID
    subscriptionTier: 'free' | 'premium' | 'enterprise';
    appsEnrolled: string[];                      // List of enrolled apps
    preferences: Record<string, string | number | boolean>; // User preferences
  };
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
