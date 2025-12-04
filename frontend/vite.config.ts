import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv } from 'vite'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // Load env file based on `mode` in the current working directory.
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [react()],
    // Vite automatically loads .env files - no need to override
    // VITE_API_BASE_URL from .env.production will be available as import.meta.env.VITE_API_BASE_URL
  }
})
