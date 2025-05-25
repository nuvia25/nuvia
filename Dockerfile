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

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY . /var/www

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chown -R $user:$user /var/www && \
    chmod -R 755 /var/www/storage /var/www/bootstrap/cache && \
    mkdir -p /var/log/php-fpm && \
    chown -R $user:$user /var/log/php-fpm && \
    chmod -R 755 /var/log/php-fpm


FROM base AS development
RUN apk add --no-cache bash nano $PHPIZE_DEPS && \
    pecl install xdebug && \
    docker-php-ext-enable xdebug

COPY docker/php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

USER root
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]