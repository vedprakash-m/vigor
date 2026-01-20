/**
 * Microsoft Entra ID Authentication Configuration
 * Uses default tenant (common) for multi-tenant support
 */

import type { Configuration, PopupRequest, RedirectRequest } from '@azure/msal-browser';

// Environment variables for Microsoft Entra ID
const clientId = import.meta.env.VITE_AZURE_CLIENT_ID || import.meta.env.VITE_AZURE_AD_CLIENT_ID || '';
const tenantId = 'common'; // Default tenant for multi-tenant auth
const authority = `https://login.microsoftonline.com/${tenantId}`;

/**
 * MSAL Configuration for Microsoft Entra ID
 */
export const msalConfig: Configuration = {
  auth: {
    clientId: clientId,
    authority: authority,
    redirectUri: import.meta.env.VITE_REDIRECT_URI || window.location.origin,
    postLogoutRedirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
  system: {
    loggerOptions: {
      loggerCallback: (_level, message, containsPii) => {
        if (!containsPii && import.meta.env.DEV) {
          console.log(`[MSAL] ${message}`);
        }
      },
      piiLoggingEnabled: false
    }
  }
};

/**
 * Login request configuration
 */
export const loginRequest: RedirectRequest = {
  scopes: ['openid', 'profile', 'email'],
};

/**
 * API request configuration for accessing protected endpoints
 */
export const apiRequest: PopupRequest = {
  scopes: ['openid', 'profile', 'email'],
  account: undefined
};

/**
 * Silent request configuration for token refresh
 */
export const silentRequest = {
  scopes: ['openid', 'profile', 'email'],
  account: undefined
};

/**
 * Logout request configuration
 */
export const logoutRequest = {
  account: undefined,
  mainWindowRedirectUri: window.location.origin
};
