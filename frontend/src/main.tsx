import { EventType, PublicClientApplication } from '@azure/msal-browser'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import { msalConfig } from './config/authConfig'
import './index.css'

// Initialize MSAL instance once at startup
export const msalInstance = new PublicClientApplication(msalConfig);

// Handle the redirect promise BEFORE rendering the app
// This is critical for processing auth responses from Microsoft
msalInstance.initialize().then(() => {
  // Handle redirect response
  msalInstance.handleRedirectPromise()
    .then((response) => {
      if (response) {
        console.log('[MSAL] Redirect response received:', response.account?.username);
        // Set the active account
        msalInstance.setActiveAccount(response.account);
      } else {
        // Check if there's already an active account
        const accounts = msalInstance.getAllAccounts();
        if (accounts.length > 0) {
          msalInstance.setActiveAccount(accounts[0]);
        }
      }
    })
    .catch((error) => {
      console.error('[MSAL] Error handling redirect:', error);
    });

  // Listen for login events
  msalInstance.addEventCallback((event) => {
    if (event.eventType === EventType.LOGIN_SUCCESS && event.payload) {
      const payload = event.payload as { account: { username: string } };
      console.log('[MSAL] Login success:', payload.account?.username);
      msalInstance.setActiveAccount(payload.account as import('@azure/msal-browser').AccountInfo);
    }
  });

  // Render the app after MSAL is initialized
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );
});
