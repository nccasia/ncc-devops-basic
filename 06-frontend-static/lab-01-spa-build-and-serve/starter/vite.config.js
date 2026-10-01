import { defineConfig } from 'vite'

// Dev server proxies /api to the backend to avoid CORS during development.
// Production does NOT use this — Nginx handles the proxying.
export default defineConfig({
  define: {
    // Build time, shown on /about so you know which build is running
    __BUILD_TIME__: JSON.stringify(new Date().toISOString()),
  },
  server: {
    proxy: {
      '/api': {
        target: process.env.API_TARGET || 'http://127.0.0.1:5000',
        changeOrigin: true,
      },
    },
  },
})
