import laravel from 'laravel-vite-plugin';
import { defineConfig } from 'vite';


// Fix: Error [ERR_REQUIRE_ESM]: require() of ES Module /var/www/node_modules/laravel-vite-plugin/dist/index.js from /var/www/vite.config.js not supported.
export default defineConfig({
    plugins: [
        laravel({
            input: [
                'resources/js/app.js',
            ],
            refresh: true,
        }),
    ],
});
