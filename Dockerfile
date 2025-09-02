FROM php:8.2-fpm-alpine AS base

ARG user
ARG uid

RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm \
    oniguruma-dev \
    libxml2-dev \
    linux-headers

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip
RUN addgroup -g $uid -S $user && \
    adduser -u $uid -S $user -G $user -h /home/$user && \
    addgroup $user www-data && \
    addgroup $user root
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

WORKDIR /var/www

COPY .docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY .docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY .docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY . /var/www

# Normalize script line endings, ensure executable, and validate shebang/exec at build time
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh && \
    head -n1 /usr/local/bin/entrypoint.sh | grep -q "^#!\/bin\/sh" && \
    test -x /usr/local/bin/entrypoint.sh && \
    chown -R $user:$user /var/www && \
    chmod -R 755 /var/www/storage /var/www/bootstrap/cache && \
    mkdir -p /var/log/php-fpm && \
    chown -R $user:$user /var/log/php-fpm && \
    chmod -R 755 /var/log/php-fpm


FROM base AS development
RUN apk add --no-cache bash nano $PHPIZE_DEPS && \
    pecl install xdebug && \
    docker-php-ext-enable xdebug

COPY .docker/php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

USER root
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Production image: no xdebug, optimized dependencies and assets
FROM base AS production
ENV APP_ENV=production \
    APP_DEBUG=false

# Install PHP dependencies without dev and optimize autoloader
RUN composer install --no-interaction --no-dev --prefer-dist --optimize-autoloader

# Build frontend assets (if present)
RUN if [ -f package.json ]; then npm ci || npm install; npm run build; fi

# Cache Laravel config/routes/views if artisan exists
RUN if [ -f artisan ]; then php artisan config:cache || true; php artisan route:cache || true; php artisan view:cache || true; fi

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]