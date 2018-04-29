FROM php:fpm

WORKDIR /code

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
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install opcache

RUN pecl install mongodb \
    && docker-php-ext-enable mongodb

# COPY php.ini /usr/local/etc/php/
COPY conf.d/*.ini /usr/local/etc/php/conf.d/

COPY imagescripts/dockerwait.sh /usr/local/bin/dockerwait
RUN chmod u+x /usr/local/bin/dockerwait

COPY start.sh /usr/local/bin/start
RUN chmod u+x /usr/local/bin/start

CMD ["/usr/local/bin/start"]