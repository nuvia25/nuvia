#!/bin/sh
set -e

log() { printf "%s\n" "$1"; }

log "💡 Entrypoint iniciado (APP_ENV=${APP_ENV:-production})"

# Ensure storage and cache directories
mkdir -p storage/framework/{cache,sessions,views,testing,cache/data} bootstrap/cache || true
chown -R ${APP_USER:-www-data}:${APP_USER:-www-data} storage bootstrap/cache || true
chmod -R ug+rwX storage bootstrap/cache || true

if [ -f composer.json ]; then
  log "📦 Instalando dependências PHP (se necessário)"
  composer install --no-interaction --prefer-dist --optimize-autoloader $( [ "$APP_ENV" = "production" ] && echo "--no-dev" ) || true
fi

if [ -f artisan ]; then
  php artisan storage:link || true
  php artisan migrate --force || true
  php artisan config:cache || true
  php artisan route:cache || true
  php artisan view:cache || true
fi

log "✅ Inicialização concluída. Iniciando PHP-FPM..."
exec php-fpm -F
