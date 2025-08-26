#!/bin/sh
set -e

# Ensure LF line endings and executable are handled by Dockerfile.

if [ ! -d "/var/www/vendor" ] || [ -z "$(ls -A /var/www/vendor 2>/dev/null)" ]; then
    composer install --no-interaction --no-scripts --prefer-dist
    php artisan config:clear || true
    php artisan route:clear || true
    php artisan view:clear || true
fi

php artisan migrate --force || true

# Run php-fpm in foreground
exec php-fpm -F
