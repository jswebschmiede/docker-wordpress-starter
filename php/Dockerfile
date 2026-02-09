ARG PHP_VERSION=${PHP_VERSION:-8.3}
FROM php:${PHP_VERSION}

# Installation der benötigten PHP-Erweiterungen für WordPress
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    && docker-php-ext-install \
    mysqli \
    pdo_mysql \
    zip

# Optimiere PHP für WordPress
COPY php.ini /usr/local/etc/php/conf.d/wordpress.ini

# Setze Berechtigungen
RUN chown -R www-data:www-data /var/www/html 