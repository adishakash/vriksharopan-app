import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3001,
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes('node_modules')) {
            return undefined;
          }

          if (id.includes('recharts')) {
            return 'charts';
          }

          if (
            id.includes('react-router-dom') ||
            id.includes('react-dom') ||
            id.includes(`${'/'}react${'/'}`) ||
            id.includes(`${'\\'}react${'\\'}`)
          ) {
            return 'vendor';
          }

          return undefined;
        },
      },
    },
  },
});
