/**
 * Microsoft Entra ID Authentication Configuration
 * Compliance with Apps_Auth_Requirement.md for Vedprakash Domain
 */

import type { Configuration, PopupRequest, RedirectRequest } from '@azure/msal-browser';

// Environment variables for Microsoft Entra ID
const clientId = import.meta.env.VITE_AZURE_AD_CLIENT_ID || 'vigor-app-client-id';
const tenantId = import.meta.env.VITE_AZURE_AD_TENANT_ID || 'vedid.onmicrosoft.com';
const authority = `https://login.microsoftonline.com/${tenantId}`;

/**
 * MSAL Configuration for Microsoft Entra ID
 * Configured for SSO across .vedprakash.net domain
 */
export const msalConfig: Configuration = {
  auth: {
    clientId: clientId,
    authority: authority,
    redirectUri: window.location.origin,
    postLogoutRedirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: 'sessionStorage', // Required for SSO
    storeAuthStateInCookie: true,    // Required for Safari/iOS
  },
  system: {
    loggerOptions: {
      loggerCallback: (level, message, containsPii) => {
        if (!containsPii) {
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
  prompt: 'select_account'
};

/**
 * API request configuration for accessing protected endpoints
 */
export const apiRequest: PopupRequest = {
  scopes: [`api://${clientId}/access_as_user`],
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
