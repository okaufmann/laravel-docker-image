FROM php:8-fpm

# inspired by https://github.com/nextcloud/docker/blob/f1ca6dbfab022e44b8aed9909939a4c43726d2f2/21.0/apache/Dockerfile
# add mcript and gd extension for php
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        libwebp-dev \
        libcurl4-gnutls-dev \
        libmcrypt-dev \
        locales \
        libssl-dev \
        netcat \
        nginx \
        supervisor \
        git-core \
        libmagickwand-dev \
    && docker-php-ext-install -j "$(nproc)" tokenizer curl pcntl bcmath exif zip pdo_mysql \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install opcache \
    # mongodb imagick
    && pecl install redis \
    # mongodb imagick
    && docker-php-ext-enable redis \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# config php
COPY php/conf.d/*.ini /usr/local/etc/php/conf.d/

# config logging
# forward request and error logs to docker log collector
RUN touch /var/log/nginx/access.log && \
    touch /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# config nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/site.conf /etc/nginx/conf.d/default.conf

# config supervisor
COPY supervisord/ /etc/supervisor/

# add scripts
COPY start.sh /usr/local/bin/start

# fix permissions
RUN chmod u+x /usr/local/bin/start

# setup workdir and permissions
WORKDIR /code

# ensure code has correct owner
RUN chown -R www-data:www-data /code

EXPOSE 8000

CMD ["/usr/local/bin/start"]