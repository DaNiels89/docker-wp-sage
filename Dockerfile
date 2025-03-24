# ---------------------------------------
# Stage 1: Frontend Build (Node.js 22 LTS)
# ---------------------------------------
FROM node:22-alpine as frontend

WORKDIR /app

# Copy package files first for caching
COPY package.json package-lock.json ./
RUN npm install

# Copy rest of frontend files and build assets
COPY . .
RUN npm run build

# ---------------------------------------
# Stage 2: PHP-FPM (WordPress with PHP 8.4)
# ---------------------------------------
FROM wordpress:php8.4-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    zip unzip \
    jpegoptim optipng pngquant gifsicle \
    git \
    curl \
    vim \
    locales \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Configure & Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql zip exif pcntl bcmath opcache

# PHP custom configuration (optimized ini file)
COPY ./php/php.ini /usr/local/etc/php/conf.d/local.ini

# Install Composer (latest stable)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js 22.x (LTS) via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# Install WP-CLI (latest stable)
RUN curl -sSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o wp \
    && chmod +x wp \
    && mv wp /usr/local/bin/wp

# Create dedicated user/group for security
RUN groupadd -g 1000 www \
    && useradd -u 1000 -ms /bin/bash -g www www

# Set correct permissions
RUN chown -R www:www /var/www/html

# Switch to non-root user for security
USER www

# Set working directory
WORKDIR /var/www/html

# Expose required ports (PHP-FPM and Vite Dev Server)
EXPOSE 9000 5173

# Start PHP-FPM service
CMD ["php-fpm"]
    