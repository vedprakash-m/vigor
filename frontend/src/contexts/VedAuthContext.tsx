/**
 * Microsoft Entra ID Authentication Context
 * Replaces custom AuthContext with MSAL integration
 * Compliant with Apps_Auth_Requirement.md
 */

import type { AccountInfo } from '@azure/msal-common';
import {
    useAccount,
    useIsAuthenticated,
    useMsal
} from '@azure/msal-react';
import React, { createContext, useEffect, useState } from 'react';
import { loginRequest, logoutRequest, silentRequest } from '../config/authConfig';
import api from '../services/api';
import type { VedUser } from '../types/auth';

interface VedAuthContextType {
  user: VedUser | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: () => Promise<void>;
  logout: () => Promise<void>;
  getAccessToken: () => Promise<string | null>;
  error: string | null;
}

export const VedAuthContext = createContext<VedAuthContextType | undefined>(undefined);

interface VedAuthProviderProps {
  children: React.ReactNode;
}

/**
 * Extract VedUser from Microsoft Entra ID token claims
 * Implements standardized user extraction as per Apps_Auth_Requirement.md
 */
function extractVedUser(account: AccountInfo, idTokenClaims?: Record<string, unknown>): VedUser {
  const claims = idTokenClaims || {};

  return {
    id: account.homeAccountId || account.localAccountId, // Entra ID subject claim
    email: account.username || claims.email as string || '',
    name: account.name || claims.name as string || '',
    username: account.username?.split('@')[0] || claims.preferred_username as string || account.name || '',
    givenName: claims.given_name as string || '',
    familyName: claims.family_name as string || '',
    tier: (claims.ved_subscription_tier as 'free' | 'premium' | 'enterprise') || 'free',
    permissions: (claims.roles as string[]) || [],
    vedProfile: {
      profileId: claims.ved_profile_id as string || account.homeAccountId || account.localAccountId,
      subscriptionTier: (claims.ved_subscription_tier as 'free' | 'premium' | 'enterprise') || 'free',
      appsEnrolled: (claims.ved_apps_enrolled as string[]) || ['vigor'],
      preferences: (() => {
        try {
          return typeof claims.ved_preferences === 'string'
            ? JSON.parse(claims.ved_preferences)
            : (claims.ved_preferences as Record<string, string | number | boolean>) || {};
        } catch {
          return {};
        }
      })()
    }
  };
}

export const VedAuthProvider: React.FC<VedAuthProviderProps> = ({ children }) => {
  const { instance, accounts } = useMsal();
  const isAuthenticated = useIsAuthenticated();
  const account = useAccount(accounts[0] || {});

  const [user, setUser] = useState<VedUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Initialize user from MSAL account
  useEffect(() => {
    const initializeUser = async () => {
      setIsLoading(true);
      setError(null);

      try {
        if (isAuthenticated && account) {
          // Get ID token claims for VedUser extraction
          const silentRequestWithAccount = {
            ...silentRequest,
            account: account
          };

          const response = await instance.acquireTokenSilent(silentRequestWithAccount);

          // Set API token for authenticated requests
          api.setAccessToken(response.accessToken);

          const vedUser = extractVedUser(account, response.idTokenClaims as Record<string, unknown>);
          setUser(vedUser);
        } else {
          setUser(null);
          api.setAccessToken(null);
        }
      } catch (error) {
        console.error('Failed to initialize user:', error);
        setError('Failed to load user profile');
        setUser(null);
        api.setAccessToken(null);
      } finally {
        setIsLoading(false);
      }
    };

    initializeUser();
  }, [isAuthenticated, account, instance]);

  const login = async (): Promise<void> => {
    try {
      setError(null);
      await instance.loginRedirect(loginRequest);
    } catch (error) {
      console.error('Login failed:', error);
      setError('Login failed. Please try again.');
      throw error;
    }
  };

  const logout = async (): Promise<void> => {
    try {
      setError(null);
      const logoutRequestWithAccount = {
        ...logoutRequest,
        account: account || undefined
      };
      await instance.logoutRedirect(logoutRequestWithAccount);
      setUser(null);
    } catch (error) {
      console.error('Logout failed:', error);
      setError('Logout failed. Please try again.');
      throw error;
    }
  };

  const getAccessToken = async (): Promise<string | null> => {
    if (!isAuthenticated || !account) {
      return null;
    }

    try {
      const silentRequestWithAccount = {
        ...silentRequest,
        account: account
      };

      const response = await instance.acquireTokenSilent(silentRequestWithAccount);
      return response.accessToken;
    } catch (error) {
      console.error('Failed to acquire access token:', error);

      try {
        // Fallback to interactive token acquisition - redirect doesn't return a response
        await instance.acquireTokenRedirect({
          ...silentRequest,
          account: account
        });
        return null; // Redirect will reload the page
      } catch (redirectError) {
        console.error('Token acquisition failed completely:', redirectError);
        setError('Unable to acquire access token');
        return null;
      }
    }
  };

  const value: VedAuthContextType = {
    user,
    isLoading,
    isAuthenticated,
    login,
    logout,
    getAccessToken,
    error
  };

  return (
    <VedAuthContext.Provider value={value}>
      {children}
    </VedAuthContext.Provider>
  );
};
