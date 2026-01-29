/**
 * MSAL Instance - Singleton for the entire application
 * Separated to avoid circular imports between main.tsx and App.tsx
 */

import type { AccountInfo } from '@azure/msal-browser';
import { EventType, PublicClientApplication } from '@azure/msal-browser';
import { msalConfig } from './authConfig';

// Initialize MSAL instance once at startup
export const msalInstance = new PublicClientApplication(msalConfig);

// Track initialization state
let isInitialized = false;

/**
 * Initialize MSAL and handle any pending redirect responses
 * Must be called before rendering the app
 */
export async function initializeMsal(): Promise<void> {
  if (isInitialized) {
    return;
  }

  await msalInstance.initialize();

  // Handle redirect response (critical for processing auth after Microsoft redirect)
  try {
    const response = await msalInstance.handleRedirectPromise();
    if (response) {
      console.log('[MSAL] Redirect response received:', response.account?.username);
      msalInstance.setActiveAccount(response.account);
    } else {
      // Check if there's already an active account
      const accounts = msalInstance.getAllAccounts();
      if (accounts.length > 0) {
        msalInstance.setActiveAccount(accounts[0]);
      }
    }
  } catch (error) {
    console.error('[MSAL] Error handling redirect:', error);
  }

  // Listen for login events
  msalInstance.addEventCallback((event) => {
    if (event.eventType === EventType.LOGIN_SUCCESS && event.payload) {
      const payload = event.payload as { account: AccountInfo };
      console.log('[MSAL] Login success:', payload.account?.username);
      msalInstance.setActiveAccount(payload.account);
    }
  });

  isInitialized = true;
}
