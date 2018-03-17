FROM php:apache

# add mcript and gd extension for php
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libcurl4-gnutls-dev \
        libmcrypt-dev \
        locales \
        libssl-dev \
    && docker-php-ext-install -j$(nproc) mbstring tokenizer curl pcntl mysqli pdo pdo_mysql xml zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

RUN pecl install mongodb \
    && docker-php-ext-enable mongodb


ADD 000-default.conf /etc/apache2/sites-available/

RUN /usr/sbin/a2enmod rewrite
