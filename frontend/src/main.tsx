import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import { initializeMsal } from './config/msalInstance'
import './index.css'

// Initialize MSAL before rendering the app
// This ensures auth redirects are handled properly
initializeMsal().then(() => {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );
});
