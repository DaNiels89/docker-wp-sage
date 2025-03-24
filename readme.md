docker exec up -d --build

---

ADJUST vite.config.js for Sage 11 to work with Docker:

import { defineConfig, loadEnv } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import laravel from 'laravel-vite-plugin';
import { wordpressPlugin, wordpressThemeJson } from '@roots/vite-plugin';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  return {
    base: '/wp-content/themes/sage/public/build/',
    plugins: [
      tailwindcss(),
      laravel({
        input: [
          'resources/css/app.css',
          'resources/js/app.js',
          'resources/css/editor.css',
          'resources/js/editor.js',
        ],
        refresh: true,
      }),
      wordpressPlugin(),
      wordpressThemeJson({
        disableTailwindColors: false,
        disableTailwindFonts: false,
        disableTailwindFontSizes: false,
      }),
    ],
    resolve: {
      alias: {
        '@scripts': '/resources/js',
        '@styles': '/resources/css',
        '@fonts': '/resources/fonts',
        '@images': '/resources/images',
      },
    },
    server: {
      host: '0.0.0.0',      // Allow connections externally in Docker
      port: 5173,           // Ensure fixed port
      strictPort: true,
      hmr: {
        host: 'localhost',  // CRITICAL FIX: Docker-friendly host
        protocol: 'ws',     // Use websocket explicitly
        clientPort: 5173,   // Explicitly tell browser which port to use
      },
    },
  };
});
