#!/bin/bash
set -e

if [ ! -d "/var/www/vendor" ] || [ -z "$(ls -A /var/www/vendor)" ]; then
    composer install --no-interaction --no-scripts --prefer-dist

    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
fi

php artisan migrate

exec php-fpm
