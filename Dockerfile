FROM php:8-fpm

# add mcript and gd extension for php
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
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
    && rm -rf /var/lib/apt/lists/*

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
COPY supervisord/supervisord.conf /etc/supervisor/supervisord.conf

# add scripts
COPY dockerwait.sh /usr/local/bin/dockerwait
COPY start.sh /usr/local/bin/start

# fix permissions
RUN chmod u+x /usr/local/bin/start && \
    chmod u+x /usr/local/bin/dockerwait

# setup workdir and permissions
WORKDIR /code
RUN chown -R www-data:www-data /code

EXPOSE 8000


CMD ["/usr/local/bin/start"]