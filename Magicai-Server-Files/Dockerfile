FROM php:8.2-fpm

# Argumentos para configuração
ARG user=laravel
ARG uid=1000

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm

# Limpar cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar extensões PHP
RUN docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip

# Obter e instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Criar usuário do sistema
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Configurar diretório de trabalho
WORKDIR /var/www

# Copiar arquivos de configuração personalizados
COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Copiar arquivos do projeto
COPY . /var/www
COPY .env.example /var/www/.env

# Ajustar permissões
RUN chown -R $user:$user /var/www
RUN chmod -R 755 /var/www/storage /var/www/bootstrap/cache

# Criar diretório para logs do PHP-FPM
RUN mkdir -p /var/log/php-fpm
RUN chown -R $user:$user /var/log/php-fpm
RUN chmod -R 755 /var/log/php-fpm


# Instalar dependências do Composer
#RUN composer install --no-interaction --no-scripts --prefer-dist
#RUN php artisan config:clear
#RUN php artisan route:clear
#RUN php artisan view:clear

# Mudar para o usuário Laravel
USER $user

# Expor a porta do PHP-FPM
EXPOSE 9000

# Iniciar PHP-FPM
CMD ["php-fpm"]