FROM php:8.3-apache

# 必要なパッケージをインストール
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libsqlite3-dev \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    && docker-php-ext-install \
    pdo_sqlite \
    mbstring \
    bcmath \
    intl \
    zip \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Node.js / npm
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && node --version \
    && npm --version \
    && rm -rf /var/lib/apt/lists/*

# ApacheのドキュメントルートをLaravelのpublicに変更
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

WORKDIR /var/www/html

# Laravel本体
COPY . .

# PHP依存ライブラリ
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# React / Vite
RUN npm install \
    && npm run build

# Laravelの環境設定
RUN cp .env.example .env \
    && php artisan key:generate \
    && touch database/database.sqlite \
    && php artisan migrate --force

# Laravelが書き込めるようにする
RUN chown -R www-data:www-data storage bootstrap/cache database

EXPOSE 80

CMD ["apache2-foreground"]